import SwiftUI

/// Light / dark choice for the iPhone app. Widgets, Live Activity and the watch stay dark.
enum AppAppearance: String, CaseIterable {
    case dark, light, system
    static let storageKey = "appearance"

    var scheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
    var title: String {
        switch self {
        case .dark: L10n.t("Dark")
        case .light: L10n.t("Light")
        case .system: L10n.t("System")
        }
    }
}
