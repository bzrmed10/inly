import Foundation
import SwiftUI

/// Languages the app can show. `system` follows the phone and falls back to English.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system, en, fr, ar, es
    var id: String { rawValue }

    /// Each language is always written in itself so people can find theirs.
    var nativeName: String {
        switch self {
        case .system: L10n.t("Phone language")
        case .en: "English"
        case .fr: "Français"
        case .ar: "العربية"
        case .es: "Español"
        }
    }
}

/// Everything about the app's language: which one is active, text lookup, plurals and formatting.
/// The choice lives in the App Group, so the app, widgets and Live Activity agree. The watch stores the
/// code the iPhone sends it in its own storage.
enum L10n {
    static let storageKey = "appLanguage"
    static let supported = ["en", "fr", "ar", "es"]

    private static var group: UserDefaults { UserDefaults(suiteName: AppGroup.identifier) ?? .standard }

    /// The chosen language (a launch argument `-appLanguage fr` wins, which UI tests use).
    static var selected: AppLanguage {
        if let arg = UserDefaults.standard.string(forKey: storageKey), let l = AppLanguage(rawValue: arg) { return l }
        if let raw = group.string(forKey: storageKey), let l = AppLanguage(rawValue: raw) { return l }
        return .system
    }

    static func select(_ language: AppLanguage) {
        group.set(language.rawValue, forKey: storageKey)
    }

    /// The first phone language we have a translation for, else English.
    static var systemCode: String {
        for preferred in Locale.preferredLanguages {
            let base = String(preferred.prefix(2))
            if supported.contains(base) { return base }
        }
        return "en"
    }

    /// The language actually in use: en, fr, ar or es.
    static var code: String {
        let s = selected
        return s == .system ? systemCode : s.rawValue
    }

    static var isRTL: Bool { code == "ar" }
    static var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }

    /// Arabic keeps Western digits so numbers look the same everywhere in the app.
    static var locale: Locale {
        code == "ar" ? Locale(identifier: "ar-u-nu-latn") : Locale(identifier: code)
    }

    // MARK: Text

    static func t(_ key: String, language: String? = nil) -> String {
        let code = language ?? self.code
        if code == "en" { return Strings.table[key]?.en.nonEmpty ?? key }
        return Strings.table[key]?.value(for: code) ?? Strings.table[key]?.en.nonEmpty ?? key
    }

    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), locale: locale, arguments: args)
    }

    // MARK: Plurals

    private static func category(_ n: Int, code: String) -> String {
        switch code {
        case "ar":
            switch n {
            case 1: return "one"
            case 2: return "two"
            case 3...10: return "few"
            case 11...99: return "many"
            default: return "other"
            }
        case "fr": return n <= 1 && n >= 0 ? "one" : "other"
        default: return n == 1 ? "one" : "other"
        }
    }

    /// "1 day" / "3 days" in the active language. `unit` is one of day, tray, break, minute.
    static func count(_ unit: String, _ n: Int) -> String {
        let cat = category(abs(n), code: code)
        let entry = Strings.table["\(unit)#\(cat)"] ?? Strings.table["\(unit)#other"]
        let value = entry?.value(for: code).nonEmpty ?? Strings.table["\(unit)#other"]?.value(for: code).nonEmpty ?? ""
        let format = value.isEmpty ? "%d" : value
        return String(format: format, locale: locale, n)
    }

    static func days(_ n: Int) -> String { count("day", n) }
    static func trays(_ n: Int) -> String { count("tray", n) }
    static func breaks(_ n: Int) -> String { count("break", n) }
    static func minutes(_ n: Int) -> String { count("minute", n) }

    // MARK: Dates

    static func date(_ date: Date, _ style: Date.FormatStyle) -> String {
        date.formatted(style.locale(locale))
    }

    static func time(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }

    static func dateTime(_ date: Date, date dateStyle: Date.FormatStyle.DateStyle = .abbreviated) -> String {
        date.formatted(Date.FormatStyle(date: dateStyle, time: .shortened).locale(locale))
    }

    static func shortDate(_ date: Date, year: Bool = false) -> String {
        year
            ? date.formatted(Date.FormatStyle().month(.abbreviated).day().year().locale(locale))
            : date.formatted(Date.FormatStyle().month(.abbreviated).day().locale(locale))
    }

    // MARK: Hours and minutes

    /// "21h 40m" in English, "21 h 40 min" in French, "21س 40د" in Arabic.
    static func hoursMinutes(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let hu = t("unit.h"), mu = t("unit.m")
        if h > 0 { return "\(h)\(hu) \(String(format: "%02d", m))\(mu)" }
        return "\(m)\(mu)"
    }
}

extension String {
    fileprivate var nonEmpty: String? { isEmpty ? nil : self }
}

/// One translated entry. English is the lookup key unless `en` is given (needed for plural forms).
struct Entry: Sendable, Decodable {
    var en = ""
    var fr = ""
    var ar = ""
    var es = ""

    private enum CodingKeys: String, CodingKey { case en, fr, ar, es }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        en = try c.decodeIfPresent(String.self, forKey: .en) ?? ""
        fr = try c.decodeIfPresent(String.self, forKey: .fr) ?? ""
        ar = try c.decodeIfPresent(String.self, forKey: .ar) ?? ""
        es = try c.decodeIfPresent(String.self, forKey: .es) ?? ""
    }

    func value(for code: String) -> String {
        switch code {
        case "fr": fr
        case "ar": ar
        case "es": es
        default: en
        }
    }
}

extension View {
    /// Puts the chosen language and reading direction on a whole view tree.
    func appLanguage() -> some View {
        environment(\.locale, L10n.locale)
            .environment(\.layoutDirection, L10n.layoutDirection)
    }
}
