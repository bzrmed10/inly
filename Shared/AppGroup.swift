import Foundation

/// Identifiers shared by the app, the widget extension and the Live Activity.
enum AppGroup {
    static let identifier = "group.com.bzrmed.inly"

    /// Container directory shared between the app and its extensions.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
