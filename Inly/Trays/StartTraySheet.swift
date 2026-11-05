import SwiftUI

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

    private var timing: TrayLogic.Timing? {
        guard let current else { return nil }
        return TrayLogic.timing(start: current.startDate, plannedDays: current.plannedDays, switchingOn: date, calendar: .current)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When did you start it?") {
                    Picker("Start", selection: $yesterday) {
                        Text("Today").tag(false)
                        Text("Yesterday").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Plan") {
                    Stepper("\(plannedDays) days on this tray", value: $plannedDays, in: 1...30)
                    let due = TrayLogic.switchDate(start: date, plannedDays: plannedDays, calendar: .current)
                    Text("Next switch: \(due.formatted(.dateTime.weekday(.wide).month().day()))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let warning {
                    Section { Label(warning, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.outColor) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.night)
            .navigationTitle("Start tray \(nextNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { onStart(date, plannedDays); dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }

    private var warning: String? {
        switch timing {
        case .early(let d): "That is \(d) day\(d == 1 ? "" : "s") earlier than planned for tray \(nextNumber - 1)."
        case .late(let d): "That is \(d) day\(d == 1 ? "" : "s") later than planned for tray \(nextNumber - 1)."
        default: nil
        }
    }
}
