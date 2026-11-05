import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = WearSettings.load()

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily goal") {
                    Stepper("Wear \(settings.goalHours) h a day", value: $settings.goalHours, in: 16...23)
                    Text("That leaves \(24 - settings.goalHours) h a day out of your mouth.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Trays") {
                    Stepper("Total trays: \(settings.totalTrays)", value: $settings.totalTrays, in: 1...80)
                    Stepper("Days per tray: \(settings.defaultTrayDays)", value: $settings.defaultTrayDays, in: 1...30)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.night)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { settings.save(); dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }
}
