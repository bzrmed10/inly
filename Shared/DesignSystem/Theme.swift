import SwiftUI
#if ADAPTIVE_THEME
import UIKit
#endif

extension Color {
    /// Create a color from a 24-bit hex value, e.g. `Color(hex: 0x0B0B0F)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    #if ADAPTIVE_THEME
    /// A color that follows the app's light / dark appearance (only the iPhone app is built with this).
    static func adaptive(light: UInt32, dark: UInt32, darkOpacity: Double = 1) -> Color {
        func ui(_ hex: UInt32, _ alpha: Double = 1) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
        }
        return Color(UIColor { $0.userInterfaceStyle == .light ? ui(light) : ui(dark, darkOpacity) })
    }
    #else
    /// Widgets and the watch stay dark: this just returns the dark value.
    static func adaptive(light: UInt32, dark: UInt32, darkOpacity: Double = 1) -> Color {
        Color(hex: dark, opacity: darkOpacity)
    }
    #endif
}

/// Inly design tokens. See docs in SPEC.md ("Design system").
enum Theme {
    static let night = Color.adaptive(light: 0xEFEFF4, dark: 0x0B0B0F)
    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x17171C)
    static let raised = Color.adaptive(light: 0xE7E7EF, dark: 0x23232B)
    static let text = Color.adaptive(light: 0x0F0F14, dark: 0xFFFFFF)
    static let muted = Color.adaptive(light: 0x6B6B78, dark: 0x9A9AA6)
    /// Descriptions and secondary lines.
    static let secondary = Color.adaptive(light: 0x4A4A55, dark: 0xC9C9D2)
    /// Empty tracks, unselected pills.
    static let track = Color.adaptive(light: 0xDEDEE7, dark: 0x2A2A33)
    /// Round control backgrounds and thin strips.
    static let hairline = Color.adaptive(light: 0xD5D5DF, dark: 0x33333D)
    /// Sheet background.
    static let sheet = Color.adaptive(light: 0xFFFFFF, dark: 0x1C1C22)
    /// Text or icon on a colored fill.
    static let onAccent = Color.adaptive(light: 0xFFFFFF, dark: 0x0B0B0F)

    /// Aligners in.
    static let inColor = Color.adaptive(light: 0x1A68DB, dark: 0x5B9DFF)
    /// Aligners out. For small text use `outText` on `outSoft`.
    static let outColor = Color.adaptive(light: 0xE0620D, dark: 0xFFB547)
    static let outText = Color.adaptive(light: 0x9A3F00, dark: 0xFFB547)
    static let outSoft = Color.adaptive(light: 0xFFEBDD, dark: 0xFFB547, darkOpacity: 0.16)
    /// Tray / success.
    static let trayColor = Color.adaptive(light: 0x0B7C55, dark: 0x3DDC97)
    /// Over the daily out-time budget.
    static let overColor = Color.adaptive(light: 0xCC372B, dark: 0xFF6B5E)

    /// Done-tray color per treatment phase: initial = green, then purple, teal, blue (repeats).
    static func phaseColor(_ phase: Int) -> Color {
        let palette = [trayColor, Color.adaptive(light: 0x7A4FE0, dark: 0xB28DFF), Color.adaptive(light: 0x087A89, dark: 0x4FD1D9), inColor]
        return palette[max(0, phase) % palette.count]
    }
    static let retainerColor = Color.adaptive(light: 0xC2366B, dark: 0xFF8FB1)

    static let cardRadius: CGFloat = 24
    static let pillRadius: CGFloat = 28

    /// Rounded system font, heavy weights for numbers.
    /// Sizes up to 20pt map to text styles so they follow the user's Dynamic Type setting.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        let style: Font.TextStyle? = switch size {
        case ..<13: .caption
        case ..<14: .footnote
        case ..<16: .subheadline
        case ..<18: .body
        case ..<21: .title3
        default: nil
        }
        if let style { return .system(style, design: .rounded, weight: weight) }
        return .system(size: size, weight: weight, design: .rounded)
    }

    /// Big timers: rounded, heavy, tabular so digits do not jitter.
    static func timerFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }
}
