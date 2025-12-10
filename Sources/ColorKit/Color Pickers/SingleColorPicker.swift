//
//  SingleColorPicker.swift
//  ColorKit
//
//  Original by Kieran Brown on 4/7/20.
//  Updates by Rose Kay in 2025.
// 

import SwiftUI
#if os(iOS)
import TipKit
#endif

// MARK: - Hex Input Tip
#if os(iOS)
@available(iOS 17.0, *)
struct HexInputTip: Tip {
    var title: Text {
        Text("Hex Color Input")
    }
    
    var message: Text? {
        Text("Enter hex code with/out the #. Supports (2) Gray, (3) RGB, (4) Gray/Alpha, (6) RRGGBB, (8) RRGGBBAA formats!!")
    }
    
    var image: Image? {
        Image(systemName: "number.circle")
    }

    @available(iOS 18.0, *)
    var options: [any Option] {
        [MaxDisplayDuration(150.0)]
    }
}
#endif

// MARK: - Single Color Picker View
@available(iOS 13.0, macOS 11.0, *)
public struct SingleColorPicker: View {
    @Binding public var color: ColorToken
    @State private var hexText: String = ""
    @State private var isShowingRadialHSB: Bool = false
    @State private var hexError: HexValidationError?
    @State private var showError: Bool = false

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
            420
        case .cmyk:
            220
        case .gray:
            120
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

    private var hsbColorPickers: some View {
        VStack {
            #if os(iOS)
            if #available(iOS 14.0, *) {
                Menu("Change View", systemImage: isShowingRadialHSB ? "circle" : "rectangle") {
                    Button("Rectangular", systemImage: "rectangle") {
                        isShowingRadialHSB = false
                    }
                    Button("Radial", systemImage: "circle") {
                        isShowingRadialHSB = true
                    }
                }
                .padding(.bottom, 8)
            }
            #endif

            ZStack {
                HSBColorPicker(self.selectedColor)
                    .opacity(!isShowingRadialHSB ? 1 : 0)
                    .allowsHitTesting(!isShowingRadialHSB)
                #if os(iOS)
                RadialHSBColorPicker(self.selectedColor)
                    .opacity(isShowingRadialHSB ? 1 : 0)
                    .allowsHitTesting(isShowingRadialHSB)
                #endif
            }
            .animation(.smooth, value: isShowingRadialHSB)
        }
    }

    private var currentColorPicker: some View {
        ZStack {
            VStack {
                rgbColorSpacePicker
                Spacer()
                RGBColorPicker(self.selectedColor)
            }
            .opacity(selectedColor.colorFormulation.wrappedValue == .rgb ? 1 : 0)
            .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .rgb)

            hsbColorPickers
                .opacity(selectedColor.colorFormulation.wrappedValue == .hsb ? 1 : 0)
                .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .hsb)

            CMYKColorPicker(self.selectedColor)
                .opacity(selectedColor.colorFormulation.wrappedValue == .cmyk ? 1 : 0)
                .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .cmyk)

            VStack {
                rgbColorSpacePicker
                GrayScaleSlider(self.selectedColor)
                    .frame(height: 68)
            }
            .opacity(selectedColor.colorFormulation.wrappedValue == .gray ? 1 : 0)
            .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .gray)
        }
        .animation(.easeInOut, value: selectedColor.colorFormulation.wrappedValue)
        .frame(height: frameHeight)
    }

    // MARK: - Text Overlays
    @available(iOS 15.0, macOS 13.0, *)
    private var fullPlusHexColorOverlay: some View {
        ZStack {
            VStack {
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

                    #if os(iOS)
                    if #available(iOS 17.0, *) {
                        TipView(HexInputTip(), arrowEdge: .bottom)
                            .tipImageSize(CGSizeMake(36, 36))
                            .padding(.horizontal)
                    }
                    #endif
                }

                VStack(spacing: 4) {
                    if #available(iOS 17.0, *) {
                        TextField("Hex Input", text: $hexText, prompt: Text(" # Hex Input"))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .textFieldStyle(.roundedBorder)
                            .clipShape(.capsule)
                            .overlay(content: {
                                Capsule()
                                    .stroke(
                                        showError ? Color.red : (colorScheme == .dark ? Color.dimColorDark.opacity(0.42) : Color.dimColorLight.opacity(0.42)),
                                        lineWidth: 2.4
                                    )
                            })
                            .frame(maxWidth: 112)
                            .padding(.top, 8)
                            .submitLabel(.done)
                            .onChange(of: hexText) {
                                showError = false
                                hexError = nil
                            }
                            .onSubmit {
                                validateAndApplyHex()
                            }
                    } else {
                        TextField("Hex Input", text: $hexText, prompt: Text(" # Hex Input"))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .textFieldStyle(.roundedBorder)
                            .clipShape(.capsule)
                            .overlay(content: {
                                Capsule()
                                    .stroke(
                                        showError ? Color.red : (colorScheme == .dark ? Color.dimColorDark.opacity(0.42) : Color.dimColorLight.opacity(0.42)),
                                        lineWidth: 2.4
                                    )
                            })
                            .frame(maxWidth: 112)
                            .padding(.top, 8)
                            .submitLabel(.done)
                            .onSubmit {
                                validateAndApplyHex()
                            }
                    }
                    
                    if showError, let error = hexError {
                        VStack(spacing: 2) {
                            Text(error.errorDescription ?? "Invalid hex")
                                .font(.caption)
                                .foregroundColor(.red)
                            if let suggestion = error.recoverySuggestion {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 8)
                        .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

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
                    fullPlusHexColorOverlay

                    fullColorOverlay

                    basicColorOverlay

                    Text("")
                }
            } else {
                fullColorOverlay
            }
        }
    }

    // MARK: - Main Content View
    private var mainContentView: some View {
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
    }

    // MARK: - View Body
    public var body: some View {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            mainContentView
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .ignoresSafeArea(.keyboard)
                .task {
                    if #available(iOS 17.0, *) {
//                        #if DEBUG
//                        try? Tips.resetDatastore()
//                        #endif
                        
                        try? Tips.configure([
                            .displayFrequency(.daily),
                            .datastoreLocation(.applicationDefault)
                        ])
                    }
                }
        } else {
            mainContentView
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
        }
        #elseif os(macOS)
        mainContentView
            .padding(.horizontal, 40)
            .padding(.bottom, 10)
            .padding(.top, 30)
        #else
        mainContentView
        #endif
    }
    
    // MARK: - Helper Methods
    private func validateAndApplyHex() {
        let validationResult = HexValidator.validate(hexText)
        
        switch validationResult {
        case .success(let validHex):
            if #available(iOS 14.0, macOS 11.0, *) {
                self.color = self.color.update(hex: validHex)
                hexText = ""
                showError = false
                hexError = nil
            }
        case .failure(let error):
            hexError = error
            showError = true
            
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
        }
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

        @State var color: ColorToken = .init(colorSpace: .sRGB, white: 0.26)

        var body: some View {
            SingleColorPicker($color, withAlpha: true)
        }
    }
}
