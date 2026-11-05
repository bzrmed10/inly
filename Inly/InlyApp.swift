import SwiftData
import SwiftUI

@main
struct InlyApp: App {
    init() {
        SessionService.shared.ensureTray()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(SessionService.shared.container)
        }
    }
}
