//
//  SingleColorPicker.swift
//  ColorKit
//
//  Original by Kieran Brown on 4/7/20.
//  Updates by Rose Kay in 2025.
// 

import SwiftUI

// MARK: - Single Color Picker View
@available(iOS 13.0, macOS 11.0, *)
public struct SingleColorPicker: View {
    @Binding public var color: ColorToken
    @State private var isShowingRadialHSB: Bool = false
    @State private var hexError: HexValidationError?
    @State private var showError: Bool = false
    @State private var showHexFormatInfo: Bool = false
    @State private var privateText: String = ""
    private var hexText: Binding<String> {
        Binding {
            self.privateText
        } set: { newVal in
            self.privateText = newVal.uppercased()
        }
    }

    let withAlpha: Bool
    private let lastFormulation: Binding<ColorToken.ColorFormulation>?
    private let showColorSpacePicker: Binding<Bool>?

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initialization
    public init(_ color: Binding<ColorToken>, withAlpha: Bool, lastFormulation: Binding<ColorToken.ColorFormulation>? = nil, showColorSpacePicker: Binding<Bool>? = nil) {
        self._color = color
        self.withAlpha = withAlpha
        self.lastFormulation = lastFormulation
        self.showColorSpacePicker = showColorSpacePicker
    }

    // MARK: - Calculated Variables
    private var selectedColor: Binding<ColorToken> {
        Binding(get: {
            return self.color
        }) {
            self.color = $0
        }
    }

    /// The height a formulation's controls want when there is room to spare.
    private var idealPickerHeight: CGFloat {
        switch self.selectedColor.wrappedValue.colorFormulation {
        case .rgb:
            showColorSpacePicker?.wrappedValue == true ? 208: 160
        case .hsb:
            345
        case .cmyk:
            212
        case .gray:
            showColorSpacePicker?.wrappedValue == true ? 112 : 80
        }
    }

    /// The smallest height a formulation's controls stay usable at. Only HSB can shrink, because its track pad is the one control that scales; the rest  fixed stacks of sliders and so are already at their minimum.
    private var minimumPickerHeight: CGFloat {
        switch self.selectedColor.wrappedValue.colorFormulation {
        case .hsb:
            200
        default:
            idealPickerHeight
        }
    }

    private var textColor: Color {
        // If color is transparent, use environment color scheme colors
        if color.alpha < 0.42 {
            return colorScheme == .dark ? Color.white : Color.black
        }

        // Because Color Formulations are now Synced just check Luminance
        let luminance = (0.299 * color.red) + (0.587 * color.green) + (0.114 * color.blue)
        return luminance < 0.5 ? Color.white : Color.black
    }

    // MARK: - Picker Components
    private var formulationBinding: Binding<ColorToken.ColorFormulation> {
        Binding {
            color.colorFormulation
        } set: { newVal in
            color.colorFormulation = newVal
            lastFormulation?.wrappedValue = newVal
        }
    }

    private var formulationPicker: some View {
        Picker(selection: formulationBinding, label: Text("Color Formulation")) {
            ForEach(ColorToken.ColorFormulation.allCases) { (formulation)  in
                Text(formulation.rawValue).tag(formulation)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .labelsHidden()
    }

    private var rgbColorSpacePicker: some View {
        Picker(selection: self.selectedColor.rgbColorSpace, label: Text("Color Space")) {
            ForEach(ColorToken.RGBColorSpace.allCases) { space in
                Text(space.rawValue).tag(space)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .labelsHidden()
    }

    @available(iOS 15.0, macOS 13.0, *)
    private var hexInputField: some View {
        Group {
            if #available(iOS 17.0, macOS 14.0, *) {
                #if os(iOS)
                TextField("Hex Input", text: hexText, prompt: Text(" # Hex Input"))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .textFieldStyle(.roundedBorder)
                    .clipShape(.capsule)
                    .overlay(content: {
                        Capsule()
                            .stroke(
                                showError ? Color.red.opacity(0.84) : (colorScheme == .dark ? Color.dimColorDark.opacity(0.84) : Color.dimColorLight.opacity(0.84)),
                                lineWidth: 2.1
                            )
                    })
                    .submitLabel(.done)
                    .onChange(of: hexText.wrappedValue) {
                        showError = false
                        hexError = nil
                    }
                    .onSubmit {
                        validateAndApplyHex()
                    }
                #else
                TextField("Hex Input", text: hexText, prompt: Text(" # Hex Input"))
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .clipShape(.capsule)
                    .overlay(content: {
                        Capsule()
                            .stroke(
                                showError ? Color.red : (colorScheme == .dark ? Color.dimColorDark.opacity(0.42) : Color.dimColorLight.opacity(0.42)),
                                lineWidth: 2.4
                            )
                    })
                    .submitLabel(.done)
                    .onChange(of: hexText.wrappedValue) {
                        showError = false
                        hexError = nil
                    }
                    .onSubmit {
                        validateAndApplyHex()
                    }
                #endif
            } else {
                TextField("Hex Input", text: hexText, prompt: Text(" # Hex Input"))
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .clipShape(.capsule)
                    .overlay(content: {
                        Capsule()
                            .stroke(
                                showError ? Color.red : (colorScheme == .dark ? Color.dimColorDark.opacity(0.42) : Color.dimColorLight.opacity(0.42)),
                                lineWidth: 2.4
                            )
                    })
                    .submitLabel(.done)
                    .onSubmit {
                        validateAndApplyHex()
                    }
            }
        }
        .padding(.horizontal, 6)
    }


    /// Description of every hex length the validator accepts, shown from the info button.
    @available(iOS 15.0, macOS 13.0, *)
    private var hexFormatInfoContent: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            Label("Hex Color Input", systemImage: "number.circle")
                .font(.headline)

            Group {
                Text("Enter a hex code with").offset(y: 3)
                Text("or without the #.").offset(y: -3)
            }
            .font(.subheadline)

            VStack(alignment: .leading, spacing: 3) {
                Text("2 digits — Gray")
                Text("3 digits — RGB")
                Text("4 digits — Gray + Alpha")
                Text("6 digits — RRGGBB")
                Text("8 digits — RRGGBBAA")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: 260, alignment: .leading)

        return Group {
            // Keeps the popover a popover on iPhone instead of adapting into a sheet.
            if #available(iOS 16.4, macOS 13.3, *) {
                content.presentationCompactAdaptation(.popover)
            } else {
                content
            }
        }
    }

    @available(iOS 15.0, macOS 13.0, *)
    private var hexFormatInfoButton: some View {
        Button {
            showHexFormatInfo = true
        } label: {
            Image(systemName: "info.circle")
                .imageScale(.large)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hex format help")
        .popover(isPresented: $showHexFormatInfo, arrowEdge: .top) {
            hexFormatInfoContent
        }
        .padding(.trailing, 6)
    }

    @available(iOS 15.0, macOS 13.0, *)
    private var hexInputSection: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                hexInputField

                hexFormatInfoButton
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
        }
    }

    // MARK: - Current Color Picker
    private var currentColorPicker: some View {
        ZStack {
            VStack {
                if showColorSpacePicker?.wrappedValue == true {
                    rgbColorSpacePicker
                    Spacer()
                }
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
                if showColorSpacePicker?.wrappedValue == true {
                    rgbColorSpacePicker
                }
                GrayScaleSlider(self.selectedColor)
                    .frame(height: 68)
            }
            .opacity(selectedColor.colorFormulation.wrappedValue == .gray ? 1 : 0)
            .allowsHitTesting(selectedColor.colorFormulation.wrappedValue == .gray)
        }
    }

    // MARK: - Text Overlays
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

    /// Read-out drawn on top of the swatch, degrading from every component down to just the hex string, and to nothing at all when even that cannot fit.
    private var colorDescriptionOverlay: some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                ViewThatFits(in: .vertical) {
                    fullColorOverlay

                    basicColorOverlay

                    EmptyView()
                }
            } else {
                fullColorOverlay
            }
        }
        .padding(.horizontal, 8)
        .clipped()
    }

    // MARK: - Swatch
    private var colorSwatch: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 2)
                    .fill(self.selectedColor.wrappedValue.color)
            } else if #available(iOS 17.0, macOS 14.0, *) {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(colorScheme == .dark ? Color.dimColorDark : Color.dimColorLight, lineWidth: 2)
                    .fill(self.selectedColor.wrappedValue.color)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(self.selectedColor.wrappedValue.color)
            }
        }
        // A floor for the overflow case: without it the swatch is the view that absorbs leftover space, so a formulation taller than its container would squeeze it away.
        .frame(minHeight: 124)
        .overlay(colorDescriptionOverlay)
    }

    /// Hex entry sits above the swatch rather than inside its overlay, so it is always present no matter which formulation is showing or how large the text is, and so the keyboard cannot cover it while the layout is pinned by `ignoresSafeArea(.keyboard)`.
    @ViewBuilder
    private var hexInputRow: some View {
        if #available(iOS 15.0, macOS 13.0, *) {
            hexInputSection
        }
    }

    private var swatchGroup: some View {
        VStack(spacing: 18) {
            hexInputRow

            colorSwatch
        }
    }

    // MARK: - Layouts
    /// Stacked layout, used whenever the container is taller than it is wide.
    private var verticalContent: some View {
        VStack(spacing: 16) {
            swatchGroup

            formulationPicker

            currentColorPicker
                .frame(height: idealPickerHeight)

            if withAlpha {
                AlphaSlider(self.selectedColor)
                    .frame(height: 40)
            }
        }
    }

    /// Side by side layout for landscape, so the swatch stays on screen while the taller formulations use the full height of the container instead of scrolling out of view.
    private var horizontalContent: some View {
        HStack(alignment: .top, spacing: 42) {
            swatchGroup
                .frame(minWidth: 160, maxWidth: 300, maxHeight: .infinity)

            VStack(spacing: 16) {
                formulationPicker

                currentColorPicker
                    .frame(minHeight: minimumPickerHeight, maxHeight: idealPickerHeight)

                if withAlpha {
                    AlphaSlider(self.selectedColor)
                        .frame(height: 40)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// The wide layout needs its horizontal inset back for the second column, and macOS wants more room above the swatch when the content is stacked.
    private func contentInsets(isWide: Bool) -> EdgeInsets {
        #if os(macOS)
        return isWide
            ? EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 42)
            : EdgeInsets(top: 24, leading: 36, bottom: 12, trailing: 36)
        #else
        return isWide
            ? EdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 42)
            : EdgeInsets(top: 10, leading: 36, bottom: 10, trailing: 36)
        #endif
    }

    /// A ScrollView proposes an unbounded height, so any flexible subview inside it falls back to its ideal size: the swatch collapses to its minimum and the wide layout's picker snaps straight to its tallest height. Proposing the visible height instead lets both fill the viewport, while still letting the content grow past it, and so scroll, once the minimums no longer fit.
    private func adaptiveContent(isWide: Bool, availableHeight: CGFloat) -> some View {
        Group {
            if isWide {
                horizontalContent
            } else {
                verticalContent
            }
        }
        .frame(idealHeight: availableHeight)
    }

    /// A single scroll view wrapping the whole picker, so oversized text or a formulation taller than its container can still be reached.
    @ViewBuilder
    private func scrollContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            ScrollView {
                content()
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView {
                content()
            }
        }
    }

    @ViewBuilder
    private func ignoringKeyboard<Content: View>(_ content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            content.ignoresSafeArea(.keyboard)
        } else {
            content
        }
        #else
        content
        #endif
    }

    // MARK: - View Body
    public var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > proxy.size.height
            let insets = contentInsets(isWide: isWide)
            let availableHeight = max(proxy.size.height - insets.top - insets.bottom, minimumPickerHeight)

            scrollContainer {
                ignoringKeyboard(
                    adaptiveContent(isWide: isWide, availableHeight: availableHeight)
                        .padding(insets)
                )
            }
        }
        .onAppear {
            if let lastFormulation {
                color.colorFormulation = lastFormulation.wrappedValue
            }
        }
    }

    // MARK: - Helper Methods
    private func validateAndApplyHex() {
        let validationResult = HexValidator.validate(hexText.wrappedValue)

        switch validationResult {
        case .success(let validHex):
            if #available(iOS 14.0, macOS 11.0, *) {
                self.color = self.color.update(hex: validHex)
                hexText.wrappedValue = ""
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
        Group {
            ViewWithState()
                .previewDisplayName("Single Color Picker")

            if #available(iOS 15.0, *) {
                ViewWithState()
                    .previewInterfaceOrientation(.landscapeLeft)
                    .previewDisplayName("Single Color Picker — Landscape")
            }
        }
        .preferredColorScheme(.dark)
    }
    #elseif os(macOS)
    static var previews: some View {
        Group {
            ViewWithState()
                .frame(width: 400, height: 800)
                .previewDisplayName("Single Color Picker")

            ViewWithState()
                .frame(width: 900, height: 480)
                .previewDisplayName("Single Color Picker — Wide")
        }
        .preferredColorScheme(.dark)
    }
    #endif

    private struct ViewWithState : View {

        @State var color: ColorToken = .init(colorSpace: .displayP3, r: 0.33, g: 0.66, b: 0.99, a: 1) // RGB
//        @State var color: ColorToken = .init(hue: 0.88, saturation: 0.69, brightness: 0.69, opacity: 1) // HSB
//        @State var color: ColorToken = .init(cyan: 0.42, magenta: 1, yellow: 0, keyBlack: 0.42) // CMYK
//        @State var color: ColorToken = .init(colorSpace: .sRGB, white: 0.26) // Gray

        var body: some View {
            SingleColorPicker($color, withAlpha: true, showColorSpacePicker: .constant(true))
        }
    }
}
