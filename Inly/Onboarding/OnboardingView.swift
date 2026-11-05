import SwiftUI

/// First launch: who you are and which tray you are on, so counting starts from the right place.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var name = ""
    @State private var currentTray = 1
    @State private var totalTrays = 24
    @State private var plannedDays = 14
    @State private var dayOnTray = 1
    @State private var goalHours = 22
    @FocusState private var nameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WELCOME TO INLY")
                        .font(Theme.font(12, .heavy)).tracking(1.4).foregroundStyle(Theme.inColor)
                    Text("Let's set up your treatment")
                        .font(Theme.font(32, .heavy))
                    Text("So we start counting from the right tray and the right day.")
                        .font(Theme.font(16, .medium)).foregroundStyle(Theme.muted)
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    label("What should we call you?")
                    TextField("Your first name", text: $name)
                        .font(Theme.font(18, .semibold))
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .focused($nameFocused)
                        .padding(16)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    label("Your trays")
                    StepperRow(title: "Tray you are on now", valueText: "Tray \(currentTray)", value: $currentTray, range: 1...80)
                    StepperRow(title: "Trays in your treatment", valueText: "\(max(totalTrays, currentTray)) trays", value: $totalTrays, range: 1...80)
                    StepperRow(title: "Days planned for this tray", valueText: "\(plannedDays) days", value: $plannedDays, range: 1...30)
                    StepperRow(title: "Which day of this tray is it today?", valueText: "Day \(dayOnTray)", value: $dayOnTray, range: 1...60)
                    Text(summary)
                        .font(Theme.font(14, .semibold)).foregroundStyle(Theme.muted)
                        .padding(.horizontal, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    label("Daily goal")
                    StepperRow(title: "Wear your aligners", valueText: "\(goalHours) hours a day", value: $goalHours, range: 16...23)
                }

                Button("Start tracking") {
                    TrayNotifications.requestPermission()
                    SessionService.shared.completeSetup(
                        name: name, currentTray: currentTray, totalTrays: totalTrays,
                        plannedDays: plannedDays, dayOnTray: dayOnTray, goalHours: goalHours
                    )
                    onFinish()
                }
                .buttonStyle(PillButtonStyle(color: Theme.inColor))
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.night.ignoresSafeArea())
        .onChange(of: currentTray) { _, new in totalTrays = max(totalTrays, new) }
    }

    private var summary: String {
        let left = plannedDays - dayOnTray
        if left > 0 { return "Switch to tray \(currentTray + 1) in \(left) day\(left == 1 ? "" : "s")." }
        if left == 0 { return "You are due to switch to tray \(currentTray + 1) today." }
        let over = -left
        return "That is \(over) day\(over == 1 ? "" : "s") over the plan, shown as +\(over) until you start tray \(currentTray + 1)."
    }

    private func label(_ text: String) -> some View {
        Text(text).font(Theme.font(17, .heavy))
    }
}
