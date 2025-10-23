//
//  Color+Extensions.swift
//  ColorKit
//
//  Created by Rose Kay on 10/15/25.
//

import SwiftUI

extension Color {
    // MARK: - Static Colors
    static let dimColorLight = Color(red: 0.600, green: 0.600, blue: 0.600, opacity: 0.840)
    static let dimColorDark = Color(red: 0.400, green: 0.400, blue: 0.400, opacity: 0.840)
    static let prominentColorLight = Color(red: 0.400, green: 0.400, blue: 0.400, opacity: 1.000)
    static let prominentColorDark = Color(red: 0.600, green: 0.600, blue: 0.600, opacity: 1.000)

    // MARK: Hex Conversion
    func toHex(for colorSpace: RGBColorSpace) -> String {
        if #available(iOS 14.0, macOS 11.0, *) {
            let platformColor = PlatformColor(self)
            
            if colorSpace == .sRGB {
                let srgbSpace = CGColorSpace(name: CGColorSpace.sRGB)!
                guard let srgbColor = platformColor.cgColor.converted(to: srgbSpace, intent: .defaultIntent, options: nil),
                                    let components = srgbColor.components,
                                    components.count >= 3 else {
                    print("Color.toHex: Failed to convert CGColor to sRGB or get components")
                    return "#000000"
                }
                return getHexFromComponents(components)
            } else if colorSpace == .sRGBLinear {
                let linearSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
                guard let srgbLinearColor = platformColor.cgColor.converted(to: linearSpace, intent: .defaultIntent, options: nil),
                                    let components = srgbLinearColor.components,
                                    components.count >= 3 else {
                    print("Color.toHex: Failed to convert CGColor to Linear sRGB or get components")
                    return "#000000"
                }
                return getHexFromComponents(components)
            } else if colorSpace == .displayP3 {
                let p3Space = CGColorSpace(name: CGColorSpace.displayP3)!
                guard let p3Color = platformColor.cgColor.converted(to: p3Space, intent: .defaultIntent, options: nil),
                                    let components = p3Color.components,
                                    components.count >= 3 else {
                    print("Color.toHex: Failed to convert CGColor to Linear sRGB or get components")
                    return "#000000"
                }
                let p3Text = "P3-" + getHexFromComponents(components)
                return p3Text
            }
        } else {
            // Fallback on earlier versions
            // How to Initialize PlatformColor from Color in iOS 13 and earlier?
        }
        return "#000000"
    }

    private func getHexFromComponents(_ components: [CGFloat]) -> String {
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = components.count >= 4 ? Float(components[3]) : Float(1.0)

        if a != Float(1.0) {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }

///          Specifying color with or without leading #.
///          2-digit format for shades of gray.
///          3-digit format for shorthand 6-digit format.
///          4-digit format for gray with alpha.
///          6-digit format for RGB.
///          8-digit format for RGBA.
///          Automatically returns nil for all invalid formats.
///
///          let gray1 = Color("4f")
///          let gray2 = Color("#68")
///          let gray3 = Color("7813")
///          let red = Color("f00")
///          let translucentGreen = Color("#00FF0066")
///          let blue = Color("0000FF")
///          let invalid = Color("0000F")
    // MARK: Best Hex Reader
    init?(hex: String) {
        var str = hex
        if str.hasPrefix("#") {
            str.removeFirst()
        }
        if str.count == 3 {
            str = String(repeating: str[str.startIndex], count: 2)
            + String(repeating: str[str.index(str.startIndex, offsetBy: 1)], count: 2)
            + String(repeating: str[str.index(str.startIndex, offsetBy: 2)], count: 2)
        } else if !str.count.isMultiple(of: 2) || str.count > 8 {
            return nil
        }
        guard let color = UInt64(str, radix: 16)
        else {
            return nil
        }
        if str.count == 2 {
            let gray = Double(Int(color) & 0xFF) / 255
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)
        } else if str.count == 4 {
            let gray = Double(Int(color >> 8) & 0x00FF) / 255
            let alpha = Double(Int(color) & 0x00FF) / 255
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)
        } else if str.count == 6 {
            let red = Double(Int(color >> 16) & 0x0000FF) / 255
            let green = Double(Int(color >> 8) & 0x0000FF) / 255
            let blue = Double(Int(color) & 0x0000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        } else if str.count == 8 {
            let red = Double(Int(color >> 24) & 0x000000FF) / 255
            let green = Double(Int(color >> 16) & 0x000000FF) / 255
            let blue = Double(Int(color >> 8) & 0x000000FF) / 255
            let alpha = Double(Int(color) & 0x000000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        } else {
            return nil
        }
    }
}
