import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

/// Settings tab (the detached glass circle next to the tab bar).
struct SettingsView: View {
    var onRedoSetup: () -> Void

    @State private var settings = WearSettings.load()
    @State private var confirmRedo = false
    @State private var languageRaw = L10n.selected.rawValue
    @State private var backupDoc: BackupDocument?
    @State private var exportingBackup = false
    @State private var importingBackup = false
    @State private var pickingFolder = false
    @State private var pendingRestore: Data?
    @State private var backupMessage: String?
    @State private var lastBackup = BackupService.shared.lastBackup
    @State private var folderName = BackupService.shared.folderName

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L10n.t("Your treatment")).font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)
                    Text(L10n.t("Settings")).font(Theme.font(36, .heavy))
                }
                .padding(.top, 8)

                section(L10n.t("Profile")) {
                    TextField(L10n.t("Your first name"), text: $settings.userName)
                        .font(Theme.font(18, .semibold))
                        .textContentType(.givenName)
                        .padding(16)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                section(L10n.t("Language")) {
                    VStack(spacing: 0) {
                        ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { index, lang in
                            Button { languageRaw = lang.rawValue; L10n.select(lang); applyLanguageChange() } label: {
                                HStack {
                                    Text(lang.nativeName).font(Theme.font(16, .heavy))
                                    Spacer()
                                    if languageRaw == lang.rawValue {
                                        Image(systemName: "checkmark").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.inColor)
                                    }
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < AppLanguage.allCases.count - 1 { Divider().overlay(Theme.surface) }
                        }
                    }
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                section(L10n.t("Daily goal")) {
                    StepperRow(title: L10n.t("Wear your aligners"), valueText: L10n.t("%d hours a day", settings.goalHours), value: $settings.goalHours, range: 16...23)
                    note(L10n.t("That leaves %d hours a day out of your mouth.", 24 - settings.goalHours))
                }

                section(L10n.t("Trays")) {
                    StepperRow(title: L10n.t("Trays in your treatment"), valueText: L10n.trays(settings.totalTrays), value: $settings.totalTrays, range: 1...80)
                    StepperRow(title: L10n.t("Default days per tray"), valueText: L10n.days(settings.defaultTrayDays), value: $settings.defaultTrayDays, range: 1...30)
                }

                section(L10n.t("Reminders")) {
                    Toggle(isOn: $settings.remindersEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.t("Out-time and tray reminders")).font(Theme.font(16, .heavy))
                            Text(L10n.t("A nudge before your out-time runs out and on tray-change day."))
                                .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        }
                    }
                    .tint(Theme.trayColor)
                    .padding(16)
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                section(L10n.t("Still out? reminders")) {
                    Text(L10n.t("A nudge when you've been out for a while, with a Put back in button."))
                        .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 0) {
                        ForEach(Array(OutReason.allCases.enumerated()), id: \.element) { index, reason in
                            StillOutRow(
                                reason: reason,
                                minutes: Binding(
                                    get: { settings.stillOut(for: reason) },
                                    set: { settings.setStillOut($0, for: reason) }
                                )
                            )
                            if index < OutReason.allCases.count - 1 {
                                Divider().overlay(Theme.surface)
                            }
                        }
                    }
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .opacity(settings.remindersEnabled ? 1 : 0.45)
                .disabled(!settings.remindersEnabled)

                section(L10n.t("Backup")) {
                    VStack(alignment: .leading, spacing: 0) {
                        backupRow(icon: "icloud.and.arrow.up.fill", title: L10n.t("Back up now"), subtitle: L10n.t("Save a file to iCloud Drive or Files")) {
                            do {
                                backupDoc = BackupDocument(data: try BackupService.shared.makeBackupData())
                                exportingBackup = true
                            } catch { backupMessage = error.localizedDescription }
                        }
                        Divider().overlay(Theme.surface)
                        backupRow(icon: "icloud.and.arrow.down.fill", title: L10n.t("Restore from backup"), subtitle: L10n.t("Replaces everything in Inly with a backup file")) {
                            importingBackup = true
                        }
                        Divider().overlay(Theme.surface)
                        backupRow(
                            icon: "arrow.triangle.2.circlepath.icloud.fill",
                            title: folderName.map { L10n.t("Automatic backup · %@", $0) } ?? L10n.t("Automatic backup"),
                            subtitle: folderName == nil ? L10n.t("Pick an iCloud Drive folder once; Inly keeps it up to date") : (lastBackup.map { L10n.t("Last backup %@", L10n.dateTime($0)) } ?? L10n.t("Waiting for first backup"))
                        ) { pickingFolder = true }
                        if folderName != nil {
                            Divider().overlay(Theme.surface)
                            backupRow(icon: "xmark.circle.fill", title: L10n.t("Turn off automatic backup"), subtitle: L10n.t("Existing backup files stay where they are")) {
                                BackupService.shared.clearFolder()
                                folderName = nil
                            }
                        }
                    }
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    note(L10n.t("Backups include your history, trays, photos, notes and settings."))
                }

                section(L10n.t("Setup")) {
                    Button { confirmRedo = true } label: {
                        Text(L10n.t("Redo first-time setup"))
                            .font(Theme.font(16, .heavy))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Theme.raised, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    note(L10n.t("Lets you pick your current tray and day again. Your wear history stays."))
                }

                Text(L10n.t("Inly %@ · Your data stays on your devices.", version))
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
        .fileExporter(isPresented: $exportingBackup, document: backupDoc, contentType: .json, defaultFilename: "Inly Backup") { result in
            switch result {
            case .success: backupMessage = L10n.t("Backup saved.")
            case .failure(let e): backupMessage = e.localizedDescription
            }
        }
        .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                _ = try BackupFile.decode(data)
                pendingRestore = data
            } catch { backupMessage = error.localizedDescription }
        }
        .fileImporter(isPresented: $pickingFolder, allowedContentTypes: [.folder]) { result in
            guard case .success(let url) = result else { return }
            do {
                try BackupService.shared.setFolder(url)
                folderName = BackupService.shared.folderName
                lastBackup = BackupService.shared.lastBackup
                backupMessage = L10n.t("Automatic backup is on.")
            } catch { backupMessage = error.localizedDescription }
        }
        .confirmationDialog(L10n.t("Replace everything with this backup?"), isPresented: Binding(get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } }), titleVisibility: .visible) {
            Button(L10n.t("Restore"), role: .destructive) {
                if let data = pendingRestore {
                    do {
                        try BackupService.shared.restore(data)
                        settings = WearSettings.load()
                        backupMessage = L10n.t("Backup restored.")
                    } catch { backupMessage = error.localizedDescription }
                }
                pendingRestore = nil
            }
            Button(L10n.t("Cancel"), role: .cancel) { pendingRestore = nil }
        } message: {
            Text(L10n.t("Your current history, trays, photos and notes are replaced."))
        }
        .alert(L10n.t("Backup"), isPresented: Binding(get: { backupMessage != nil }, set: { if !$0 { backupMessage = nil } })) {
            Button(L10n.t("OK")) { backupMessage = nil }
        } message: { Text(backupMessage ?? "") }
        .confirmationDialog(L10n.t("Redo setup?"), isPresented: $confirmRedo, titleVisibility: .visible) {
            Button(L10n.t("Redo setup"), role: .destructive) {
                var s = WearSettings.load()
                s.onboardingDone = false
                s.save()
                onRedoSetup()
            }
            Button(L10n.t("Cancel"), role: .cancel) {}
        } message: {
            Text(L10n.t("Your current tray is replaced by the one you pick. Wear history is kept."))
        }
    }

    /// Everything that was already scheduled or drawn in the old language is refreshed.
    private func applyLanguageChange() {
        SessionService.shared.commit()
        if let tray = SessionService.shared.currentTray() { TrayNotifications.scheduleSwitchReminder(for: tray) }
        AppointmentReminders.schedule(WearSettings.load().nextAppointment)
        OutReminders.registerCategory()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(17, .heavy))
            content()
        }
    }

    private func backupRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.inColor).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.font(16, .heavy))
                    Text(subtitle).font(Theme.font(13, .medium)).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).padding(.horizontal, 4)
    }
}


/// One reason: a switch to turn the nudge on or off in one tap, and quick time choices when it's on.
struct StillOutRow: View {
    let reason: OutReason
    @Binding var minutes: Int
    private let choices = [5, 10, 15, 20, 30, 45, 60]

    private var isOn: Binding<Bool> {
        Binding(
            get: { minutes > 0 },
            set: { minutes = $0 ? (WearSettings.defaultStillOut[reason.rawValue] ?? 30) : 0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: isOn) {
                HStack(spacing: 12) {
                    Image(systemName: reason.symbol).frame(width: 24).foregroundStyle(Theme.outColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reason.title).font(Theme.font(16, .heavy))
                        Text(minutes > 0 ? L10n.t("Ask after %d min", minutes) : L10n.t("Off"))
                            .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                    }
                }
            }
            .tint(Theme.trayColor)

            if minutes > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(choices, id: \.self) { m in
                            Button { minutes = m } label: {
                                Text("\(m)" + L10n.t("unit.m")).font(Theme.font(14, .heavy)).monospacedDigit()
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(m == minutes ? Theme.inColor : Theme.surface, in: Capsule())
                                    .foregroundStyle(m == minutes ? Theme.night : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.minutes(m))
                            .accessibilityAddTraits(m == minutes ? .isSelected : [])
                        }
                    }
                }
            }
        }
        .padding(16)
        .animation(.snappy, value: minutes > 0)
    }
}
