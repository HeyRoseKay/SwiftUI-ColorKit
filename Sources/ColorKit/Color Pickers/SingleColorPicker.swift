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
    @ObservedObject public var manager: ColorManager
    private let color: ColorToken
    
    // MARK: - Initialization
    public init(_ manager: ObservedObject<ColorManager>, color: ColorToken) {
        self._manager = manager
        self.color = color
    }
    
    // MARK: - Computed Properties
    private var selectedColor: Binding<ColorToken> {
        Binding(get: {
            return self.color
        }) {
            // No-op since we're not updating the color in the manager
            // The color is passed as a parameter and managed externally
            _ = $0
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
        }.padding(.vertical, 10)
    }
    
    private var hsbPicker: some View {
        HSBColorPicker(self.selectedColor)
    }
    
    private var currentColorPicker: some View {
        Group {
            if self.selectedColor.colorFormulation.wrappedValue == .rgb {
                rgbPicker
            } else if self.selectedColor.colorFormulation.wrappedValue == .hsb {
                hsbPicker
            } else if self.selectedColor.colorFormulation.wrappedValue == .cmyk {
                CMYKColorPicker(self.selectedColor)
            } else if self.selectedColor.colorFormulation.wrappedValue == .gray {
                GrayScaleSlider(self.selectedColor)
                    .frame(height: 40)
            }
        }.frame(height: 300)
    }
    
    // MARK: - View Body
    public var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 5)
                .fill(self.selectedColor.wrappedValue.color)
            
            formulationPicker
            currentColorPicker
            
            AlphaSlider(self.selectedColor)
                .frame(height: 40)
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 40)
    }
}
