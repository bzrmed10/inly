import StoreKit
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

private enum SettingsPage: Hashable {
    case plus, treatment, reminders, backup, appearance, language, about
}

/// Settings tab: a short list of rows, each opening its own page.
struct SettingsView: View {
    var onRedoSetup: () -> Void

    @State private var settings = WearSettings.load()
    @State private var languageRaw = L10n.selected.rawValue
    @AppStorage(AppAppearance.storageKey, store: UserDefaults(suiteName: AppGroup.identifier)) private var appearanceRaw = AppAppearance.dark.rawValue

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

                    plusCard

                    VStack(spacing: 10) {
                        row(.treatment, "cross.case.fill", L10n.t("Treatment"),
                            "\(phaseName) · " + L10n.t("%d hours a day", settings.goalHours))
                        row(.reminders, "bell.badge.fill", L10n.t("Reminders"),
                            settings.remindersEnabled ? L10n.t("On") : L10n.t("Off"))
                        row(.backup, "icloud.fill", L10n.t("Backup and data"), backupSubtitle)
                        row(.appearance, "circle.lefthalf.filled", L10n.t("Appearance"),
                            (AppAppearance(rawValue: appearanceRaw) ?? .dark).title)
                        row(.language, "globe", L10n.t("Language"),
                            AppLanguage(rawValue: languageRaw)?.nativeName ?? L10n.selected.nativeName)
                        row(.about, "info.circle.fill", L10n.t("About"), version)
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
                    case .plus: PlusSettingsPage()
                    case .treatment: TreatmentSettingsPage(settings: $settings, onRedoSetup: onRedoSetup)
                    case .reminders: RemindersSettingsPage(settings: $settings)
                    case .backup: BackupSettingsPage(settings: $settings)
                    case .appearance: AppearanceSettingsPage(appearanceRaw: $appearanceRaw)
                    case .language: LanguageSettingsPage(languageRaw: $languageRaw)
                    case .about: AboutSettingsPage(version: version)
                    }
                }
                .background(Theme.night.ignoresSafeArea())
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

    private var backupSubtitle: String {
        if CloudSync.shared.isOn { return L10n.t("iCloud sync on") }
        return BackupService.shared.folderName == nil ? L10n.t("Not set up") : L10n.t("Automatic backup")
    }

    /// Inly+ status at the top of Settings: an invitation when locked, the status when unlocked.
    @ViewBuilder
    private var plusCard: some View {
        let store = Store.shared
        if store.isPlus {
            NavigationLink(value: SettingsPage.plus) {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 19, weight: .bold)).foregroundStyle(Theme.inColor)
                        .frame(width: 38, height: 38).background(Theme.inColor.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inly+").font(Theme.font(16, .heavy)).foregroundStyle(Theme.text)
                        Text(PlusSettingsPage.statusLine(store)).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted)
                }
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Button { store.paywall = .general } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().stroke(Theme.track, lineWidth: 5)
                        Circle().trim(from: 0, to: 0.75)
                            .stroke(Theme.inColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("+").font(Theme.font(17, .heavy)).foregroundStyle(Theme.text)
                    }
                    .frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Inly+").font(Theme.font(18, .heavy)).foregroundStyle(Theme.text)
                        Text(store.trialUsed ? L10n.t("Apple Watch, widgets, sync, reports. Pay once.")
                                             : L10n.t("Try everything free for 7 days"))
                            .font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Text(store.trialUsed ? L10n.t("Unlock") : L10n.t("Try free"))
                        .font(Theme.font(14, .heavy)).foregroundStyle(Theme.night)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.inColor, in: Capsule())
                }
                .padding(16)
                .background(
                    LinearGradient(colors: [Theme.inColor.opacity(0.22), Theme.phaseColor(1).opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.inColor.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func row(_ page: SettingsPage, _ icon: String, _ title: String, _ subtitle: String) -> some View {
        NavigationLink(value: page) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.muted)
                    .frame(width: 38, height: 38).background(Theme.raised, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.font(16, .heavy)).foregroundStyle(Theme.text)
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
    @State private var syncOn = CloudSync.shared.isOn
    @State private var syncChoice: CloudSync.Remote?

    var body: some View {
        SettingsPageScroll(title: L10n.t("Backup and data")) {
            SettingsBlock(title: L10n.t("iCloud sync")) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        Image(systemName: "icloud.fill").font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.inColor).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(L10n.t("Sync with iCloud")).font(Theme.font(16, .heavy))
                                if !Store.shared.isPlus { plusBadge }
                            }
                            Text(syncSubtitle).font(Theme.font(13, .medium)).foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 0)
                        Toggle("", isOn: Binding(get: { syncOn }, set: { setSync($0) })).labelsHidden().tint(Theme.inColor)
                    }
                    .padding(16)
                }
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                settingsNote(L10n.t("Your history, trays, notes and settings, in your own iCloud. Photos stay on this iPhone."))
            }

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
                ) { Store.shared.require(.sync) { pickingFolder = true } }
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
        .confirmationDialog(L10n.t("Inly data is already in iCloud"), isPresented: Binding(get: { syncChoice != nil }, set: { if !$0 { syncChoice = nil } }), titleVisibility: .visible) {
            Button(L10n.t("Use the iCloud data")) {
                if let r = syncChoice { CloudSync.shared.apply(r); settings = WearSettings.load() }
                syncChoice = nil
            }
            Button(L10n.t("Keep this iPhone's data")) { CloudSync.shared.keepLocal(); syncChoice = nil }
            Button(L10n.t("Cancel"), role: .cancel) { CloudSync.shared.disable(); syncOn = false; syncChoice = nil }
        } message: {
            Text(L10n.t("Another iPhone saved Inly data %@. Which one should Inly keep?", syncChoice.map { L10n.dateTime($0.modified) } ?? ""))
        }
        .alert(L10n.t("Backup"), isPresented: Binding(get: { backupMessage != nil }, set: { if !$0 { backupMessage = nil } })) {
            Button(L10n.t("OK")) { backupMessage = nil }
        } message: { Text(backupMessage ?? "") }
    }

    private var plusBadge: some View {
        Text("Inly+").font(Theme.font(11, .heavy)).foregroundStyle(Theme.inColor)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Theme.inColor.opacity(0.15), in: Capsule())
    }

    private var syncSubtitle: String {
        switch CloudSync.shared.status {
        case .off: return L10n.t("Off")
        case .unavailable: return L10n.t("Sign in to iCloud in the Settings app to sync")
        case .tooLarge: return L10n.t("Too much data for iCloud sync. Use automatic backup.")
        case .upToDate(let date): return L10n.t("Synced %@", L10n.dateTime(date))
        }
    }

    private func setSync(_ on: Bool) {
        guard on else { CloudSync.shared.disable(); syncOn = false; return }
        guard Store.shared.isPlus else { Store.shared.paywall = .sync; return }
        syncOn = true
        if let remote = CloudSync.shared.enable() { syncChoice = remote }
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

// MARK: Appearance

private struct AppearanceSettingsPage: View {
    @Binding var appearanceRaw: String

    var body: some View {
        SettingsPageScroll(title: L10n.t("Appearance")) {
            VStack(spacing: 0) {
                ForEach(Array(AppAppearance.allCases.enumerated()), id: \.element) { index, option in
                    Button { appearanceRaw = option.rawValue } label: {
                        HStack {
                            Text(option.title).font(Theme.font(16, .heavy))
                            Spacer()
                            if appearanceRaw == option.rawValue {
                                Image(systemName: "checkmark").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.inColor)
                            }
                        }
                        .padding(16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < AppAppearance.allCases.count - 1 { Divider().overlay(Theme.surface) }
                }
            }
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
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

            VStack(alignment: .leading, spacing: 0) {
                aboutLink("envelope.fill", L10n.t("Send feedback"), URL(string: "mailto:\(LegalLinks.supportEmail)?subject=Inly%20feedback%20(\(version.replacingOccurrences(of: " ", with: "%20")))")!)
                Divider().overlay(Theme.surface)
                aboutLink("questionmark.circle.fill", L10n.t("Help"), LegalLinks.support)
                Divider().overlay(Theme.surface)
                aboutLink("hand.raised.fill", L10n.t("Privacy Policy"), LegalLinks.privacy)
                Divider().overlay(Theme.surface)
                aboutLink("doc.text.fill", L10n.t("Terms of Use"), LegalLinks.terms)
            }
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            settingsNote(L10n.t("Something wrong? Tell us before leaving a review, we read every message."))
        }
    }

    private func aboutLink(_ icon: String, _ title: String, _ url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.muted).frame(width: 28)
                Text(title).font(Theme.font(16, .heavy)).foregroundStyle(Theme.text)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.forward").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
    }
}

// MARK: Inly+

struct PlusSettingsPage: View {
    @State private var redeeming = false
    @State private var message: String?

    static func statusLine(_ store: Store) -> String {
        if store.ownsLifetime {
            return store.isFamilyShared ? L10n.t("Lifetime · shared by your family") : L10n.t("Lifetime · thank you!")
        }
        if store.trialActive, let end = store.trialEnd {
            return L10n.t("Free trial · ends %@", L10n.date(end, .dateTime.weekday(.abbreviated).month(.abbreviated).day()))
        }
        return L10n.t("Unlocked")
    }

    var body: some View {
        let store = Store.shared
        SettingsPageScroll(title: "Inly+") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 26, weight: .bold)).foregroundStyle(Theme.inColor)
                    Text("Inly+").font(Theme.font(28, .heavy))
                }
                Text(Self.statusLine(store)).font(Theme.font(15, .semibold)).foregroundStyle(Theme.muted)
                if store.trialActive && !store.ownsLifetime {
                    Button { Task { await store.buy(store.lifetime) } } label: {
                        Text(store.lifetime.map { L10n.t("Keep Inly+ forever · %@", $0.displayPrice) } ?? L10n.t("Unlock Inly+"))
                    }
                    .buttonStyle(PillButtonStyle(color: Theme.inColor, foreground: Theme.night, height: 52))
                    .padding(.top, 6)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                pageButton("sparkles", L10n.t("What's included")) { store.paywall = .general }
                Divider().overlay(Theme.surface)
                pageButton("arrow.clockwise", L10n.t("Restore purchases")) {
                    Task {
                        await store.restore()
                        message = store.isPlus ? L10n.t("Inly+ is unlocked") : L10n.t("No purchase found for this Apple ID.")
                    }
                }
                Divider().overlay(Theme.surface)
                pageButton("ticket.fill", L10n.t("Redeem code")) { redeeming = true }
            }
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            settingsNote(L10n.t("One purchase works on every iPhone signed in with your Apple ID, and for your family."))
        }
        .offerCodeRedemption(isPresented: $redeeming) { _ in Task { await store.refresh() } }
        .alert("Inly+", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(L10n.t("OK")) { message = nil }
        } message: { Text(message ?? "") }
    }

    private func pageButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.inColor).frame(width: 28)
                Text(title).font(Theme.font(16, .heavy)).foregroundStyle(Theme.text)
                Spacer(minLength: 0)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
