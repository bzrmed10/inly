import SwiftUI

/// Pick the next orthodontist visit; Inly reminds you the evening before and that morning.
struct AppointmentSheet: View {
    let initial: Date?
    var onSave: (Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date

    init(initial: Date?, onSave: @escaping (Date?) -> Void) {
        self.initial = initial
        self.onSave = onSave
        let fallback = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
        _date = State(initialValue: initial ?? Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: fallback) ?? fallback)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next orthodontist visit").font(Theme.font(26, .heavy))
            Text("We'll remind you the evening before and the morning of.")
                .font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)

            DatePicker("Visit", selection: $date, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .tint(Theme.inColor)

            VStack(spacing: 6) {
                Button("Save visit") { onSave(date); dismiss() }
                    .buttonStyle(PillButtonStyle(color: Theme.trayColor, foreground: Color(hex: 0x062014)))
                if initial != nil {
                    Button("Remove visit") { onSave(nil); dismiss() }
                        .font(Theme.font(16, .heavy)).foregroundStyle(Theme.overColor)
                        .frame(maxWidth: .infinity, minHeight: 48)
                } else {
                    Button("Cancel") { dismiss() }
                        .font(Theme.font(16, .heavy)).foregroundStyle(Color(hex: 0xC9C9D2))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
    }
}
