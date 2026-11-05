import SwiftUI

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
}

/// Inly design tokens. See docs in SPEC.md ("Design system").
enum Theme {
    static let night = Color(hex: 0x0B0B0F)
    static let surface = Color(hex: 0x17171C)
    static let raised = Color(hex: 0x23232B)
    static let text = Color.white
    static let muted = Color(hex: 0x9A9AA6)

    /// Aligners in.
    static let inColor = Color(hex: 0x5B9DFF)
    /// Aligners out.
    static let outColor = Color(hex: 0xFFB547)
    /// Tray / success.
    static let trayColor = Color(hex: 0x3DDC97)
    /// Over the daily out-time budget.
    static let overColor = Color(hex: 0xFF6B5E)

    static let cardRadius: CGFloat = 24
    static let pillRadius: CGFloat = 28

    /// Rounded system font, heavy weights for numbers.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Big timers: rounded, heavy, tabular so digits do not jitter.
    static func timerFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }
}
