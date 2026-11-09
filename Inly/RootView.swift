import SwiftUI

/// System TabView: on iOS 26 this gets the Liquid Glass tab bar for free.
struct RootView: View {
    enum AppTab: Hashable { case today, trays, history, settings }

    @State private var setupDone = WearSettings.load().onboardingDone
    @State private var selection: AppTab = .today
    @AppStorage(L10n.storageKey, store: UserDefaults(suiteName: AppGroup.identifier)) private var languageRaw = AppLanguage.system.rawValue

    @AppStorage(AppAppearance.storageKey, store: UserDefaults(suiteName: AppGroup.identifier)) private var appearanceRaw = AppAppearance.dark.rawValue

    var body: some View {
        Group {
            if setupDone {
                TabView(selection: $selection) {
                    Tab(L10n.t("Today"), systemImage: "circle.dashed", value: AppTab.today) {
                        TodayView(onOpenTrays: { selection = .trays })
                    }
                    Tab(L10n.t("Trays"), systemImage: "square.stack.3d.up.fill", value: AppTab.trays) { TraysView() }
                    Tab(L10n.t("History"), systemImage: "chart.bar.fill", value: AppTab.history) { HistoryView() }
                    // role .search makes iOS 26 draw this as the detached glass circle next to the tab bar.
                    Tab(L10n.t("Settings"), systemImage: "gearshape.fill", value: AppTab.settings, role: .search) {
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
        .id(languageRaw)
        .appLanguage()
        .preferredColorScheme((AppAppearance(rawValue: appearanceRaw) ?? .dark).scheme)
    }
}
