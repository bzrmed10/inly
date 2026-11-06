import SwiftUI

@main
struct InlyWatchApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(model: model)
        }
    }
}
