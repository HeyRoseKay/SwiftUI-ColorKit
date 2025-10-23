//
//  GrayScaleSlider.swift
//  MyExamples
//
//  Created by Kieran Brown on 4/8/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI
import Shapes
import Sliders

// MARK: - Gray Scale L Slider Style
@available(iOS 13.0, macOS 11.0, *)
public struct GrayScaleSliderStyle: LSliderStyle {
    public let color: ColorToken
    public let sliderHeight: CGFloat
    let colorScheme: ColorScheme
    
    private var gradient: Gradient { Gradient(colors: [Color(white: 0), Color(white: 1)]) }
    
    public func makeThumb(configuration: LSliderConfiguration) -> some View {
        let strokeColor = Color(white: color.white < 0.75 ? 1 : 1-color.white)
        return ZStack {
            Pentagon()
                .fill(Color(white: color.white))
            if #available(iOS 15.0, macOS 12.0, watchOS 10.0, *) {
                Pentagon()
                    .stroke(colorScheme == .dark ? Color.prominentColorDark : Color.prominentColorLight, style: .init(lineWidth: 2, lineJoin: .round))
            } else {
                Pentagon()
                    .stroke(strokeColor, style: .init(lineWidth: 2, lineJoin: .round))
            }
        }
        .frame(width: sliderHeight/2, height: 0.66*sliderHeight)
        .offset(x: 0, y: 0.16*sliderHeight-1.5)
    }
    
    public func makeTrack(configuration: LSliderConfiguration) -> some View {
        let fill = LinearGradient(gradient: self.gradient, startPoint: .leading, endPoint: .trailing)
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(fill)
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.500, green: 0.500, blue: 0.500, opacity: 0.800), lineWidth: 1)
        }
    }
}

// MARK: - GrayScale Slider View
@available(iOS 13.0, macOS 11.0, *)
public struct GrayScaleSlider: View {
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
    
    // MARK: - View Body
    public var body: some View {
        VStack {
            // MARK: - Percentage Display
            Text("\(Int(round(self.color.white * 100)))%")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.vertical, 4)

            LSlider(Binding(get: { self.color.white}, set: { self.color = self.color.update(white: $0) }))
                .linearSliderStyle(GrayScaleSliderStyle(color: color, sliderHeight: sliderHeight, colorScheme: colorScheme))
        }
    }
}

// MARK: - Preview
struct GrayScaleSlider_Previews: PreviewProvider {

    static var previews: some View {
        ViewWithState()
            .previewDisplayName("Gray Scale Slider")
            .preferredColorScheme(.dark)
    }

    private struct ViewWithState : View {

        @State var color: ColorToken = .init(white: 0.42)

        var body: some View {
            GrayScaleSlider($color)
                .frame(height: 68)
                .padding(.all, 40)
        }
    }
}
