import Foundation

/// iCloud sync (Inly+): a compact copy of everything except photos lives in the user's own iCloud
/// key-value store, so a new iPhone (same Apple ID) gets the history back and two iPhones stay in step.
/// No Inly server is involved. The newest change wins.
@MainActor
final class CloudSync {
    static let shared = CloudSync()

    enum Status: Equatable { case off, upToDate(Date), tooLarge, unavailable }

    private let cloud = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private enum Key {
        static let data = "inly.sync.data"
        static let modified = "inly.sync.modified"
        static let device = "inly.sync.device"
        static let enabled = "cloudSyncEnabled"
        static let deviceID = "cloudSyncDeviceID"
        static let lastApplied = "cloudSyncLastApplied"
        static let lastSync = "cloudSyncLastSync"
    }
    /// The key-value store holds 1 MB in total; stay well under it.
    static let maxBytes = 900_000

    private var pushTask: Task<Void, Never>?
    private(set) var tooLarge = false
    private var applying = false

    private init() {}

    // MARK: State

    var wantsSync: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }
    var isOn: Bool { wantsSync && PlusStatus.isActive }
    var lastSync: Date? { defaults.object(forKey: Key.lastSync) as? Date }
    var iCloudAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

    var status: Status {
        guard isOn else { return .off }
        if !iCloudAvailable { return .unavailable }
        if tooLarge { return .tooLarge }
        return lastSync.map { .upToDate($0) } ?? .upToDate(.now)
    }

    private var deviceID: String {
        if let id = defaults.string(forKey: Key.deviceID) { return id }
        let id = UUID().uuidString
        defaults.set(id, forKey: Key.deviceID)
        return id
    }

    private var lastApplied: Double {
        get { defaults.double(forKey: Key.lastApplied) }
        set { defaults.set(newValue, forKey: Key.lastApplied) }
    }

    struct Remote {
        let file: BackupFile
        let modified: Date
        let fromThisDevice: Bool
    }

    /// What iCloud holds right now, if anything.
    func remote() -> Remote? {
        guard let packed = cloud.data(forKey: Key.data),
              let raw = try? (packed as NSData).decompressed(using: .lzfse) as Data,
              let file = try? BackupFile.decode(raw) else { return nil }
        let modified = Date(timeIntervalSince1970: cloud.double(forKey: Key.modified))
        return Remote(file: file, modified: modified, fromThisDevice: cloud.string(forKey: Key.device) == deviceID)
    }

    // MARK: Life cycle

    func start() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: .main
        ) { _ in
            Task { @MainActor in CloudSync.shared.pullIfNewer() }
        }
        cloud.synchronize()
        SessionService.shared.didSave = { CloudSync.shared.pushSoon() }
        pullIfNewer()
    }

    /// Turn sync on. Returns the iCloud copy from another iPhone when there is one, so the caller can ask which to keep.
    func enable() -> Remote? {
        wantsSync = true
        cloud.synchronize()
        if let r = remote(), !r.fromThisDevice, r.modified.timeIntervalSince1970 > lastApplied { return r }
        push()
        return nil
    }

    func disable() {
        wantsSync = false
        pushTask?.cancel()
    }

    /// After buying Inly+: nothing to do unless the user already asked for sync.
    func plusDidUnlock() {
        if wantsSync { push() }
    }

    // MARK: Push / pull

    func pushSoon() {
        guard isOn, !applying else { return }
        pushTask?.cancel()
        pushTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            CloudSync.shared.push()
        }
    }

    func push() {
        guard isOn, !applying else { return }
        guard let file = try? BackupService.shared.makeBackup(includePhotos: false),
              let raw = try? file.encoded(),
              let packed = try? (raw as NSData).compressed(using: .lzfse) as Data else { return }
        guard packed.count < Self.maxBytes else { tooLarge = true; return }
        tooLarge = false
        let now = Date.now
        cloud.set(packed, forKey: Key.data)
        cloud.set(now.timeIntervalSince1970, forKey: Key.modified)
        cloud.set(deviceID, forKey: Key.device)
        cloud.synchronize()
        lastApplied = now.timeIntervalSince1970
        defaults.set(now, forKey: Key.lastSync)
    }

    /// Applies the iCloud copy when another iPhone changed it after our last sync.
    func pullIfNewer() {
        guard isOn, let r = remote(), !r.fromThisDevice, r.modified.timeIntervalSince1970 > lastApplied + 1 else { return }
        apply(r)
    }

    /// Replaces local data with the iCloud copy (photos on this iPhone are kept).
    func apply(_ r: Remote) {
        applying = true
        defer { applying = false }
        try? BackupService.shared.restore(file: r.file, keepPhotos: true)
        lastApplied = r.modified.timeIntervalSince1970
        defaults.set(Date.now, forKey: Key.lastSync)
    }

    /// Keep this iPhone's data and overwrite iCloud with it.
    func keepLocal() {
        push()
    }
}
