import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

private enum SettingsPage: Hashable {
    case treatment, reminders, backup, language, about
}

/// Settings tab: a short list of rows, each opening its own page.
struct SettingsView: View {
    var onRedoSetup: () -> Void

    @State private var settings = WearSettings.load()
    @State private var languageRaw = L10n.selected.rawValue

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private var phaseName: String {
        if settings.retainerMode { return TreatmentPhase.retainerName }
        let phase = SessionService.shared.currentTray()?.phase ?? 0
        return TreatmentPhase.name(phase)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.t("Your treatment")).font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)
                        Text(L10n.t("Settings")).font(Theme.font(36, .heavy))
                    }
                    .padding(.top, 8)

                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 26)).foregroundStyle(Theme.muted)
                        TextField(L10n.t("Your first name"), text: $settings.userName)
                            .font(Theme.font(17, .semibold))
                            .textContentType(.givenName)
                    }
                    .padding(16)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    VStack(spacing: 10) {
                        row(.treatment, "cross.case.fill", Theme.trayColor, L10n.t("Treatment"),
                            "\(phaseName) · " + L10n.t("%d hours a day", settings.goalHours))
                        row(.reminders, "bell.badge.fill", Theme.outColor, L10n.t("Reminders"),
                            settings.remindersEnabled ? L10n.t("On") : L10n.t("Off"))
                        row(.backup, "icloud.fill", Theme.inColor, L10n.t("Backup and data"),
                            BackupService.shared.folderName == nil ? L10n.t("Not set up") : L10n.t("Automatic backup"))
                        row(.language, "globe", Color(hex: 0xB28DFF), L10n.t("Language"),
                            AppLanguage(rawValue: languageRaw)?.nativeName ?? L10n.selected.nativeName)
                        row(.about, "info.circle.fill", Theme.muted, L10n.t("About"), version)
                    }

                    Text(L10n.t("Inly %@ · Your data stays on your devices.", version))
                        .font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.night.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsPage.self) { page in
                Group {
                    switch page {
                    case .treatment: TreatmentSettingsPage(settings: $settings, onRedoSetup: onRedoSetup)
                    case .reminders: RemindersSettingsPage(settings: $settings)
                    case .backup: BackupSettingsPage(settings: $settings)
                    case .language: LanguageSettingsPage(languageRaw: $languageRaw)
                    case .about: AboutSettingsPage(version: version)
                    }
                }
                .background(Theme.night.ignoresSafeArea())
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
        .onAppear { settings = WearSettings.load() }
        .onChange(of: settings) { _, new in
            var saved = new
            saved.onboardingDone = true
            if saved.retainerMode, saved.goalHours != saved.retainerHours {
                saved.applyRetainerGoal()
                settings = saved
            }
            saved.save()
            RetainerReminders.reschedule()
            SessionService.shared.reconcileLiveActivity()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func row(_ page: SettingsPage, _ icon: String, _ color: Color, _ title: String, _ subtitle: String) -> some View {
        NavigationLink(value: page) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(color)
                    .frame(width: 38, height: 38).background(Theme.raised, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.font(16, .heavy)).foregroundStyle(.white)
                    Text(subtitle).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Shared page pieces

private struct SettingsBlock<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(17, .heavy))
            content
        }
    }
}

private func settingsNote(_ text: String) -> some View {
    Text(text).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).padding(.horizontal, 4)
}

private struct SettingsPageScroll<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { content }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.night.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: Treatment

private struct TreatmentSettingsPage: View {
    @Binding var settings: WearSettings
    var onRedoSetup: () -> Void
    @State private var confirmRedo = false

    var body: some View {
        SettingsPageScroll(title: L10n.t("Treatment")) {
            if settings.retainerMode {
                SettingsBlock(title: TreatmentPhase.retainerName) {
                    VStack(spacing: 8) {
                        ForEach(RetainerSchedule.allCases, id: \.self) { s in
                            Button {
                                settings.retainerSchedule = s
                                if s == .fullTime { settings.retainerHours = 22 } else if settings.retainerHours > 16 { settings.retainerHours = 8 }
                            } label: {
                                HStack {
                                    Text(title(s)).font(Theme.font(16, .heavy))
                                    Spacer()
                                    if settings.retainerSchedule == s {
                                        Image(systemName: "checkmark").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.retainerColor)
                                    }
                                }
                                .padding(16)
                                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    StepperRow(title: L10n.t("Hours of wear"), valueText: L10n.t("%d hours a day", settings.retainerHours), value: $settings.retainerHours, range: 4...23)
                    if settings.retainerSchedule == .fewNights {
                        StepperRow(title: L10n.t("Nights per week"), valueText: "\(settings.retainerNights)", value: $settings.retainerNights, range: 1...6)
                    }
                }
            } else {
                SettingsBlock(title: L10n.t("Daily goal")) {
                    StepperRow(title: L10n.t("Wear your aligners"), valueText: L10n.t("%d hours a day", settings.goalHours), value: $settings.goalHours, range: 16...23)
                    settingsNote(L10n.t("That leaves %d hours a day out of your mouth.", 24 - settings.goalHours))
                }
                SettingsBlock(title: L10n.t("Trays")) {
                    StepperRow(title: L10n.t("Trays in this phase"), valueText: L10n.trays(settings.totalTrays), value: $settings.totalTrays, range: 1...80)
                    StepperRow(title: L10n.t("Default days per tray"), valueText: L10n.days(settings.defaultTrayDays), value: $settings.defaultTrayDays, range: 1...30)
                    settingsNote(L10n.t("Start a refinement or retainer mode from the Trays tab."))
                }
            }

            SettingsBlock(title: L10n.t("Setup")) {
                Button(role: .destructive) { confirmRedo = true } label: {
                    Text(L10n.t("Redo first-time setup"))
                        .font(Theme.font(16, .heavy))
                        .foregroundStyle(Theme.overColor)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.raised, in: Capsule())
                }
                .buttonStyle(.plain)
                settingsNote(L10n.t("Lets you pick your current tray and day again. Your wear history stays."))
            }
        }
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

    private func title(_ s: RetainerSchedule) -> String {
        switch s {
        case .fullTime: L10n.t("Full-time")
        case .nightly: L10n.t("Every night")
        case .fewNights: L10n.t("A few nights a week")
        }
    }
}

// MARK: Reminders

private struct RemindersSettingsPage: View {
    @Binding var settings: WearSettings

    private var bedtime: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: settings.bedtimeMinutes / 60, minute: settings.bedtimeMinutes % 60, second: 0, of: .now) ?? .now },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                settings.bedtimeMinutes = (c.hour ?? 22) * 60 + (c.minute ?? 30)
            }
        )
    }

    var body: some View {
        SettingsPageScroll(title: L10n.t("Reminders")) {
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

            Group {
                if settings.isNightRetainer {
                    SettingsBlock(title: L10n.t("Bedtime")) {
                        VStack(spacing: 0) {
                            Toggle(L10n.t("Bedtime reminder"), isOn: $settings.bedtimeReminder)
                                .font(Theme.font(16, .heavy)).tint(Theme.trayColor).padding(16)
                            if settings.bedtimeReminder {
                                Divider().overlay(Theme.surface)
                                HStack {
                                    Text(L10n.t("Time")).font(Theme.font(16, .heavy))
                                    Spacer()
                                    DatePicker("", selection: bedtime, displayedComponents: .hourAndMinute).labelsHidden()
                                }
                                .padding(16)
                            }
                        }
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        settingsNote(L10n.t("Time to put your retainer in."))
                    }
                } else {
                    SettingsBlock(title: L10n.t("Still out? reminders")) {
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
                                if index < OutReason.allCases.count - 1 { Divider().overlay(Theme.surface) }
                            }
                        }
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
            }
            .opacity(settings.remindersEnabled ? 1 : 0.45)
            .disabled(!settings.remindersEnabled)
        }
    }
}

// MARK: Backup

private struct BackupSettingsPage: View {
    @Binding var settings: WearSettings
    @State private var backupDoc: BackupDocument?
    @State private var exportingBackup = false
    @State private var importingBackup = false
    @State private var pickingFolder = false
    @State private var pendingRestore: Data?
    @State private var backupMessage: String?
    @State private var lastBackup = BackupService.shared.lastBackup
    @State private var folderName = BackupService.shared.folderName

    var body: some View {
        SettingsPageScroll(title: L10n.t("Backup and data")) {
            VStack(alignment: .leading, spacing: 0) {
                backupRow(icon: "icloud.and.arrow.up.fill", title: L10n.t("Back up now"), subtitle: L10n.t("Save a file to iCloud Drive or Files")) {
                    do {
                        backupDoc = BackupDocument(data: try BackupService.shared.makeBackupData())
                        exportingBackup = true
                    } catch { backupMessage = error.localizedDescription }
                }
                Divider().overlay(Theme.surface)
                backupRow(
                    icon: "arrow.triangle.2.circlepath.icloud.fill",
                    title: folderName.map { L10n.t("Automatic backup · %@", $0) } ?? L10n.t("Automatic backup"),
                    subtitle: folderName == nil ? L10n.t("Pick an iCloud Drive folder once; Inly keeps it up to date") : (lastBackup.map { L10n.t("Last backup %@", L10n.dateTime($0)) } ?? L10n.t("Waiting for first backup"))
                ) { pickingFolder = true }
            }
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            settingsNote(L10n.t("Backups include your history, trays, photos, notes and settings."))

            SettingsBlock(title: L10n.t("Restore")) {
                VStack(alignment: .leading, spacing: 0) {
                    backupRow(icon: "icloud.and.arrow.down.fill", tint: Theme.overColor, title: L10n.t("Restore from backup"), subtitle: L10n.t("Replaces everything in Inly with a backup file")) {
                        importingBackup = true
                    }
                    if folderName != nil {
                        Divider().overlay(Theme.surface)
                        backupRow(icon: "xmark.circle.fill", tint: Theme.overColor, title: L10n.t("Turn off automatic backup"), subtitle: L10n.t("Existing backup files stay where they are")) {
                            BackupService.shared.clearFolder()
                            folderName = nil
                        }
                    }
                }
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
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
    }

    private func backupRow(icon: String, tint: Color = Theme.inColor, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundStyle(tint).frame(width: 28)
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
}

// MARK: Language

private struct LanguageSettingsPage: View {
    @Binding var languageRaw: String

    var body: some View {
        SettingsPageScroll(title: L10n.t("Language")) {
            VStack(spacing: 0) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { index, lang in
                    Button {
                        languageRaw = lang.rawValue
                        L10n.select(lang)
                        applyLanguageChange()
                    } label: {
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
    }

    /// Everything that was already scheduled or drawn in the old language is refreshed.
    private func applyLanguageChange() {
        SessionService.shared.commit()
        if let tray = SessionService.shared.currentTray() { TrayNotifications.scheduleSwitchReminder(for: tray) }
        AppointmentReminders.schedule(WearSettings.load().nextAppointment)
        OutReminders.registerCategory()
        RetainerReminders.reschedule()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: About

private struct AboutSettingsPage: View {
    let version: String
    var body: some View {
        SettingsPageScroll(title: L10n.t("About")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Inly").font(Theme.font(28, .heavy))
                Text(L10n.t("Version %@", version)).font(Theme.font(15, .semibold)).foregroundStyle(Theme.muted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            settingsNote(L10n.t("Your data stays on your devices."))
        }
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
