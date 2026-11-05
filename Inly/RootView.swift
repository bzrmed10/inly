import SwiftUI

/// System TabView: on iOS 26 this gets the Liquid Glass tab bar for free.
struct RootView: View {
    @State private var setupDone = WearSettings.load().onboardingDone

    var body: some View {
        Group {
            if setupDone {
                TabView {
                    Tab("Today", systemImage: "circle.dashed") { TodayView() }
                    Tab("Trays", systemImage: "square.stack.3d.up.fill") { TraysView() }
                    Tab("History", systemImage: "chart.bar.fill") { HistoryView() }
                    // role .search makes iOS 26 draw this as the detached glass circle next to the tab bar.
                    Tab("Settings", systemImage: "person.fill", role: .search) {
                        SettingsView { withAnimation(.smooth) { setupDone = false } }
                    }
                }
                .tint(Theme.inColor)
                .transition(.opacity)
            } else {
                OnboardingView { withAnimation(.smooth) { setupDone = true } }
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}
