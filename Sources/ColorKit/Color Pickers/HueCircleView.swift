//
//  HueCircleView.swift
//  ColorKit
//
//  Original by Kieran Brown on 4/8/20.
//  Updates by Rose Kay in 2025.
//

#if os(iOS)
import SwiftUI
import UIKit
import simd
import MetalKit

// MARK: - Shader Source
private let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct Vertex {
        float4 position [[position]];
        float4 color;
    };

    struct Uniforms {
        float4x4 modelMatrix;
    };

    vertex Vertex vertex_func(constant Vertex *vertices [[buffer(0)]],
                              constant Uniforms &uniforms [[buffer(1)]],
                              uint vid [[vertex_id]]) {
        float4x4 matrix = uniforms.modelMatrix;
        Vertex in = vertices[vid];
        Vertex out;
        out.position = matrix * float4(in.position);
        out.color = in.color;
        return out;
    }

    fragment float4 fragment_func(Vertex vert [[stage_in]]) {
        return vert.color;
    }
"""

// MARK: - Shared Metal Resources
@available(iOS 13.0, *)
class SharedMetalResources {
    static let shared = SharedMetalResources()
    
    let device: MTLDevice
    let library: MTLLibrary
    let renderPipelineState: MTLRenderPipelineState
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        
        do {
            self.library = try device.makeLibrary(source: shaderSource, options: nil)
            
            guard let vertexFunction = library.makeFunction(name: "vertex_func"),
                  let fragmentFunction = library.makeFunction(name: "fragment_func") else {
                fatalError("Failed to create shader functions")
            }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create Metal library or pipeline state: \(error)")
        }
    }
}

// MARK: - Metal View
@available(iOS 13.0, *)
public class MetalView: NSObject, MTKViewDelegate {
    var queue: MTLCommandQueue!
    var vertexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    var vertexData: [Vertex] = []
    
    private let sharedResources = SharedMetalResources.shared
    
    public var device: MTLDevice {
        return sharedResources.device
    }
    
    override public init() {
        super.init()
        
        createVertexPoints()
        createBuffers()
    }
    
    func rgb(h: Float, s: Float, v: Float) -> (r: Float, g: Float, b: Float) {
        if s == 0 { return (r: v, g: v, b: v) } // Achromatic grey
        
        let angle = Float(Int(h)%360)
        let sector = angle / 60 // Sector
        let i = floor(sector)
        let f = sector - i // Factorial part of h
        
        let p = v * (1 - s)
        let q = v * (1 - (s * f))
        let t = v * (1 - (s * (1 - f)))
        
        switch i {
        case 0:
            return (r: v, g: t, b: p)
        case 1:
            return (r: q, g: v, b: p)
        case 2:
            return (r: p, g: v, b: t)
        case 3:
            return (r: p, g: q, b: v)
        case 4:
            return (r: t, g: p, b: v)
        default:
            return (r: v, g: p, b: q)
        }
    }
    
    fileprivate func createVertexPoints() {
        func rads(forDegree d: Float) -> Float32 {
            return (Float.pi * d) / 180
        }
        
        var vertices: [Vertex] = []
        let origin: vector_float4 = vector_float4([0, 0, 0, 1])
        
        for i in 0..<720 {
            let position: vector_float4 = vector_float4([
                cos(rads(forDegree: Float(i))) * 2,
                sin(rads(forDegree: Float(i))) * 2,
                0,
                1
            ])
            let color = rgb(h: 720 - Float(i), s: 1, v: 1)
            
            vertices.append(Vertex(pos: position, col: vector_float4([color.r, color.g, color.b, 1])))
            
            if (i + 1) % 2 == 0 {
                let col = rgb(h: 720 - Float(i), s: 0, v: 1)
                let c: vector_float4 = vector_float4([col.r, col.g, col.b, 1])
                vertices.append(Vertex(pos: origin, col: c))
            }
        }
        
        self.vertexData = vertices
    }
    
    func createBuffers() {
        queue = device.makeCommandQueue()
        
        vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: MemoryLayout<Vertex>.size * vertexData.count,
            options: []
        )
        
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<Float>.size * 16,
            options: []
        )
        
        let bufferPointer = uniformBuffer.contents()
        memcpy(bufferPointer, Matrix().scalingMatrix(Matrix(), 0.5).m, MemoryLayout<Float>.size * 16)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        guard let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = queue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
            return
        }
        
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        commandEncoder.setRenderPipelineState(sharedResources.renderPipelineState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexData.count, instanceCount: 1)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Vertex
@available(iOS 13.0, *)
struct Vertex {
    var position: vector_float4
    var color: vector_float4
    
    init(pos: vector_float4, col: vector_float4) {
        position = pos
        color = col
    }
}

// MARK: - Matrix
@available(iOS 13.0, *)
struct Matrix {
    var m: [Float]
    
    init() {
        m = [1, 0, 0, 0,
             0, 1, 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1]
    }
    
    func scalingMatrix(_ matrix: Matrix, _ scale: Float) -> Matrix {
        var matrix = matrix
        matrix.m[0] = scale
        matrix.m[5] = scale
        matrix.m[10] = scale
        matrix.m[15] = 1.0
        return matrix
    }
}

// MARK: - Hue Circle Metal View
@available(iOS 13.0, *)
struct HueCircleMetalView: UIViewRepresentable {
    typealias UIViewType = MTKView

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.delegate.device
        view.delegate = context.coordinator.delegate
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.framebufferOnly = false
        view.backgroundColor = .clear
        view.layer.isOpaque = false
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.async {
            uiView.draw()
        }
    }

    class Coordinator {
        let delegate: MetalView

        init() {
            self.delegate = MetalView()
        }
    }
}

// MARK: - Hue Circle View
@available(iOS 13.0, *)
struct HueCircleView: View {
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                HueCircleMetalView()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .mask(Circle())
            }
        }
    }
}

// MARK: - Preview
struct HueCircleView_Previews: PreviewProvider {
    static var previews: some View {
        HueCircleView()
            .frame(width: 300, height: 300)
            .rotationEffect(Angle(degrees: -90))
            .preferredColorScheme(.dark)
    }
}
#endif
