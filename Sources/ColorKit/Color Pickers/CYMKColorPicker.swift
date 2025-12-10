//
//  CYMKColorPicker.swift
//  ColorKit
//
//  Original by Kieran Brown on 4/7/20.
//  Updates by Rose Kay in 2025.
// 

import SwiftUI
import Shapes
import Sliders

// MARK: - CMYK L Slider Style
@available(iOS 13.0, macOS 11.0, *)
public struct CMYKSliderStyle: LSliderStyle {
    public enum ColorType: String, CaseIterable {
        case cyan
        case magenta
        case yellow
        case black
    }
    public var sliderHeight: CGFloat
    public var type: ColorType
    public var color: ColorToken
    let colorScheme: ColorScheme

    // Creates two colors based upon what the color would look like if the value of the slider was dragged all the way left or all the way right
    private var colors: [Color] {
        switch type {
            
        case .cyan:
            return [Color(PlatformColor(cmyk: (0,CGFloat(color.magenta), CGFloat(color.yellow), CGFloat(color.keyBlack) ))), Color(PlatformColor(cmyk: (1,CGFloat(color.magenta), CGFloat(color.yellow), CGFloat(color.keyBlack) )))]
        case .magenta:
            return [Color(PlatformColor(cmyk: (CGFloat(color.cyan),0, CGFloat(color.yellow), CGFloat(color.keyBlack) ))), Color(PlatformColor(cmyk: (CGFloat(color.cyan),1, CGFloat(color.yellow), CGFloat(color.keyBlack) )))]
        case .yellow:
            return [Color(PlatformColor(cmyk: (CGFloat(color.cyan),CGFloat(color.magenta), 0, CGFloat(color.keyBlack) ))), Color(PlatformColor(cmyk: (CGFloat(color.cyan),CGFloat(color.magenta), 1, CGFloat(color.keyBlack) )))]
        case .black:
            return [Color(PlatformColor(cmyk: (CGFloat(color.cyan),CGFloat(color.magenta), CGFloat(color.yellow), 0))), Color(PlatformColor(cmyk: (CGFloat(color.cyan),CGFloat(color.magenta), CGFloat(color.yellow), 1)))]
            
        }
    }

    public func makeThumb(configuration: LSliderConfiguration) -> some View {
        let currentColor: Color =  {
            switch type {
            case .cyan:
                return Color(PlatformColor(cmyk: (CGFloat(configuration.pctFill), 0 , 0, 0)))
            case .magenta:
                return Color(PlatformColor(cmyk: (0,CGFloat(configuration.pctFill), 0, 0)))
            case .yellow:
                return Color(PlatformColor(cmyk: (0, 0, CGFloat(configuration.pctFill), 0)))
            case .black:
                return Color(PlatformColor(cmyk: (0, 0, 0, CGFloat(configuration.pctFill))))
            }
        }()
        
        return Circle()
            .fill(currentColor)
            .frame(width: self.sliderHeight, height: self.sliderHeight)
            .overlay(GeometryReader { proxy in
                Circle()
                    .stroke(colorScheme == .dark ? Color.prominentColorDark : Color.prominentColorLight, lineWidth: 2)
                    .shadow(radius: 2)
            })
    }
    
    public func makeTrack(configuration: LSliderConfiguration) -> some View {
        let style: StrokeStyle = .init(lineWidth: sliderHeight, lineCap: .round)
        return AdaptiveLine(angle: configuration.angle)
            .stroke(LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing), style: style)
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

// MARK: - CMYK Color Picker View
@available(iOS 13.0, macOS 11.0, *)
public struct CMYKColorPicker: View {
    @Binding public var color: ColorToken
    public var sliderHeights: CGFloat = 40

    @Environment(\.colorScheme) var colorScheme

    public init(_ color: Binding<ColorToken>) {
        self._color = color
    }
    
    public init(_ color: Binding<ColorToken>, sliderHeights: CGFloat) {
        self._color = color
        self.sliderHeights = sliderHeights
    }
    
    private func makeSlider( _ color: CMYKSliderStyle.ColorType) -> some View {
        let value: Binding<Double> =  {
            switch color {
            case .cyan:
                return Binding(get: {self.color.cyan},
                               set: {self.color = self.color.update(cyan: $0)})
            case .magenta:
                return Binding(get: {self.color.magenta},
                               set: {self.color = self.color.update(magenta: $0)})
            case .yellow:
                return Binding(get: {self.color.yellow},
                               set: {self.color = self.color.update(yellow: $0)})
            case .black:
                return Binding(get: {self.color.keyBlack},
                               set: {self.color = self.color.update(keyBlack: $0)})
            }
        }()
        let style = CMYKSliderStyle(sliderHeight: sliderHeights, type: color, color: self.color, colorScheme: colorScheme)
        return LSlider(value)
            .linearSliderStyle(style)
            .frame(height: sliderHeights)
    }

    // MARK: - View Body
    public var body: some View {
        VStack(spacing: 20) {
            makeSlider( .cyan)
            makeSlider(.magenta)
            makeSlider(.yellow)
            makeSlider(.black)
        }
    }
}

// MARK: - Preview
struct CMYKColorPicker_Previews: PreviewProvider {

    static var previews: some View {
        ViewWithState()
            .previewDisplayName("CMYK Picker")
            .preferredColorScheme(.dark)
    }

    private struct ViewWithState : View {

        @State var color: ColorToken = .init(cyan: 0.42, magenta: 0.42, yellow: 0.42, keyBlack: 0.42)

        var body: some View {
            CMYKColorPicker($color)
                .frame(height: 40)
                .padding(.all, 40)
        }
    }
}
