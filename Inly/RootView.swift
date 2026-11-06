import SwiftUI

/// System TabView: on iOS 26 this gets the Liquid Glass tab bar for free.
struct RootView: View {
    enum AppTab: Hashable { case today, trays, history, settings }

    @State private var setupDone = WearSettings.load().onboardingDone
    @State private var selection: AppTab = .today

    var body: some View {
        Group {
            if setupDone {
                TabView(selection: $selection) {
                    Tab("Today", systemImage: "circle.dashed", value: AppTab.today) {
                        TodayView(onOpenTrays: { selection = .trays })
                    }
                    Tab("Trays", systemImage: "square.stack.3d.up.fill", value: AppTab.trays) { TraysView() }
                    Tab("History", systemImage: "chart.bar.fill", value: AppTab.history) { HistoryView() }
                    // role .search makes iOS 26 draw this as the detached glass circle next to the tab bar.
                    Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings, role: .search) {
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
