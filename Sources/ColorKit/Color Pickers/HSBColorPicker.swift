//
//  HSBColorPicker.swift
//  MyExamples
//
//  Created by Kieran Brown on 4/7/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI
import Shapes
import Sliders

@available(iOS 13.0, macOS 11.0, *)
public struct HueSliderStyle: LSliderStyle {
    public var sliderHeight: CGFloat
    let colorScheme: ColorScheme

    private let hueColors = stride(from: 0, to: 1, by: 0.03).map {
        Color(hue: $0, saturation: 1, brightness: 1)
    }
    
    public func makeThumb(configuration: LSliderConfiguration) -> some View {
        Circle()
            .fill(Color(hue: configuration.pctFill, saturation: 1, brightness: 1))
            .frame(width: sliderHeight, height: sliderHeight)
            .overlay(GeometryReader { proxy in
                Circle()
                    .stroke(colorScheme == .dark ? Color.prominentColorDark : Color.prominentColorLight, lineWidth: 2)
                    .shadow(radius: 2)
            })
    }
    
    public func makeTrack(configuration: LSliderConfiguration) -> some View {
        let style: StrokeStyle = .init(lineWidth: sliderHeight, lineCap: .round)
        let gradient = LinearGradient(gradient: Gradient(colors: hueColors), startPoint: .leading, endPoint: .trailing)
        return AdaptiveLine(angle: configuration.angle)
            .stroke(gradient, style: style)
            .overlay(GeometryReader { proxy in
                Capsule()
                    .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 1)
                    .frame(width: proxy.size.width + self.sliderHeight)
                    .offset(x: -self.sliderHeight / 2)
                    .rotationEffect(configuration.angle)
                    .shadow(radius: 4)
            })
    }
}

@available(iOS 13.0, macOS 11.0, *)
public struct SaturationBrightnessStyle: TrackPadStyle {
    public var hue: Double

    @Environment(\.colorScheme) var colorScheme

    private var saturationColors: [Color] {
        return stride(from: 0, to: 1, by: 0.01).map {
            Color(hue: hue, saturation: $0, brightness: 1)
        }
    }
    
    public func makeThumb(configuration: TrackPadConfiguration) -> some View {
        Circle()
            .fill(Color(hue: self.hue, saturation: Double(configuration.pctX), brightness: Double(1 - configuration.pctY)))
            .frame(width: 36, height: 36)
            .overlay(GeometryReader { proxy in
                Circle()
                    .stroke(colorScheme == .dark ? Color.prominentColorDark : Color.prominentColorLight, lineWidth: 2)
                    .shadow(radius: 2)
            })
    }

    // FIXME: Come back and draw the 2D gradient with metal when I make a better pipeline
    public func makeTrack(configuration: TrackPadConfiguration) -> some View {
        let brightnessGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 1, green: 1, blue: 1), Color(red: 0, green: 0, blue: 0)]), startPoint: .top, endPoint: .bottom)
        let saturationGradient = LinearGradient(gradient: Gradient(colors: saturationColors), startPoint: .leading, endPoint: .trailing)
        if #available(iOS 15.0, macOS 12.0, watchOS 10.0, *) {
            return ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(brightnessGradient)

                RoundedRectangle(cornerRadius: 10)
                    .fill(saturationGradient)
                    .drawingGroup(opaque: false, colorMode: .extendedLinear)
                    .blendMode(.plusDarker)
            }.overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Material.thin, lineWidth: 2)
            )
        } else {
            return ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(brightnessGradient)

                RoundedRectangle(cornerRadius: 10)
                    .fill(saturationGradient)
                    .drawingGroup(opaque: false, colorMode: .extendedLinear)
                    .blendMode(.plusDarker)
            }.overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 1)
            )
        }
    }
}

@available(iOS 13.0, macOS 11.0, *)
public struct HSBColorPicker: View {
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
        VStack(spacing: 20) {
            TrackPad(value: Binding(get: {CGPoint(x: self.color.saturation, y: 1 - self.color.brightness)},
                                    set: { (new) in
                                        self.color = self.color.update(saturation: Double(new.x))
                                        self.color = self.color.update(brightness: Double(1 - new.y))
            }), rangeX: 0.0...1, rangeY: 0.0...1)
                .trackPadStyle(SaturationBrightnessStyle(hue: self.color.hue))
            
            LSlider(Binding(get: {self.color.hue}, set: {self.color = self.color.update(hue: $0)}))
                .linearSliderStyle(HueSliderStyle(sliderHeight: sliderHeight, colorScheme: colorScheme))
                .frame(height: sliderHeight)
//                .padding(.horizontal, sliderHeight/2)
        }
    }
}

struct HSBColorPicker_Previews: PreviewProvider {

    static var previews: some View {
        ViewWithState()
            .previewDisplayName("Alpha Slider")
            .preferredColorScheme(.dark)
    }

    private struct ViewWithState : View {

        @State var color: ColorToken = .init(hue: 0.42, saturation: 0.42, brightness: 0.42)

        var body: some View {
            HSBColorPicker($color)
                .frame(height: 360)
                .padding(.all, 40)
        }
    }
}
