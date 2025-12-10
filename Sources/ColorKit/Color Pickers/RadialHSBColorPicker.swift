//
//  RadialHSBColorPicker.swift
//  ColorKit
//
//  Original by Kieran Brown on 4/7/20.
//  Updates by Rose Kay in 2025.
//

#if os(iOS)
import SwiftUI
import Shapes
import Sliders

// MARK: - Hue L Slider Style
@available(iOS 13.0, *)
public struct RadialHueSliderStyle: LSliderStyle {
    let color: ColorToken
    public var sliderHeight: CGFloat
    let colorScheme: ColorScheme

    var gradient: Gradient {
        Gradient(colors: [Color(hue: color.hue, saturation: color.saturation, brightness: 0),
                          Color(hue: color.hue, saturation: color.saturation, brightness: 1)])
    }

    public func makeThumb(configuration: LSliderConfiguration) -> some View {
        Circle()
            .fill(color.color)
            .frame(width: sliderHeight, height: sliderHeight)
            .overlay(GeometryReader { proxy in
                Circle()
                    .stroke(colorScheme == .dark ? Color.prominentColorDark : Color.prominentColorLight, lineWidth: 2)
                    .shadow(radius: 2)
            })
    }
    
    public func makeTrack(configuration: LSliderConfiguration) -> some View {
        let style: StrokeStyle = .init(lineWidth: sliderHeight, lineCap: .round)
        let gradient = LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
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

// MARK: - Saturation Hue Radial Pad
@available(iOS 13.0, *)
struct SaturationHueRadialPad: RadialPadStyle {
    let brightness: Double
    let colorScheme: ColorScheme

    var hueColors: [Color] {
        stride(from: 0, to: 1, by: 0.01).map {
            Color(hue: $0, saturation: 1, brightness: brightness)
        }
    }

    func makeThumb(configuration: RadialPadConfiguration) -> some View {
        let adjustedAngle = (configuration.angle.degrees + 90).truncatingRemainder(dividingBy: 360)
        let normalizedAngle = adjustedAngle < 0 ? adjustedAngle + 360 : adjustedAngle
        let color = Color(hue: (normalizedAngle/360), saturation: configuration.radialOffset, brightness: self.brightness)
        return Circle()
            .fill(color)
            .frame(width: 36, height: 36)
            .overlay(GeometryReader { proxy in
                Circle()
                    .stroke(colorScheme == .dark ? Color.prominentColorDark : Color.prominentColorLight, lineWidth: 2)
                    .shadow(radius: 2)
            })
    }

    func makeTrack(configuration: RadialPadConfiguration) -> some View {
        if #available(iOS 15.0, *) {
            return ZStack {
                Circle()
                    .fill(Color(hue: 0, saturation: 0, brightness: self.brightness))
                HueCircleView()
                    .rotationEffect(.degrees(-90))
                    .blendMode(.plusDarker)
            }.overlay(
                Circle()
                    .stroke(Material.thin, lineWidth: 2)
            )
        } else {
            return ZStack {
                Circle()
                    .fill(Color(hue: 0, saturation: 0, brightness: self.brightness))
                HueCircleView()
                    .rotationEffect(.degrees(-90))
                    .blendMode(.plusDarker)
            }.overlay(
                Circle()
                    .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 1)
            )
        }
    }
}

// MARK: - HSB Color Picker View
@available(iOS 13.0, *)
public struct RadialHSBColorPicker: View {
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
        VStack(spacing: 24) {
            RadialPad(offset: Binding(get: {self.color.saturation}, set: {self.color = self.color.update(saturation: $0)}),
                      angle: Binding(
                        get: {
                            let adjustedHue = self.color.hue - 0.25
                            let normalizedHue = adjustedHue < 0 ? adjustedHue + 1 : adjustedHue
                            return Angle(degrees: normalizedHue * 360)
                        },
                        set: {
                            let adjustedDegrees = $0.degrees + 90
                            let normalizedDegrees = adjustedDegrees >= 360 ? adjustedDegrees - 360 : adjustedDegrees
                            self.color = self.color.update(hue: normalizedDegrees / 360)
                        }))
                .radialPadStyle(SaturationHueRadialPad(brightness: color.brightness, colorScheme: colorScheme))

            LSlider(Binding(get: {self.color.brightness}, set: {self.color = self.color.update(brightness: $0)}))
                .linearSliderStyle(RadialHueSliderStyle(color: self.color, sliderHeight: sliderHeight, colorScheme: colorScheme))
                .frame(height: sliderHeight)
        }
    }
}

// MARK: - Preview
struct RadialHSBColorPicker_Previews: PreviewProvider {

    static var previews: some View {
        ViewWithState()
            .previewDisplayName("HSB Radial Picker")
            .preferredColorScheme(.dark)
    }

    private struct ViewWithState : View {

        @State var color: ColorToken = .init(hue: 0.69, saturation: 0.69, brightness: 0.69)

        var body: some View {
            RadialHSBColorPicker($color)
                .frame(height: 360)
                .padding(.all, 40)
        }
    }
}
#endif
