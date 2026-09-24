//
//  AlphaSlider.swift
//  ColorKit
//
//  Original by Kieran Brown on 4/7/20.
//  Updates by Rose Kay in 2025.
//

import SwiftUI
import Sliders

// MARK: - Alpha L Slider Style
@available(iOS 13.0, macOS 11.0, *)
public struct AlphaSliderStyle: LSliderStyle {
    public var color: ColorToken
    public var sliderHeight: CGFloat = 40
    let colorScheme: ColorScheme

    private var gradient: Gradient { Gradient(colors: [Color(self.color.rgbColorSpace.space, white: 1, opacity: 0),
                                                       Color(self.color.rgbColorSpace.space, white: 1, opacity: 1)]) }

    public func makeThumb(configuration: LSliderConfiguration) -> some View {
        ZStack {
            if #available(iOS 26.0, macOS 26.0, *) {
                Circle()
                    .glassEffect(.regular, in: .circle)
            } else if #available(iOS 15.0, macOS 12.0, *) {
                Circle()
                    .fill(Material.ultraThin)
            } else {
                Circle()
                    .fill(colorScheme == .dark ? Color.black.opacity(0.01) : Color.white.opacity(0.01))
            }
            Circle()
                .fill(color.color)
        }
            .frame(width: sliderHeight, height: sliderHeight)
            .overlay(
                GeometryReader { proxy in
                    return Circle()
                        .stroke(colorScheme == .dark ? Color.prominentColorDark : Color.prominentColorLight, lineWidth: 2)
                        .shadow(radius: 2)
                }
            )
    }
    
    public var blockHeight: CGFloat = 10
    
    public func makeTrack(configuration: LSliderConfiguration) -> some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width + self.sliderHeight

            ZStack {
                Color.white
                AlphaGridShape(blockSize: self.blockHeight)
                    .fill(Color.black)
                LinearGradient(gradient: self.gradient, startPoint: .leading, endPoint: .trailing)
            }
            .frame(width: trackWidth, height: proxy.size.height)
            .mask(Capsule().fill())
            .offset(x: -self.sliderHeight / 2)
            .overlay(
                Capsule()
                    .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 1)
                    .frame(width: trackWidth)
                    .offset(x: -self.sliderHeight / 2)
                    .shadow(radius: 2)
            )
        }
    }
}

// MARK: - Alpha Grid Shape

/// The checkerboard drawn behind the alpha gradient to represent transparency.
///
/// Only the dark squares are described by the path, so the shape is meant to be filled with the  dark color and layered over the light one. Because a shape receives its rect in `path(in:)`,  the row and column counts stay out of SwiftUI's view identity, which a size dependent `ForEach` range cannot do safely.
@available(iOS 13.0, macOS 11.0, *)
public struct AlphaGridShape: Shape {
    public var blockSize: CGFloat

    public init(blockSize: CGFloat = 10) {
        self.blockSize = blockSize
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard blockSize > 0, !rect.isEmpty else { return path }

        let columns = Int((rect.width / blockSize).rounded(.up))
        let rows = Int((rect.height / blockSize).rounded(.up))

        for row in 0..<rows {
            for column in 0..<columns where (row + column).isMultiple(of: 2) {
                // Clip the trailing and bottom squares so the grid never draws past its rect.
                let block = CGRect(x: rect.minX + CGFloat(column) * blockSize,
                                   y: rect.minY + CGFloat(row) * blockSize,
                                   width: blockSize,
                                   height: blockSize)
                path.addRect(block.intersection(rect))
            }
        }

        return path
    }
}

// MARK: - Alpha Slider View
@available(iOS 13.0, macOS 11.0, *)
public struct AlphaSlider: View {
    @Binding public var color: ColorToken
    public var sliderHeight: CGFloat = 40

    @Environment(\.colorScheme) var colorScheme

    public init(_ color: Binding<ColorToken>) {
        self._color = color
    }
    
    public init(_ color: Binding<ColorToken>, sliderHeight: CGFloat) {
        self._color = color
        self.sliderHeight = sliderHeight
    }
    
    public var body: some View {
        LSlider(Binding(get: { self.color.alpha }, set: { self.color = self.color.update(alpha: $0) }))
            .linearSliderStyle(AlphaSliderStyle(color: color, sliderHeight: sliderHeight, colorScheme: colorScheme))
    }
}

// MARK: - Preview
struct AlphaSlider_Previews: PreviewProvider {

    static var previews: some View {
        ViewWithState()
            .previewDisplayName("Alpha Slider")
            .preferredColorScheme(.dark)
    }

    private struct ViewWithState : View {

        @State var color: ColorToken = .init(colorSpace: .sRGB, r: 1, g: 1, b: 1, a: 0.42)

        var body: some View {
            AlphaSlider($color)
                .frame(height: 40)
                .padding(.all, 40)
        }
    }
}
