import AppIntents

/// Runs from the Live Activity / Dynamic Island button.
struct PutBackInIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Put back in" }
    static var description: IntentDescription { IntentDescription("Record that your aligners are back in.") }

    func perform() async throws -> some IntentResult {
        await SessionService.shared.putBackIn()
        await SessionService.shared.waitForLiveActivity()
        return .result()
    }
}
