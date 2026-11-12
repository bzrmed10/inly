import Foundation

/// Whether Inly+ is unlocked, as a flag every target can read (app, widgets, watch, complications).
/// The iPhone app is the source of truth (StoreKit); it writes this flag and sends it to the watch.
enum PlusStatus {
    static let key = "inlyPlusActive"
    private static var defaults: UserDefaults { UserDefaults(suiteName: AppGroup.identifier) ?? .standard }

    static var isActive: Bool {
        if ProcessInfo.processInfo.arguments.contains("-demoData") { return true }
        return defaults.bool(forKey: key)
    }

    static func set(_ active: Bool) {
        defaults.set(active, forKey: key)
    }
}
