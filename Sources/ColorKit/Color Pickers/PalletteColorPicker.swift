//
//  PalletteColorPicker.swift
//  MyExamples
//
//  Created by Kieran Brown on 4/7/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI

// MARK: - Color Picker Button Style
@available(iOS 13.0, macOS 11.0, *)
public struct ColorPickerButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white : .blue)
            .frame(width: 20, height: 20)
            .padding()
            .background(
                Group {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue)
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue)
                    }
            })
    }
}

// MARK: - Pallette Color Picker View
@available(iOS 13.0, macOS 11.0, *)
public struct PalletteColorPicker: View {
    @ObservedObject public var manager: ColorManager
    let withAlpha: Bool
    
    public init(_ manager: ObservedObject<ColorManager>, withAlpha: Bool) {
        self._manager = manager
        self.withAlpha = withAlpha
    }

    private func select(_ id: UUID) {
        if self.manager.selected == id {
            self.manager.selected = nil
        } else {
            self.manager.selected = id
        }
    }

    // MARK: - Computed Variables
    private var colors: [ColorToken] {
        Array(self.manager.colors.values).sorted(by: {$0.dateCreated > $1.dateCreated})
    }
    
    private var selectedColor: Binding<ColorToken> {
        Binding(get: {
            if self.manager.selected == nil {
                return self.manager.defaultColor
            } else {
                return self.manager.colors[self.manager.selected!]!
            }
        }) {
            if self.manager.selected == nil {
                self.manager.defaultColor = $0
            } else {
                self.manager.colors[self.manager.selected!]! = $0
            }
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

    // MARK: - Picker Views
    private var pallette: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                ForEach(self.colors) { (color)  in
                    Rectangle()
                        .fill(color.color)
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            self.select(color.id)
                    }.border(self.manager.selected == color.id ? Color.blue : Color.clear)
                }
            }
        }
    }

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

    // MARK: - Buttons
    private var buttons: some View {
        HStack(spacing: 20) {
            Button(action: self.manager.delete, label: {
                Group {
                    #if os(macOS)
                    if #available(macOS 11.0, *) {
                        Image(systemName: "xmark")
                    } else {
                        Text("✕")
                    }
                    #else
                    Image(systemName: "xmark")
                    #endif
                }
                .font(.system(size: 34, weight: .bold))
            })
            Button(action: self.manager.add, label: {
                Group {
                    #if os(macOS)
                    if #available(macOS 11.0, *) {
                        Image(systemName: "plus")
                    } else {
                        Text("+")
                    }
                    #else
                    Image(systemName: "plus")
                    #endif
                }
                .font(.system(size: 36, weight: .bold))
            })
        }.frame(height: 30)
    }

    // MARK: - View Body
    public var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 10)
                .fill(self.selectedColor.wrappedValue.color)
            pallette
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
            buttons
        }.padding(.horizontal, 40)
    }
}

// MARK: - Preview
struct PalletteColorPicker_Previews: PreviewProvider {

    static var previews: some View {
        ViewWithState()
            .previewDisplayName("Pallette Color Picker")
            .preferredColorScheme(.dark)
    }

    private struct ViewWithState : View {

        @ObservedObject var manager: ColorManager = ColorManager(colors: [ColorToken(hue: 0.3, saturation: 0.5, brightness: 0.5),
             ColorToken(hue: 0.6, saturation: 0.5, brightness: 0.5),
             ColorToken(hue: 0.9, saturation: 0.5, brightness: 0.5)])

        var body: some View {
            PalletteColorPicker(_manager, withAlpha: true)
        }
    }
}
