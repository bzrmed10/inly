import AppIntents

/// Makes the toggle available in Shortcuts and as an Action Button action.
struct InlyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleWearIntent(),
            phrases: ["Toggle aligners in \(.applicationName)", "Aligners out in \(.applicationName)"],
            shortTitle: "Aligners in / out",
            systemImageName: "circle.dashed"
        )
    }
}
