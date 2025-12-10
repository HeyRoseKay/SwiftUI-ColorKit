//
//  ColorToken.swift
//  ColorKit
//
//  Original by Kieran Brown on 4/8/20.
//  Updates by Rose Kay in 2025.
//

import SwiftUI

// MARK: - Color Token
@available(iOS 13.0, macOS 11.0, *)
public struct ColorToken: Identifiable, Codable, Equatable, Hashable {
    public enum ColorFormulation: String, CaseIterable, Identifiable, Decodable, Encodable, Equatable, Hashable {
        case rgb
        case hsb
        case cmyk
        case gray
        
        public var id: String {self.rawValue}
    }
    public enum RGBColorSpace: String, CaseIterable, Identifiable, Codable, Equatable, Hashable {
        case displayP3
        case sRGB
        case sRGBLinear
        
        public var id: String {self.rawValue}
        
        public var space: Color.RGBColorSpace {
            switch self {
            case .displayP3: return .displayP3
            case .sRGB: return .sRGB
            case .sRGBLinear: return .sRGBLinear
            }
        }
    }
    
    public var colorFormulation: ColorFormulation
    public var rgbColorSpace: RGBColorSpace = .sRGB

    public var name: String = "New Color"
    public let id: UUID
    public let dateCreated: Date
    
    public var white: Double = 0.5
    
    public var red: Double = 0.5
    public var green: Double = 0.5
    public var blue: Double = 0.5
    
    public var hue: Double = 0.5
    public var saturation: Double = 0.5
    public var brightness: Double = 0.5
    
    public var cyan: Double = 0.5
    public var magenta: Double = 0.5
    public var yellow: Double = 0.5
    public var keyBlack: Double = 0.5
    
    public var alpha: Double = 1

    // MARK: - Computed Variables
    public var hex: String { self.color.description }
    
    public var color: Color {
        switch colorFormulation {
        case .rgb:
            return Color(self.rgbColorSpace.space, red: self.red, green: self.green, blue: self.blue, opacity: self.alpha)
        case .hsb:
            return Color(hue: self.hue, saturation: self.saturation, brightness: self.brightness, opacity: self.alpha)
        case .cmyk:
            return Color(PlatformColor(cmyk: (CGFloat(self.cyan), CGFloat(self.magenta), CGFloat(self.yellow), CGFloat(self.keyBlack)))).opacity(alpha)
        case .gray:
            return Color(self.rgbColorSpace.space, white: self.white).opacity(alpha)
        }
    }
    
    public var fileFormat: String {
        switch colorFormulation {
        case .rgb:
            return "Color(.\(self.rgbColorSpace.space), red: \(self.red), green: \(self.green), blue: \(self.blue), opacity: \(self.alpha))"
        case .hsb:
            return "Color(hue: \(self.hue), saturation: \(self.saturation), brightness: \(self.brightness), opacity: \(self.alpha))"
        case .cmyk:
            return "Color(PlatformColor(cmyk: (\(self.cyan), \(self.magenta), \(self.yellow), \(self.keyBlack)))).opacity(\(alpha))"
        case .gray:
            return "Color(.\(self.rgbColorSpace.space), white: \(self.white).opacity(\(alpha))"
        }
    }

    // MARK: - Initialization
    internal init(id: UUID,
                  date: Date,
                  name: String,
                  formulation: ColorFormulation,
                  rgbColorSpace: RGBColorSpace,
                  white: Double,
                  red: Double,
                  green: Double,
                  blue: Double,
                  hue: Double,
                  saturation: Double,
                  brightness: Double,
                  cyan: Double,
                  magenta: Double,
                  yellow: Double,
                  keyBlack: Double,
                  alpha: Double) {
        self.id = id
        self.dateCreated = date
        self.name = name
        self.colorFormulation = formulation
        self.rgbColorSpace = rgbColorSpace
        self.white = white
        self.red = red
        self.green = green
        self.blue = blue
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.cyan = cyan
        self.magenta = magenta
        self.yellow = yellow
        self.keyBlack = keyBlack
        self.alpha = alpha
        
    }

    // MARK: - Update ColorToken
    public mutating func update() {
        self.syncColorRepresentations()
    }
    
    public func updated() -> ColorToken {
        var updated = ColorToken(id: self.id,
                                 date: self.dateCreated,
                                 name: self.name,
                                 formulation: self.colorFormulation,
                                 rgbColorSpace: self.rgbColorSpace,
                                 white: self.white,
                                 red: self.red,
                                 green: self.green,
                                 blue: self.blue,
                                 hue: self.hue,
                                 saturation: self.saturation,
                                 brightness: self.brightness,
                                 cyan: self.cyan,
                                 magenta: self.magenta,
                                 yellow: self.yellow,
                                 keyBlack: self.keyBlack,
                                 alpha: self.alpha)
        updated.syncColorRepresentations()
        return updated
    }
    
    // MARK: - Sync Color Representations
    private mutating func syncColorRepresentations() {
        switch self.colorFormulation {
        case .rgb:
            syncFromRGB()
        case .hsb:
            syncFromHSB()
        case .cmyk:
            syncFromCMYK()
        case .gray:
            syncFromGray()
        }
    }
    
    private mutating func syncFromRGB() {
        let r = self.red
        let g = self.green
        let b = self.blue
        
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal
        
        var h: Double = 0
        var s: Double = 0
        let brightness = maxVal
        
        if delta != 0 {
            s = delta / maxVal
            
            if r == maxVal {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if g == maxVal {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            
            h /= 6
            if h < 0 {
                h += 1
            }
        }
        
        self.hue = h
        self.saturation = s
        self.brightness = brightness
        
        let k = 1 - maxVal
        var c: Double = 0
        var m: Double = 0
        var y: Double = 0
        
        if k < 1 {
            c = (1 - r - k) / (1 - k)
            m = (1 - g - k) / (1 - k)
            y = (1 - b - k) / (1 - k)
        }
        
        self.cyan = c
        self.magenta = m
        self.yellow = y
        self.keyBlack = k
        
        self.white = 0.299 * r + 0.587 * g + 0.114 * b
    }
    
    private mutating func syncFromHSB() {
        let h = self.hue
        let s = self.saturation
        let brightness = self.brightness
        
        let c = brightness * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        
        var r: Double = 0
        var g: Double = 0
        var b: Double = 0
        
        let hSegment = Int(h * 6)
        
        switch hSegment {
        case 0:
            r = c; g = x; b = 0
        case 1:
            r = x; g = c; b = 0
        case 2:
            r = 0; g = c; b = x
        case 3:
            r = 0; g = x; b = c
        case 4:
            r = x; g = 0; b = c
        default:
            r = c; g = 0; b = x
        }
        
        self.red = r + m
        self.green = g + m
        self.blue = b + m
        
        let maxVal = max(self.red, self.green, self.blue)
        let k = 1 - maxVal
        
        var cyan: Double = 0
        var magenta: Double = 0
        var yellow: Double = 0
        
        if k < 1 {
            cyan = (1 - self.red - k) / (1 - k)
            magenta = (1 - self.green - k) / (1 - k)
            yellow = (1 - self.blue - k) / (1 - k)
        }
        
        self.cyan = cyan
        self.magenta = magenta
        self.yellow = yellow
        self.keyBlack = k
        
        self.white = 0.299 * self.red + 0.587 * self.green + 0.114 * self.blue
    }
    
    private mutating func syncFromCMYK() {
        let c = self.cyan
        let m = self.magenta
        let y = self.yellow
        let k = self.keyBlack
        
        self.red = (1 - c) * (1 - k)
        self.green = (1 - m) * (1 - k)
        self.blue = (1 - y) * (1 - k)
        
        let maxVal = max(self.red, self.green, self.blue)
        let minVal = min(self.red, self.green, self.blue)
        let delta = maxVal - minVal
        
        var h: Double = 0
        var s: Double = 0
        let brightness = maxVal
        
        if delta != 0 {
            s = delta / maxVal
            
            if self.red == maxVal {
                h = ((self.green - self.blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if self.green == maxVal {
                h = (self.blue - self.red) / delta + 2
            } else {
                h = (self.red - self.green) / delta + 4
            }
            
            h /= 6
            if h < 0 {
                h += 1
            }
        }
        
        self.hue = h
        self.saturation = s
        self.brightness = brightness
        
        self.white = 0.299 * self.red + 0.587 * self.green + 0.114 * self.blue
    }
    
    private mutating func syncFromGray() {
        let w = self.white
        
        self.red = w
        self.green = w
        self.blue = w
        
        self.hue = 0
        self.saturation = 0
        self.brightness = w
        
        self.cyan = 0
        self.magenta = 0
        self.yellow = 0
        self.keyBlack = 1 - w
    }
    // MARK: - Update from Hex
    @available(iOS 14.0, *)
    public mutating func update(hex: String)  -> ColorToken {
        guard let color = Color(hex: hex) else {
            return self
        }
        switch self.colorFormulation {
        case .rgb:
            let platformColor = PlatformColor(color)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getRed(&r, green: &g, blue: &b, alpha: &o)
            #else
            guard platformColor.getRed(&r, green: &g, blue: &b, alpha: &o) else {
                print("Update from Color Failed to extract RGB color components")
                return self
            }
            #endif

            self.red = Double(r)
            self.green = Double(g)
            self.blue = Double(b)
            self.alpha = Double(o)
            return self.updated()
        case .hsb:
            let platformColor = PlatformColor(color)
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getHue(&h, saturation: &s, brightness: &b, alpha: &o)
            #else
            guard platformColor.getHue(&h, saturation: &s, brightness: &b, alpha: &o) else {
                print("Update from Color Failed to extract HSB color components")
                return self
            }
            #endif

            self.hue = Double(h)
            self.saturation = Double(s)
            self.brightness = Double(b)
            self.alpha = Double(o)
            return self.updated()
        case .cmyk:
            let platformColor = PlatformColor(color)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getRed(&r, green: &g, blue: &b, alpha: &o)
            #else
            guard platformColor.getRed(&r, green: &g, blue: &b, alpha: &o) else {
                print("Update from Color Failed to extract RGB color components")
                return self
            }
            #endif

            let k = 1 - max(r, g, b)

            var c: CGFloat = 0
            var m: CGFloat = 0
            var y: CGFloat = 0

            if k < 1 {
                c = (1 - r - k) / (1 - k)
                m = (1 - g - k) / (1 - k)
                y = (1 - b - k) / (1 - k)
            }

            self.cyan = Double(c)
            self.magenta = Double(m)
            self.yellow = Double(y)
            self.keyBlack = Double(k)
            self.alpha = Double(o)
            return self.updated()
        case .gray:
            // convert color to grayscale
            let platformColor = PlatformColor(color)
            var w: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getWhite(&w, alpha: &o)
            #else
            guard platformColor.getWhite(&w, alpha: &o) else {
                print("Update from Color Failed to extract Gray color components")
                return self
            }
            #endif

            self.white = Double(w)
            self.alpha = Double(o)
            return self.updated()
        }
    }
    // MARK: - Update from Color
    @available(iOS 14.0, *)
    public mutating func update(color: Color) -> ColorToken {
        switch self.colorFormulation {
        case .rgb:
            let platformColor = PlatformColor(color)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getRed(&r, green: &g, blue: &b, alpha: &o)
            #else
            guard platformColor.getRed(&r, green: &g, blue: &b, alpha: &o) else {
                print("Update from Color Failed to extract RGB color components")
                return self
            }
            #endif

            self.red = Double(r)
            self.green = Double(g)
            self.blue = Double(b)
            self.alpha = Double(o)
            return self.updated()
        case .hsb:
            let platformColor = PlatformColor(color)
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getHue(&h, saturation: &s, brightness: &b, alpha: &o)
            #else
            guard platformColor.getHue(&h, saturation: &s, brightness: &b, alpha: &o) else {
                print("Update from Color Failed to extract HSB color components")
                return self
            }
            #endif

            self.hue = Double(h)
            self.saturation = Double(s)
            self.brightness = Double(b)
            self.alpha = Double(o)
            return self.updated()
        case .cmyk:
            let platformColor = PlatformColor(color)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getRed(&r, green: &g, blue: &b, alpha: &o)
            #else
            guard platformColor.getRed(&r, green: &g, blue: &b, alpha: &o) else {
                print("Update from Color Failed to extract RGB color components")
                return self
            }
            #endif

            let k = 1 - max(r, g, b)

            var c: CGFloat = 0
            var m: CGFloat = 0
            var y: CGFloat = 0

            if k < 1 {
                c = (1 - r - k) / (1 - k)
                m = (1 - g - k) / (1 - k)
                y = (1 - b - k) / (1 - k)
            }

            self.cyan = Double(c)
            self.magenta = Double(m)
            self.yellow = Double(y)
            self.keyBlack = Double(k)
            self.alpha = Double(o)
            return self.updated()
        case .gray:
            let platformColor = PlatformColor(color)
            var w: CGFloat = 0
            var o: CGFloat = 0

            #if os(macOS)
            platformColor.getWhite(&w, alpha: &o)
            #else
            guard platformColor.getWhite(&w, alpha: &o) else {
                print("Update from Color Failed to extract Gray color components")
                return self
            }
            #endif

            self.white = Double(w)
            self.alpha = Double(o)
            return self.updated()
        }
    }
    // MARK: - Update from Components
    public mutating func update(white: Double) -> ColorToken {
        self.white = white
        self.colorFormulation = .gray
        return self.updated()
    }
    public mutating func update(red: Double) -> ColorToken {
        self.red = red
        self.colorFormulation = .rgb
        return self.updated()
    }
    public mutating func update(green: Double) -> ColorToken {
        self.green = green
        self.colorFormulation = .rgb
        return self.updated()
    }
    public mutating func update(blue: Double) -> ColorToken {
        self.blue = blue
        self.colorFormulation = .rgb
        return self.updated()
    }
    public mutating func update(hue: Double) -> ColorToken {
        self.hue = hue
        self.colorFormulation = .hsb
        return self.updated()
    }
    public mutating func update(saturation: Double) -> ColorToken {
        self.saturation = saturation
        self.colorFormulation = .hsb
        return self.updated()
    }
    public mutating func update(brightness: Double) -> ColorToken {
        self.brightness = brightness
        self.colorFormulation = .hsb
        return self.updated()
    }
    public mutating func update(cyan: Double) -> ColorToken {
        self.cyan = cyan
        self.colorFormulation = .cmyk
        return self.updated()
    }
    public mutating func update(magenta: Double) -> ColorToken {
        self.magenta = magenta
        self.colorFormulation = .cmyk
        return self.updated()
    }
    public mutating func update(yellow: Double) -> ColorToken {
        self.yellow = yellow
        self.colorFormulation = .cmyk
        return self.updated()
    }
    public mutating func update(keyBlack: Double) -> ColorToken {
        self.keyBlack = keyBlack
        self.colorFormulation = .cmyk
        return self.updated()
    }
    public mutating func update(alpha: Double) -> ColorToken {
        self.alpha = alpha
        return self.updated()
    }
    
    // MARK: RGB Inits
    public init(r: Double, g: Double, b: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.colorFormulation = .rgb
        self.update()
    }
    public init(name: String, r: Double, g: Double, b: Double) {
        self.name = name
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.colorFormulation = .rgb
        self.update()
    }
    public init(colorSpace: RGBColorSpace, r: Double, g: Double, b: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.colorFormulation = .rgb
        self.rgbColorSpace = colorSpace
        self.update()
    }
    public init(name: String, colorSpace: RGBColorSpace, r: Double, g: Double, b: Double) {
        self.name = name
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.colorFormulation = .rgb
        self.rgbColorSpace = colorSpace
        self.update()
    }
    public init(r: Double, g: Double, b: Double, a: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
        self.colorFormulation = .rgb
        self.update()
    }
    public init(name: String, r: Double, g: Double, b: Double, a: Double) {
        self.name = name
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
        self.colorFormulation = .rgb
        self.update()
    }
    public init(colorSpace: RGBColorSpace, r: Double, g: Double, b: Double, a: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
        self.colorFormulation = .rgb
        self.rgbColorSpace = colorSpace
        self.update()
    }
    public init(name: String, colorSpace: RGBColorSpace, r: Double, g: Double, b: Double, a: Double) {
        self.name = name
        self.id = .init()
        self.dateCreated = .init()
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
        self.colorFormulation = .rgb
        self.rgbColorSpace = colorSpace
        self.update()
    }
    // MARK: HSB Inits
    public init(hue: Double, saturation: Double, brightness: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.colorFormulation = .hsb
        self.update()
    }
    public init(name: String, hue: Double, saturation: Double, brightness: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.name = name
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.colorFormulation = .hsb
        self.update()
    }
    public init(hue: Double, saturation: Double, brightness: Double, opacity: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = opacity
        self.colorFormulation = .hsb
        self.update()
    }
    public init(name: String, hue: Double, saturation: Double, brightness: Double, opacity: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.name = name
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = opacity
        self.colorFormulation = .hsb
        self.update()
    }
    // MARK: CMYK Inits
    public init(cyan: Double, magenta: Double, yellow: Double, keyBlack: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.cyan = cyan
        self.magenta = magenta
        self.yellow = yellow
        self.keyBlack = keyBlack
        self.colorFormulation = .cmyk
        self.update()
    }
    public init(name: String, cyan: Double, magenta: Double, yellow: Double, keyBlack: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.name = name
        self.cyan = cyan
        self.magenta = magenta
        self.yellow = yellow
        self.keyBlack = keyBlack
        self.colorFormulation = .cmyk
        self.update()
    }
    // MARK: White Inits
    public init(white: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.white = white
        self.colorFormulation = .gray
        self.update()
    }
    public init(name: String, white: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.name = name
        self.white = white
        self.colorFormulation = .gray
        self.update()
    }
    public init(colorSpace: RGBColorSpace, white: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.white = white
        self.colorFormulation = .gray
        self.rgbColorSpace = colorSpace
        self.update()
    }
    public init(white: Double, opacity: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.white = white
        self.alpha = opacity
        self.colorFormulation = .gray
        self.update()
    }
    public init(colorSpace: RGBColorSpace, white: Double, opacity: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.white = white
        self.alpha = opacity
        self.colorFormulation = .gray
        self.rgbColorSpace = colorSpace
        self.update()
    }
    public init(name: String, white: Double, opacity: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.name = name
        self.white = white
        self.alpha = opacity
        self.colorFormulation = .gray
        self.update()
    }
    public init(name: String, colorSpace: RGBColorSpace, white: Double, opacity: Double) {
        self.id = .init()
        self.dateCreated = .init()
        self.name = name
        self.white = white
        self.alpha = opacity
        self.colorFormulation = .gray
        self.rgbColorSpace = colorSpace
        self.update()
    }
    public init(_ token: ColorToken) {
        self.id = .init()
        self.dateCreated = .init()
        self.name = token.name
        self.alpha = token.alpha
        self.white = token.white
        self.rgbColorSpace = token.rgbColorSpace
        self.colorFormulation = token.colorFormulation
        self.red = token.red
        self.green = token.green
        self.blue = token.blue
        self.hue = token.hue
        self.saturation = token.saturation
        self.brightness = token.brightness
        self.cyan = token.cyan
        self.magenta = token.magenta
        self.yellow = token.yellow
        self.keyBlack = token.keyBlack
    }
}

@available(iOS 13.0, macOS 11.0, *)
public extension ColorToken {
    
    // MARK: - Color Scheme
    enum ColorSchemes: String, CaseIterable {
        case analagous
        case monochromatic
        case triadic
        case complementary
    }
    
    func colorSchemes(_ type: ColorSchemes) -> [ColorToken] {
        switch (type) {
        case .analagous:
            return analgousColors()
        case .monochromatic:
            return monochromaticColors()
        case .triadic:
            return triadColors()
        case .complementary:
            return complementaryColors()
        }
    }

    // MARK: - Color Conversions
    func analgousColors() -> [ColorToken] {
        return [ColorToken(hue: (hue*360+30)/360, saturation: saturation-0.05, brightness: brightness-0.1, opacity: alpha),
                ColorToken(hue: (hue*360+15)/360, saturation: saturation-0.05, brightness: brightness-0.05, opacity: alpha),
                ColorToken(hue: (hue*360-15)/360, saturation: saturation-0.05, brightness: brightness-0.05, opacity: alpha),
                ColorToken(hue: (hue*360-30)/360, saturation: saturation-0.05, brightness: brightness-0.1, opacity: alpha)]
    }
    
    func monochromaticColors() -> [ColorToken] {
        return [ColorToken(hue: hue, saturation: saturation/2, brightness: brightness/3, opacity: alpha),
                ColorToken(hue: hue, saturation: saturation, brightness: brightness/2, opacity: alpha),
                ColorToken(hue: hue, saturation: saturation/3, brightness: 2*brightness/3, opacity: alpha),
                ColorToken(hue: hue, saturation: saturation, brightness: 4*brightness/5, opacity: alpha)]
        
    }
    
    func triadColors() -> [ColorToken] {
        return [ColorToken(hue: (120+hue*360)/360, saturation: 2*saturation/3, brightness: brightness-0.05, opacity: alpha),
                ColorToken(hue: (120+hue*360)/360, saturation: saturation, brightness: brightness, opacity: alpha),
                ColorToken(hue: (240+hue*360)/360, saturation: saturation, brightness: brightness, opacity: alpha),
                ColorToken(hue: (240+hue*360)/360, saturation: 2*saturation/3, brightness: brightness-0.05, opacity: alpha)]
        
    }
    
    func complementaryColors() -> [ColorToken] {
        return  [ColorToken(hue: hue, saturation: saturation, brightness: 4*brightness/5, opacity: alpha),
                 ColorToken(hue: hue, saturation: 5*saturation/7, brightness: brightness, opacity: alpha),
                 ColorToken(hue: (180+hue*360)/360, saturation: saturation, brightness: brightness, opacity: alpha),
                 ColorToken(hue: (180+hue*360)/360, saturation: 5*saturation/7, brightness: brightness, opacity: alpha)]
    }
}