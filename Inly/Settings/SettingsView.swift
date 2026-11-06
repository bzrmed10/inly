import SwiftUI
import WidgetKit

/// Settings tab (the detached glass circle next to the tab bar).
struct SettingsView: View {
    var onRedoSetup: () -> Void

    @State private var settings = WearSettings.load()
    @State private var confirmRedo = false

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Your treatment").font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)
                    Text("Settings").font(Theme.font(36, .heavy))
                }
                .padding(.top, 8)

                section("Profile") {
                    TextField("Your first name", text: $settings.userName)
                        .font(Theme.font(18, .semibold))
                        .textContentType(.givenName)
                        .padding(16)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                section("Daily goal") {
                    StepperRow(title: "Wear your aligners", valueText: "\(settings.goalHours) hours a day", value: $settings.goalHours, range: 16...23)
                    note("That leaves \(24 - settings.goalHours) hours a day out of your mouth.")
                }

                section("Trays") {
                    StepperRow(title: "Trays in your treatment", valueText: "\(settings.totalTrays) trays", value: $settings.totalTrays, range: 1...80)
                    StepperRow(title: "Default days per tray", valueText: "\(settings.defaultTrayDays) days", value: $settings.defaultTrayDays, range: 1...30)
                }

                section("Reminders") {
                    Toggle(isOn: $settings.remindersEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Out-time and tray reminders").font(Theme.font(16, .heavy))
                            Text("A nudge before your out-time runs out and on tray-change day.")
                                .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        }
                    }
                    .tint(Theme.trayColor)
                    .padding(16)
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                section("Still out? reminders") {
                    Text("Get a nudge when you've been out longer than this, with a Put back in button.")
                        .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(OutReason.allCases, id: \.self) { reason in
                        StepperRow(
                            title: reason.title,
                            valueText: settings.stillOut(for: reason) == 0 ? "Off" : "After \(settings.stillOut(for: reason)) min",
                            value: Binding(
                                get: { settings.stillOut(for: reason) },
                                set: { settings.setStillOut($0, for: reason) }
                            ),
                            range: 0...120, step: 5
                        )
                    }
                }
                .opacity(settings.remindersEnabled ? 1 : 0.45)
                .disabled(!settings.remindersEnabled)

                section("Setup") {
                    Button { confirmRedo = true } label: {
                        Text("Redo first-time setup")
                            .font(Theme.font(16, .heavy))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Theme.raised, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    note("Lets you pick your current tray and day again. Your wear history stays.")
                }

                Text("Inly \(version) · Your data stays on this iPhone.")
                    .font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 100)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.night.ignoresSafeArea())
        .onAppear { settings = WearSettings.load() }
        .onChange(of: settings) { _, new in
            var saved = new
            saved.onboardingDone = true
            saved.save()
            SessionService.shared.reconcileLiveActivity()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .confirmationDialog("Redo setup?", isPresented: $confirmRedo, titleVisibility: .visible) {
            Button("Redo setup", role: .destructive) {
                var s = WearSettings.load()
                s.onboardingDone = false
                s.save()
                onRedoSetup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current tray is replaced by the one you pick. Wear history is kept.")
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(17, .heavy))
            content()
        }
    }

    private func note(_ text: String) -> some View {
        Text(text).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).padding(.horizontal, 4)
    }
}
