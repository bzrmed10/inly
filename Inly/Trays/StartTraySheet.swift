import SwiftUI

/// "Start tray N?" sheet, laid out like the design.
struct StartTraySheet: View {
    let current: Tray?
    let nextNumber: Int
    let defaultDays: Int
    var onStart: (Date, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var yesterday = false
    @State private var plannedDays: Int

    init(current: Tray?, nextNumber: Int, defaultDays: Int, onStart: @escaping (Date, Int) -> Void) {
        self.current = current
        self.nextNumber = nextNumber
        self.defaultDays = defaultDays
        self.onStart = onStart
        _plannedDays = State(initialValue: defaultDays)
    }

    private var date: Date {
        let today = Calendar.current.startOfDay(for: .now)
        return yesterday ? (Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today) : today
    }

    private var savedDays: Int? {
        guard let current else { return nil }
        return TrayLogic.daysSpent(start: current.startDate, end: date, now: date, calendar: .current)
    }

    private var warning: String? {
        guard let current, let saved = savedDays else { return nil }
        let plan = current.plannedDays
        if saved < plan { return L10n.t("%@ earlier than planned (%d)", L10n.days(plan - saved), plan) }
        if saved > plan { return L10n.t("%@ later than planned (%d)", L10n.days(saved - plan), plan) }
        return nil
    }

    private var reminderDate: String {
        L10n.date(TrayLogic.switchDate(start: date, plannedDays: plannedDays, calendar: .current),
                  .dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.t("Start tray %d?", nextNumber)).font(Theme.font(28, .heavy))
                if let current, let saved = savedDays {
                    Text(L10n.t("Tray %d will be saved with %@.", current.displayNumber, L10n.days(saved)))
                        .font(Theme.font(15, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))
                }
                if let warning {
                    Text(warning).font(Theme.font(14, .heavy)).foregroundStyle(Theme.outColor)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("Put it in")).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                HStack(spacing: 8) {
                    choice(L10n.t("Today"), selected: !yesterday) { yesterday = false }
                    choice(L10n.t("Yesterday"), selected: yesterday) { yesterday = true }
                }
            }

            StepperRow(title: L10n.t("Days on this tray"), valueText: L10n.days(plannedDays), value: $plannedDays, range: 1...30)

            Text(L10n.t("We'll remind you to switch on %@.", reminderDate))
                .font(Theme.font(14, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))

            VStack(spacing: 6) {
                Button(L10n.t("Start tray %d", nextNumber)) { onStart(date, plannedDays); dismiss() }
                    .buttonStyle(PillButtonStyle(color: Theme.trayColor, foreground: Color(hex: 0x062014)))
                Button(L10n.t("Cancel")) { dismiss() }
                    .font(Theme.font(16, .heavy))
                    .foregroundStyle(Color(hex: 0xC9C9D2))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.fraction(0.86), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
    }

    private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(15, .heavy))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(selected ? Theme.night : .white)
                .background(selected ? Color.white : Color(hex: 0x2A2A33), in: Capsule())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: selected)
    }
}

/// Add days to the current tray on purpose.
struct ExtendTraySheet: View {
    let tray: Tray
    var onExtend: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var extra = 2

    private var newPlan: Int { tray.plannedDays + extra }
    private var switchDate: String {
        L10n.date(TrayLogic.switchDate(start: tray.startDate, plannedDays: newPlan, calendar: .current),
                  .dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.t("Extend tray %d", tray.displayNumber)).font(Theme.font(28, .heavy))
                Text(L10n.t("Planned: %@. Use this when your orthodontist asks for more time on this tray.", L10n.days(tray.plannedDays)))
                    .font(Theme.font(15, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))
            }
            StepperRow(title: L10n.t("Add days"), valueText: "+" + L10n.days(extra), value: $extra, range: 1...21)
            Text(L10n.t("New plan: %@. Switch on %@.", L10n.days(newPlan), switchDate))
                .font(Theme.font(14, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))
            VStack(spacing: 6) {
                Button(L10n.t("Extend by %@", L10n.days(extra))) { onExtend(extra); dismiss() }
                    .buttonStyle(PillButtonStyle(color: Theme.trayColor, foreground: Color(hex: 0x062014)))
                Button(L10n.t("Cancel")) { dismiss() }
                    .font(Theme.font(16, .heavy))
                    .foregroundStyle(Color(hex: 0xC9C9D2))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.fraction(0.62), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
    }
}
