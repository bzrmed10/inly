import SwiftData
import SwiftUI
import UserNotifications

@main
struct InlyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        SessionService.shared.ensureTray()
        OutReminders.registerCategory()
        PhoneConnectivity.shared.start()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
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
