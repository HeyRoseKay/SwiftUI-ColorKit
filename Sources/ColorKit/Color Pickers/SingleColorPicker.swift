//
//  SingleColorPicker.swift
//  MyExamples
//
//  Created by Kieran Brown on 4/7/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , *)
public struct SingleColorPicker: View {
    @Binding public var color: ColorToken

    // MARK: - Initialization
    public init(_ color: Binding<ColorToken>) {
        self._color = color
    }

    private var selectedColor: Binding<ColorToken> {
        Binding(get: {
            return self.color
        }) {
            self.color = $0
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
            if self.selectedColor.colorFormulation.wrappedValue == .rgb {
                ZStack {
                    rgbPicker
                }.frame(height: 220)
            } else if self.selectedColor.colorFormulation.wrappedValue == .hsb {
                ZStack {
                    HSBColorPicker(self.selectedColor)
                }.frame(height: 300)
            } else if self.selectedColor.colorFormulation.wrappedValue == .cmyk {
                ZStack {
                    CMYKColorPicker(self.selectedColor)
                }.frame(height: 220)
            } else if self.selectedColor.colorFormulation.wrappedValue == .gray {
                ZStack {
                    GrayScaleSlider(self.selectedColor)
                        .frame(height: 68)
                }.frame(height: 80)
            }
        }.animation(.easeInOut, value: self.selectedColor.colorFormulation.wrappedValue)
    }

    private var colorDescriptionOverlay: some View {
        ZStack {
            if self.selectedColor.colorFormulation.wrappedValue == .rgb {
                let white: CGFloat = (color.red + color.green + color.blue) / 3
                VStack {
                    Text("Red: \(String(format: "%.0f", color.red*255))")
                    Text("Green: \(String(format: "%.0f", color.green*255))")
                    Text("Blue: \(String(format: "%.0f", color.blue*255))")
                    Text(String(color.color.description))
                }.foregroundColor(white > 0.5 ? Color.black : Color.white)
            } else if self.selectedColor.colorFormulation.wrappedValue == .hsb {
                VStack {
                    Text("Hue: \(String(format: "%.0f", color.hue*360))")
                    Text("Saturation: \(String(format: "%.0f", color.saturation*100))%")
                    Text("Brightness: \(String(format: "%.0f", color.brightness*100))%")
                    Text(String(color.color.description))
                }.foregroundColor(color.brightness > 0.5 ? Color.black : Color.white)
            } else if self.selectedColor.colorFormulation.wrappedValue == .cmyk {
                VStack {
                    Text("Cyan: \(String(format: "%.0f", color.cyan*100))%")
                    Text("Magenta: \(String(format: "%.0f", color.magenta*100))%")
                    Text("Yellow: \(String(format: "%.0f", color.yellow*100))%")
                    Text("Black: \(String(format: "%.0f", color.keyBlack*100))%")
                    Text(String(color.color.description))
                }.foregroundColor(color.keyBlack < 0.5 ? Color.black : Color.white)
            } else if self.selectedColor.colorFormulation.wrappedValue == .gray {
                VStack {
                    Text("white: \(String(format: "%.0f", color.white*100))%")
                    Text(String(color.color.description))
                }.foregroundColor(color.white > 0.5 ? Color.black : Color.white)
            }
        }
    }

    // MARK: - View Body
    public var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 10)
                .fill(self.selectedColor.wrappedValue.color)
                .overlay(colorDescriptionOverlay)

            Divider()

            formulationPicker
            currentColorPicker
            
            AlphaSlider(self.selectedColor)
                .frame(height: 40)
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 40)
    }
}
