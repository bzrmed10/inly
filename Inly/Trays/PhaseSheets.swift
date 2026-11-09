import SwiftUI

/// "Start refinement": the orthodontist rescanned and ordered a new set of trays.
/// Works at any time, also before the last tray of the current phase.
struct StartRefinementSheet: View {
    let current: Tray?
    let phaseTotal: Int
    let defaultDays: Int
    /// (start date, number of trays, days per tray)
    var onStart: (Date, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date = Calendar.current.startOfDay(for: .now)
    @State private var trays = 8
    @State private var days: Int

    init(current: Tray?, phaseTotal: Int, defaultDays: Int, onStart: @escaping (Date, Int, Int) -> Void) {
        self.current = current
        self.phaseTotal = phaseTotal
        self.defaultDays = defaultDays
        self.onStart = onStart
        _days = State(initialValue: defaultDays)
    }

    private var skipped: Int {
        guard let current else { return 0 }
        return max(0, phaseTotal - current.displayNumber)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("Start refinement")).font(Theme.font(28, .heavy))
                    Text(L10n.t("Your orthodontist ordered a new set of trays. Numbering starts again at 1 and your history stays."))
                        .font(Theme.font(15, .bold)).foregroundStyle(Theme.secondary)
                    if let current {
                        Text(skipped > 0
                             ? L10n.t("%@ stops at tray %d. The other %d are marked as skipped.", TreatmentPhase.name(current.phase), current.displayNumber, skipped)
                             : L10n.t("%@ is saved as finished.", TreatmentPhase.name(current.phase)))
                            .font(Theme.font(14, .heavy)).foregroundStyle(Theme.outText)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("First new tray goes in on")).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                    DatePicker("", selection: $date, in: pastLimit...Date.now, displayedComponents: .date)
                        .datePickerStyle(.compact).labelsHidden()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                StepperRow(title: L10n.t("Trays in the refinement"), valueText: L10n.trays(trays), value: $trays, range: 1...80)
                StepperRow(title: L10n.t("Days per tray"), valueText: L10n.days(days), value: $days, range: 1...30)

                VStack(spacing: 6) {
                    Button(L10n.t("Start refinement")) { onStart(Calendar.current.startOfDay(for: date), trays, days); dismiss() }
                        .buttonStyle(PillButtonStyle(color: Theme.phaseColor((current?.phase ?? 0) + 1), foreground: Theme.night))
                    Button(L10n.t("Cancel")) { dismiss() }
                        .font(Theme.font(16, .heavy))
                        .foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .presentationDetents([.fraction(0.9), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.sheet)
        .presentationCornerRadius(34)
    }

    private var pastLimit: Date { Calendar.current.date(byAdding: .day, value: -60, to: .now) ?? .now }
}

/// Treatment is over: choose how the retainer is worn.
struct RetainerSheet: View {
    var onStart: (Date, RetainerSchedule, Int, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var schedule: RetainerSchedule = .nightly
    @State private var hours = 8
    @State private var nights = 4
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: .now) ?? .now

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("Start retainer mode")).font(Theme.font(28, .heavy))
                    Text(L10n.t("Your last tray is saved as finished. Inly now tracks your retainer instead."))
                        .font(Theme.font(15, .bold)).foregroundStyle(Theme.secondary)
                }

                VStack(spacing: 8) {
                    option(.fullTime, L10n.t("Full-time"), L10n.t("Worn all day, like your aligners."))
                    option(.nightly, L10n.t("Every night"), L10n.t("Worn while you sleep."))
                    option(.fewNights, L10n.t("A few nights a week"), L10n.t("Worn on some nights only."))
                }

                StepperRow(title: L10n.t("Hours of wear"), valueText: L10n.t("%d hours a day", hours), value: $hours, range: 4...23)
                if schedule != .fullTime {
                    if schedule == .fewNights {
                        StepperRow(title: L10n.t("Nights per week"), valueText: "\(nights)", value: $nights, range: 1...6)
                    }
                    HStack {
                        Text(L10n.t("Bedtime reminder")).font(Theme.font(16, .heavy))
                        Spacer()
                        DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute).labelsHidden()
                    }
                    .padding(.vertical, 8).padding(.horizontal, 16)
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    Text(L10n.t("Take it out when you wake up and put it back in at bedtime. Inly counts the hours it was in."))
                        .font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                }

                VStack(spacing: 6) {
                    Button(L10n.t("Start retainer mode")) {
                        let c = Calendar.current.dateComponents([.hour, .minute], from: bedtime)
                        onStart(.now, schedule, hours, nights, (c.hour ?? 22) * 60 + (c.minute ?? 30))
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle(color: Theme.retainerColor, foreground: Theme.night))
                    Button(L10n.t("Cancel")) { dismiss() }
                        .font(Theme.font(16, .heavy))
                        .foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .presentationDetents([.fraction(0.92), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.sheet)
        .presentationCornerRadius(34)
    }

    private func option(_ value: RetainerSchedule, _ title: String, _ subtitle: String) -> some View {
        Button {
            schedule = value
            if value == .fullTime { hours = 22 } else if hours > 16 { hours = 8 }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.font(16, .heavy))
                    Text(subtitle).font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: schedule == value ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(schedule == value ? Theme.retainerColor : Theme.muted)
                    .font(.system(size: 22))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(schedule == value ? .isSelected : [])
    }
}
