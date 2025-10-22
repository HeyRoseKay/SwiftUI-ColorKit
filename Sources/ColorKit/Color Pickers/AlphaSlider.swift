//
//  AlphaSlider.swift
//  MyExamples
//
//  Created by Kieran Brown on 4/7/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI
import Sliders

@available(iOS 13.0, macOS 11.0, *)
public struct AlphaSliderStyle: LSliderStyle {
    public var color: ColorToken
    public var sliderHeight: CGFloat = 40
    let colorScheme: ColorScheme

    private var gradient: Gradient { Gradient(colors: [Color.white.opacity(0), Color.white]) }

    public func makeThumb(configuration: LSliderConfiguration) -> some View {
        ZStack {
            if #available(iOS 26.0, macOS 26.0, watchOS 26.0, *) {
                Circle()
                    .glassEffect(.regular, in: .circle)
            } else if #available(iOS 15.0, macOS 12.0, watchOS 10.0, *) {
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
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<max(Int(proxy.size.height / self.blockHeight), 2)) { (v: Int)  in
                        HStack(spacing: 0) {
                            ForEach(0..<max(Int((proxy.size.width + self.sliderHeight) / self.blockHeight), 2), id: \.self) { (h: Int) in
                                Rectangle()
                                    .fill( h % 2 == 0 ? v % 2 == 0 ? Color.black : Color.white : v % 2 == 0 ? Color.white : Color.black).frame(width: self.blockHeight, height: self.blockHeight).tag(h)
                            }
                        }
                    }
                }
                LinearGradient(gradient: self.gradient, startPoint: .leading, endPoint: .trailing)
            }
            .drawingGroup()
            .mask(Capsule().fill())
            .offset(x: -self.sliderHeight / 2)
            .overlay(
                Capsule()
                    .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 1)
                    .frame(width: proxy.size.width + self.sliderHeight)
                    .offset(x: -self.sliderHeight / 2)
                    .shadow(radius: 2)
            )
        }
    }
}

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
