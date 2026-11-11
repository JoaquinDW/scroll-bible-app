import SwiftUI

/// Single source of truth for the product's identity.
/// Rename the app, retint it, or swap its typefaces here and nowhere else.
/// (User-facing copy lives in `Copy.swift`, which reads `Brand.name`.)
enum Brand {
    static let name = "Lumen"
    static let urlScheme = "lumen"
    static let supportEmail = "hello@example.com"

    enum Palette {
        // Paper and surfaces (never pure white)
        static let ivory = Color(hex: 0xFBF6EA)
        static let cream = Color(hex: 0xF6EBD3)
        static let paper = Color(hex: 0xFFF9EC)
        // Meadow
        static let sage = Color(hex: 0xB7CDAA)
        static let grass = Color(hex: 0x97B884)
        static let deepGrass = Color(hex: 0x6F9A6C)
        // Water and sky
        static let aqua = Color(hex: 0xC6E4DF)
        static let teal = Color(hex: 0x7FB3AE)
        static let peach = Color(hex: 0xF8D3B8)
        static let blush = Color(hex: 0xF3C9CB)
        // Light
        static let gold = Color(hex: 0xE5B95C)
        static let goldSoft = Color(hex: 0xF5DD9C)
        // Ink (never pure black)
        static let petrol = Color(hex: 0x23464F)
        static let petrolSoft = Color(hex: 0x52727A)
        static let brown = Color(hex: 0x4A3A2C)
        // Dusk and night
        static let dusk = Color(hex: 0x6C7AA0)
        static let night = Color(hex: 0x2F3C5E)
        // Sheep
        static let wool = Color(hex: 0xFBF3E0)
        static let woolShade = Color(hex: 0xE9D9B9)
        static let face = Color(hex: 0xF4E4C8)
        static let earPink = Color(hex: 0xEDB1AB)
        static let nose = Color(hex: 0x5A4638)
        // Feedback (soft, never alarming)
        static let correct = Color(hex: 0x7FAE84)
        static let gentle = Color(hex: 0xD9A08C)
    }

    enum Fonts {
        /// Scripture. Warm serif, scales with Dynamic Type.
        static let verse = Font.system(.title2, design: .serif).weight(.medium)
        static let verseLarge = Font.system(.title, design: .serif).weight(.medium)
        static let reference = Font.system(.subheadline, design: .serif).weight(.semibold)
        static let display = Font.system(.largeTitle, design: .serif).weight(.semibold)
        static let title = Font.system(.title2, design: .serif).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let callout = Font.system(.callout, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded).weight(.medium)
        static let button = Font.system(.headline, design: .rounded).weight(.semibold)
        static let number = Font.system(.title, design: .rounded).weight(.bold)
    }

    enum Metrics {
        static let corner: CGFloat = 24
        static let cardCorner: CGFloat = 20
        static let padding: CGFloat = 20
        static let shadowRadius: CGFloat = 14
    }

    /// Placeholder prices. Replace with StoreKit products.
    enum Pricing {
        static let annual = "$29.99"
        static let weekly = "$2.99"
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
