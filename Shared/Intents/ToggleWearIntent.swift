import AppIntents

/// Take the aligners out or put them back in with one tap (widget button, Action Button, Shortcuts).
/// Conforms to LiveActivityIntent so it runs in the app process and can start the Dynamic Island.
struct ToggleWearIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Take out / Put back in" }
    static var description: IntentDescription {
        IntentDescription("Switch between aligners in and aligners out.")
    }

    func perform() async throws -> some IntentResult {
        await SessionService.shared.toggle()
        await SessionService.shared.waitForLiveActivity()
        return .result()
    }
}

/// Backs the Control Center toggle (on = aligners out).
struct SetOutIntent: SetValueIntent, LiveActivityIntent {
    static var title: LocalizedStringResource { "Aligners out" }

    @Parameter(title: "Out")
    var value: Bool

    func perform() async throws -> some IntentResult {
        if value {
            await SessionService.shared.takeOut()
        } else {
            await SessionService.shared.putBackIn()
        }
        await SessionService.shared.waitForLiveActivity()
        return .result()
    }
}
