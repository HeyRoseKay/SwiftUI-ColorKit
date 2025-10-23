//
//  SingleColorPicker.swift
//  MyExamples
//
//  Created by Kieran Brown on 4/7/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI

// MARK: - Single Color Picker View
@available(iOS 13.0, macOS 11.0, *)
public struct SingleColorPicker: View {
    @Binding public var color: ColorToken
    let withAlpha: Bool

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initialization
    public init(_ color: Binding<ColorToken>, withAlpha: Bool) {
        self._color = color
        self.withAlpha = withAlpha
    }

    // MARK: - Calculated Variables
    private var selectedColor: Binding<ColorToken> {
        Binding(get: {
            return self.color
        }) {
            self.color = $0
        }
    }

    private var frameHeight: CGFloat {
        switch self.selectedColor.wrappedValue.colorFormulation {
        case .rgb:
            220
        case .hsb:
            300
        case .cmyk:
            220
        case .gray:
            80
        }
    }

    private var textColor: Color {
        // If color is transparent, use environment color scheme colors
        if color.alpha < 0.42 {
            return colorScheme == .dark ? Color.white : Color.black
        }
        
        // For opaque colors, calculate based on brightness
        switch selectedColor.colorFormulation.wrappedValue {
        case .rgb:
            let white: CGFloat = (color.red + color.green + color.blue) / 3
            return white > 0.5 ? Color.black : Color.white
        case .hsb:
            return color.brightness > 0.6 ? Color.black : Color.white
        case .cmyk:
            let black: CGFloat = (color.cyan + color.magenta + color.yellow) / 3
            if black > 0.6 {
                return Color.white
            } else if color.keyBlack < 0.4 {
                return Color.black
            } else {
                return Color.white
            }
        case .gray:
            return color.white > 0.5 ? Color.black : Color.white
        }
    }

    // MARK: - Picker Components
    private var formulationPicker: some View {
        Picker(selection: self.selectedColor.colorFormulation, label: Text("Color Formulation")) {
            ForEach(ColorToken.ColorFormulation.allCases) { (formulation)  in
                Text(formulation.rawValue).tag(formulation)
            }
        }.pickerStyle(SegmentedPickerStyle())
    }

    private var rgbColorSpacePicker: some View {
        Picker(selection: self.selectedColor.rgbColorSpace, label: Text("")) {
            ForEach(ColorToken.RGBColorSpace.allCases) { space in
                Text(space.rawValue).tag(space)
            }
        }.pickerStyle(SegmentedPickerStyle())
    }

    private var rgbPicker: some View {
        VStack {
            rgbColorSpacePicker
            Spacer()
            RGBColorPicker(self.selectedColor)
        }
    }

    private var currentColorPicker: some View {
        ZStack {
            rgbPicker
                .opacity(selectedColor.colorFormulation.wrappedValue == .rgb ? 1 : 0)
                .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .rgb)

            HSBColorPicker(self.selectedColor)
                .opacity(selectedColor.colorFormulation.wrappedValue == .hsb ? 1 : 0)
                .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .hsb)

            CMYKColorPicker(self.selectedColor)
                .opacity(selectedColor.colorFormulation.wrappedValue == .cmyk ? 1 : 0)
                .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .cmyk)

            ZStack {
                GrayScaleSlider(self.selectedColor)
                    .frame(height: 68)
            }
            .opacity(selectedColor.colorFormulation.wrappedValue == .gray ? 1 : 0)
            .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .gray)
        }
        .animation(.easeInOut, value: selectedColor.colorFormulation.wrappedValue)
        .frame(height: frameHeight)
    }

    // MARK: - Text Overlay
    private var fullColorOverlay: some View {
        ZStack {
            if self.selectedColor.colorFormulation.wrappedValue == .rgb {
                VStack {
                    Text("Red: \(String(format: "%.0f", color.red*255))")
                    Text("Green: \(String(format: "%.0f", color.green*255))")
                    Text("Blue: \(String(format: "%.0f", color.blue*255))")
                    Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                }.foregroundColor(textColor)
            } else if self.selectedColor.colorFormulation.wrappedValue == .hsb {
                VStack {
                    Text("Hue: \(String(format: "%.0f", color.hue*360))")
                    Text("Saturation: \(String(format: "%.0f", color.saturation*100))%")
                    Text("Brightness: \(String(format: "%.0f", color.brightness*100))%")
                    Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                }.foregroundColor(textColor)
            } else if self.selectedColor.colorFormulation.wrappedValue == .cmyk {
                VStack {
                    Text("Cyan: \(String(format: "%.0f", color.cyan*100))%")
                    Text("Magenta: \(String(format: "%.0f", color.magenta*100))%")
                    Text("Yellow: \(String(format: "%.0f", color.yellow*100))%")
                    Text("Black: \(String(format: "%.0f", color.keyBlack*100))%")
                    Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                }.foregroundColor(textColor)
            } else if self.selectedColor.colorFormulation.wrappedValue == .gray {
                VStack {
                    Text("White: \(String(format: "%.0f", color.white*100))%")
                    Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                    Text("Alpha: \(String(format: "%.0f", color.alpha*100))%")
                }.foregroundColor(textColor)
            }
        }
    }

    private var basicColorOverlay: some View {
        ZStack {
             if self.selectedColor.colorFormulation.wrappedValue == .rgb {
                 Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                     .foregroundColor(textColor)
             } else if self.selectedColor.colorFormulation.wrappedValue == .hsb {
                 Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                     .foregroundColor(textColor)
             } else if self.selectedColor.colorFormulation.wrappedValue == .cmyk {
                 Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                     .foregroundColor(textColor)
             } else if self.selectedColor.colorFormulation.wrappedValue == .gray {
                 Text(String(color.color.toHex(for: color.rgbColorSpace.space)))
                     .foregroundColor(textColor)
             }
         }
    }

    private var colorDescriptionOverlay: some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                ViewThatFits(in: .vertical) {
                    fullColorOverlay

                    basicColorOverlay

                    Text("")
                }
            } else {
                fullColorOverlay
            }
        }
    }

    // MARK: - Platform-specific Padding
    private func applyPlatformPadding<Content: View>(to content: Content) -> some View {
        #if os(iOS)
        return AnyView(
            content
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
        )
        #elseif os(macOS)
        return AnyView(
            content
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                .padding(.top, 30)
        )
        #else
        return AnyView(content)
        #endif
    }

    // MARK: - View Body
    public var body: some View {
        applyPlatformPadding(to:
            VStack(spacing: 20) {
                if #available(iOS 26.0, macOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 2)
                        .fill(self.selectedColor.wrappedValue.color)
                        .overlay(colorDescriptionOverlay)
                } else if #available(iOS 17.0, macOS 14.0, *) {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 2)
                        .fill(self.selectedColor.wrappedValue.color)
                        .overlay(colorDescriptionOverlay)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(self.selectedColor.wrappedValue.color)
                        .overlay(colorDescriptionOverlay)
                }

                formulationPicker
                if withAlpha {
                    currentColorPicker
                    AlphaSlider(self.selectedColor)
                        .frame(height: 40)
                        .padding(.bottom, 10)
                } else {
                    currentColorPicker
                        .padding(.bottom, 10)
                }
            }
        )
    }
}

// MARK: - Preview
struct SingleColorPicker_Previews: PreviewProvider {

    #if os(iOS)
    static var previews: some View {
        ViewWithState()
            .previewDisplayName("Single Color Picker")
            .preferredColorScheme(.dark)
    }
    #elseif os(macOS)
    static var previews: some View {
        ViewWithState()
            .frame(height: 800)
            .previewDisplayName("Single Color Picker")
            .preferredColorScheme(.dark)
    }
    #endif

    private struct ViewWithState : View {

        @State var color: ColorToken = .init(colorSpace: .sRGB, r: 0.42, g: 0.42, b: 0.42)

        var body: some View {
            SingleColorPicker($color, withAlpha: true)
        }
    }
}
