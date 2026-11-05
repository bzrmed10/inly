import SwiftData
import SwiftUI

@main
struct InlyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        SessionService.shared.ensureTray()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(SessionService.shared.container)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { SessionService.shared.reconcileLiveActivity() }
                }
        }
    }
}
