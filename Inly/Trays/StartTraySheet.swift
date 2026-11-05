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
        if saved < plan { return "\(plan - saved) day\(plan - saved == 1 ? "" : "s") earlier than planned (\(plan))" }
        if saved > plan { return "\(saved - plan) day\(saved - plan == 1 ? "" : "s") later than planned (\(plan))" }
        return nil
    }

    private var reminderDate: String {
        TrayLogic.switchDate(start: date, plannedDays: plannedDays, calendar: .current)
            .formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Start tray \(nextNumber)?").font(Theme.font(28, .heavy))
                if let current, let saved = savedDays {
                    Text("Tray \(current.number) will be saved with \(saved) day\(saved == 1 ? "" : "s").")
                        .font(Theme.font(15, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))
                }
                if let warning {
                    Text(warning).font(Theme.font(14, .heavy)).foregroundStyle(Theme.outColor)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Put it in").font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                HStack(spacing: 8) {
                    choice("Today", selected: !yesterday) { yesterday = false }
                    choice("Yesterday", selected: yesterday) { yesterday = true }
                }
            }

            StepperRow(title: "Days on this tray", valueText: "\(plannedDays) days", value: $plannedDays, range: 1...30)

            Text("We'll remind you to switch on \(reminderDate).")
                .font(Theme.font(14, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))

            VStack(spacing: 6) {
                Button("Start tray \(nextNumber)") { onStart(date, plannedDays); dismiss() }
                    .buttonStyle(PillButtonStyle(color: Theme.trayColor, foreground: Color(hex: 0x062014)))
                Button("Cancel") { dismiss() }
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
        TrayLogic.switchDate(start: tray.startDate, plannedDays: newPlan, calendar: .current)
            .formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Extend tray \(tray.number)").font(Theme.font(28, .heavy))
                Text("Planned: \(tray.plannedDays) days. Use this when your orthodontist asks for more time on this tray.")
                    .font(Theme.font(15, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))
            }
            StepperRow(title: "Add days", valueText: "+\(extra) day\(extra == 1 ? "" : "s")", value: $extra, range: 1...21)
            Text("New plan: \(newPlan) days. Switch on \(switchDate).")
                .font(Theme.font(14, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))
            VStack(spacing: 6) {
                Button("Extend by \(extra) day\(extra == 1 ? "" : "s")") { onExtend(extra); dismiss() }
                    .buttonStyle(PillButtonStyle(color: Theme.trayColor, foreground: Color(hex: 0x062014)))
                Button("Cancel") { dismiss() }
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
