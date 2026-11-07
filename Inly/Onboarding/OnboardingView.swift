import SwiftUI

/// First launch: a short, animated tour (Dynamic Island, widgets), then who you are, your tray, your goal and reminders.
struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Step: Int, CaseIterable { case welcome, island, widgets, name, tray, goal, reminders, done }

    @State private var step: Step = .welcome
    @State private var name = ""
    @State private var currentTray = 1
    @State private var totalTrays = 24
    @State private var plannedDays = 14
    @State private var trayStart = Date.now
    @State private var goalHours = 22
    @State private var alignersIn = true
    @State private var remindersOn = true
    @State private var stillOut = WearSettings.defaultStillOut
    @FocusState private var nameFocused: Bool

    private var animate: Bool { !reduceMotion }
    private var dayOnTray: Int { TrayLogic.dayNumber(start: trayStart, now: .now, calendar: .current) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: $step) {
                ForEach(Step.allCases, id: \.self) { s in
                    page(for: s).tag(s)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: step) { _, new in if new != .name { nameFocused = false } }

            Button(action: next) {
                Text(buttonTitle)
            }
            .buttonStyle(PillButtonStyle(color: step == .done ? Theme.trayColor : Theme.inColor,
                                         foreground: step == .done ? Color(hex: 0x062014) : Theme.night))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Theme.night.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: step)
        .onChange(of: currentTray) { _, new in totalTrays = max(totalTrays, new) }
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack {
            Button { go(-1) } label: {
                Image(systemName: "chevron.left").font(.headline.weight(.bold))
                    .frame(width: 44, height: 44)
            }
            .opacity(step == .welcome ? 0 : 1)
            .disabled(step == .welcome)
            .accessibilityLabel("Back")
            Spacer()
            HStack(spacing: 7) {
                ForEach(Step.allCases, id: \.self) { s in
                    Capsule()
                        .fill(s == step ? Theme.inColor : Theme.raised)
                        .frame(width: s == step ? 22 : 7, height: 7)
                }
            }
            .animation(.snappy, value: step)
            .accessibilityElement()
            .accessibilityLabel("Step \(step.rawValue + 1) of \(Step.allCases.count)")
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
    }

    private var buttonTitle: String {
        switch step {
        case .welcome: "Get started"
        case .done: "Open Inly"
        default: "Next"
        }
    }

    private func go(_ delta: Int) {
        guard let target = Step(rawValue: step.rawValue + delta) else { return }
        withAnimation(.smooth) { step = target }
    }

    private func next() {
        if step == .reminders, remindersOn { TrayNotifications.requestPermission() }
        if step == .done { finish() } else { go(1) }
    }

    private func finish() {
        SessionService.shared.completeSetup(
            name: name, currentTray: currentTray, totalTrays: totalTrays,
            plannedDays: plannedDays, dayOnTray: dayOnTray, goalHours: goalHours
        )
        var settings = WearSettings.load()
        settings.remindersEnabled = remindersOn
        settings.stillOutMinutes = stillOut
        settings.save()
        if !alignersIn { SessionService.shared.takeOut() }
        onFinish()
    }

    // MARK: Pages

    private func page(for s: Step) -> some View {
        GeometryReader { geo in
        ScrollView {
            VStack(spacing: 22) {
                visual(for: s)
                    .padding(.top, 8)
                VStack(spacing: 8) {
                    Text(title(for: s)).font(Theme.font(30, .heavy)).multilineTextAlignment(.center)
                    Text(subtitle(for: s)).font(Theme.font(16, .medium)).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)
                controls(for: s)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: geo.size.height)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        }
    }

    @ViewBuilder
    private func visual(for s: Step) -> some View {
        switch s {
        case .welcome: WelcomeVisual(animate: animate)
        case .island: IslandVisual(animate: animate)
        case .widgets: WidgetsVisual(animate: animate)
        case .name: GreetingVisual(name: name)
        case .tray: trayWheels
        case .goal: GoalVisual(hours: goalHours, animate: animate)
        case .reminders: ReminderVisual(animate: animate)
        case .done: DoneVisual(animate: animate)
        }
    }

    private func title(for s: Step) -> String {
        switch s {
        case .welcome: "Meet Inly"
        case .island: "Always on top"
        case .widgets: "Right on your Home Screen"
        case .name: "What should we call you?"
        case .tray: "Which tray are you on?"
        case .goal: "Your daily goal"
        case .reminders: "Never forget them"
        case .done: name.trimmingCharacters(in: .whitespaces).isEmpty ? "You're all set" : "You're all set, \(name.trimmingCharacters(in: .whitespaces))"
        }
    }

    private func subtitle(for s: Step) -> String {
        switch s {
        case .welcome: "The calm way to track your aligners. One tap out, one tap back in."
        case .island: "Your timer lives in the Dynamic Island and on your Lock Screen, so you can put them back in without opening the app."
        case .widgets: "Add a widget and log with one tap. It works on your Home Screen, Lock Screen and Apple Watch."
        case .name: "We'll use it to say hello."
        case .tray: "So we start counting from the right tray and the right day."
        case .goal: "Most orthodontists ask for 20 to 22 hours a day. Use the number your orthodontist gave you."
        case .reminders: "Get a nudge when your aligners have been out too long. Turn off what you don't need."
        case .done: "Two quick things make Inly even better."
        }
    }

    @ViewBuilder
    private func controls(for s: Step) -> some View {
        switch s {
        case .name:
            TextField("Your first name", text: $name)
                .font(Theme.font(18, .semibold))
                .textContentType(.givenName)
                .submitLabel(.next)
                .focused($nameFocused)
                .onSubmit { go(1) }
                .padding(16)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        case .tray:
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("Started this tray", selection: $trayStart, in: ...Date.now, displayedComponents: .date)
                    .font(Theme.font(16, .heavy))
                    .tint(Theme.inColor)
                    .padding(16)
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text(traySummary)
                    .font(Theme.font(14, .semibold)).foregroundStyle(Theme.muted)
                    .padding(.horizontal, 4)
            }
        case .goal:
            VStack(spacing: 14) {
                Slider(value: Binding(get: { Double(goalHours) }, set: { goalHours = Int($0.rounded()) }), in: 16...23, step: 1)
                    .tint(Theme.inColor)
                    .accessibilityLabel("Hours a day")
                    .accessibilityValue("\(goalHours) hours")
                Toggle(isOn: $alignersIn) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My aligners are in right now").font(Theme.font(16, .heavy))
                        Text(alignersIn ? "Counting starts as worn." : "Counting starts as out. Tap Put back in when they're in.")
                            .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.trayColor)
                .padding(16)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        case .reminders:
            VStack(spacing: 14) {
                Toggle(isOn: $remindersOn) {
                    Text("Reminders").font(Theme.font(16, .heavy))
                }
                .tint(Theme.trayColor)
                .padding(16)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(spacing: 0) {
                    ForEach(Array(OutReason.allCases.enumerated()), id: \.element) { index, reason in
                        StillOutRow(
                            reason: reason,
                            minutes: Binding(
                                get: { stillOut[reason.rawValue] ?? WearSettings.defaultStillOut[reason.rawValue] ?? 30 },
                                set: { stillOut[reason.rawValue] = $0 }
                            )
                        )
                        if index < OutReason.allCases.count - 1 { Divider().overlay(Theme.surface) }
                    }
                }
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .opacity(remindersOn ? 1 : 0.4)
                .disabled(!remindersOn)
            }
        case .done:
            VStack(spacing: 10) {
                tip("square.grid.2x2", "Add the widget", "Touch and hold your Home Screen, tap +, then pick Inly.")
                tip("button.horizontal.top.press", "Use the Action Button", "Settings, Action Button, Shortcut, then choose Take out or Put back in.")
                tip("applewatch", "Install the watch app", "Open the Watch app on your iPhone and install Inly.")
            }
        default:
            EmptyView()
        }
    }

    private func tip(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(Theme.inColor)
                .frame(width: 40, height: 40).background(Theme.surface, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.font(15, .heavy))
                Text(text).font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Tray wheels

    private var trayWheels: some View {
        HStack(spacing: 0) {
            wheel("Tray", value: $currentTray, range: 1...80)
            wheel("Of", value: $totalTrays, range: 1...80)
            wheel("Days each", value: $plannedDays, range: 1...30)
        }
        .padding(.vertical, 6)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func wheel(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 0) {
            Text(title.uppercased()).font(Theme.font(11, .heavy)).tracking(1).foregroundStyle(Theme.muted)
                .padding(.top, 8)
            Picker(title, selection: value) {
                ForEach(Array(range), id: \.self) { Text("\($0)").font(Theme.font(20, .heavy)).tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .clipped()
        }
        .frame(maxWidth: .infinity)
    }

    private var traySummary: String {
        let left = plannedDays - dayOnTray
        if left > 0 { return "Day \(dayOnTray) of \(plannedDays). Switch to tray \(currentTray + 1) in \(left) day\(left == 1 ? "" : "s")." }
        if left == 0 { return "Day \(dayOnTray) of \(plannedDays). You're due to switch to tray \(currentTray + 1) today." }
        let over = -left
        return "That's \(over) day\(over == 1 ? "" : "s") over the plan, shown as +\(over) until you start tray \(currentTray + 1)."
    }
}
