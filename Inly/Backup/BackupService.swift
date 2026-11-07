import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// A backup file for `fileExporter`.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// Makes and restores backups, and optionally writes one automatically into a folder the user picked (e.g. in iCloud Drive).
@MainActor
final class BackupService {
    static let shared = BackupService()
    static let fileName = "Inly Backup.json"

    private let defaults = UserDefaults.standard
    private enum Key {
        static let bookmark = "backupFolderBookmark"
        static let folderName = "backupFolderName"
        static let lastBackup = "lastBackupDate"
    }

    private var context: ModelContext { SessionService.shared.container.mainContext }

    // MARK: Build / restore

    func makeBackup(now: Date = .now) throws -> BackupFile {
        let sessions = try context.fetch(FetchDescriptor<WearSession>(sortBy: [SortDescriptor(\.start)]))
        let trays = try context.fetch(FetchDescriptor<Tray>(sortBy: [SortDescriptor(\.number)]))
        let notes = try context.fetch(FetchDescriptor<TrayNote>(sortBy: [SortDescriptor(\.date)]))
        return BackupFile(
            createdAt: now,
            settings: .init(WearSettings.load()),
            sessions: sessions.map { .init(start: $0.start, end: $0.end, reason: $0.reasonRaw) },
            trays: trays.map { .init(number: $0.number, startDate: $0.startDate, endDate: $0.endDate, plannedDays: $0.plannedDays, photo: $0.photoData) },
            notes: notes.map { .init(trayNumber: $0.trayNumber, date: $0.date, text: $0.text) }
        )
    }

    func makeBackupData() throws -> Data { try makeBackup().encoded() }

    /// Replaces everything in the app with the contents of the backup.
    func restore(_ data: Data) throws {
        let file = try BackupFile.decode(data)
        try context.delete(model: WearSession.self)
        try context.delete(model: Tray.self)
        try context.delete(model: TrayNote.self)
        for s in file.sessions {
            context.insert(WearSession(start: s.start, end: s.end, reason: OutReason(rawValue: s.reason) ?? .other))
        }
        for t in file.trays {
            let tray = Tray(number: t.number, startDate: t.startDate, endDate: t.endDate, plannedDays: t.plannedDays)
            tray.photoData = t.photo
            context.insert(tray)
        }
        for n in file.notes {
            context.insert(TrayNote(trayNumber: n.trayNumber, text: n.text, date: n.date))
        }
        try context.save()
        file.settings.apply().save()
        SessionService.shared.ensureTray()
        SessionService.shared.commit()
        if let tray = SessionService.shared.currentTray() { TrayNotifications.scheduleSwitchReminder(for: tray) }
        TrayNotifications.schedule(WearSettings.load().nextAppointment)
    }

    // MARK: Automatic backup folder

    var folderName: String? { defaults.string(forKey: Key.folderName) }
    var lastBackup: Date? { defaults.object(forKey: Key.lastBackup) as? Date }
    var hasFolder: Bool { defaults.data(forKey: Key.bookmark) != nil }

    func setFolder(_ url: URL) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        defaults.set(bookmark, forKey: Key.bookmark)
        defaults.set(url.lastPathComponent, forKey: Key.folderName)
        try backUpNow()
    }

    func clearFolder() {
        defaults.removeObject(forKey: Key.bookmark)
        defaults.removeObject(forKey: Key.folderName)
    }

    /// Writes the backup file into the chosen folder.
    func backUpNow() throws {
        guard let bookmark = defaults.data(forKey: Key.bookmark) else { return }
        var stale = false
        let folder = try URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
        let access = folder.startAccessingSecurityScopedResource()
        defer { if access { folder.stopAccessingSecurityScopedResource() } }
        let data = try makeBackupData()
        var coordError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: folder.appending(path: Self.fileName), options: .forReplacing, error: &coordError) { url in
            do { try data.write(to: url, options: .atomic) } catch { writeError = error }
        }
        if let e = coordError ?? writeError as NSError? { throw e }
        defaults.set(Date.now, forKey: Key.lastBackup)
        if stale { defaults.removeObject(forKey: Key.bookmark) }
    }

    /// Called when the app goes to the background: backs up at most once an hour.
    func autoBackupIfDue(now: Date = .now) {
        guard hasFolder else { return }
        if let last = lastBackup, now.timeIntervalSince(last) < 3600 { return }
        try? backUpNow()
    }
}
