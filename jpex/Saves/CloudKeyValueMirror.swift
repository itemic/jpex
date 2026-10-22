import Foundation

/// Carries a few things the person made that are kept in UserDefaults, such as their groups of
/// countries, to their other devices through iCloud's key-value store, and brings back changes
/// made there. UserDefaults stays where the app reads them from; this only copies changes across.
/// Carries nothing until the person turns iCloud sync on. Used from the main thread.
final class CloudKeyValueMirror {
    static let shared = CloudKeyValueMirror()

    /// How a value from iCloud is taken in.
    enum Arrival {
        /// A change made on another device, which replaces this one's.
        case replacing
        /// iCloud's copy reaching this device for the first time, or another iCloud account's,
        /// which joins what's here, so nothing made on this device before is lost.
        case joining
    }

    /// A value carried across: this device's copy as it is now, and where iCloud's goes.
    private struct Mirrored {
        var local: () -> Data?
        var receive: (Data, Arrival) -> Void
    }

    /// Touched only once sync is on, so a device that never syncs never reaches iCloud.
    private lazy var store = NSUbiquitousKeyValueStore.default
    private var mirrored: [String: Mirrored] = [:]
    private var observer: (any NSObjectProtocol)?
    /// Whether values are being carried across now.
    private(set) var isActive = false

    private init() {}

    /// Starts carrying a value saved under this key, once sync is on: takes in iCloud's copy if it
    /// differs from this device's, and each change from another device as it comes. A value iCloud
    /// doesn't have yet goes up from here.
    func mirror(_ key: String, local: @escaping () -> Data?, receive: @escaping (Data, Arrival) -> Void) {
        mirrored[key] = Mirrored(local: local, receive: receive)
        if isActive { join(key) }
    }

    /// Starts or stops carrying values across, as the person turns iCloud sync on or off.
    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        if active {
            observer = NotificationCenter.default.addObserver(
                forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store, queue: .main
            ) { [weak self] notification in
                let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
                let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
                self?.receive(keys, reason: reason)
            }
            store.synchronize()
            for key in mirrored.keys { join(key) }
        } else {
            if let observer { NotificationCenter.default.removeObserver(observer) }
            observer = nil
            // Changes made here while sync is off join iCloud's when it's turned on again, rather
            // than being replaced by them.
            for key in mirrored.keys { UserDefaults.standard.removeObject(forKey: Self.joinedKey(for: key)) }
        }
    }

    /// Sends a change made here to the person's other devices, while sync is on.
    func upload(_ data: Data, for key: String) {
        guard isActive, store.data(forKey: key) != data else { return }
        store.set(data, forKey: key)
    }

    private func join(_ key: String) {
        guard let value = mirrored[key] else { return }
        let defaults = UserDefaults.standard
        // Whether this device's value has met iCloud's before; until then, they join.
        let joinedKey = Self.joinedKey(for: key)
        let local = value.local()
        if let cloud = store.data(forKey: key) {
            if cloud != local { value.receive(cloud, defaults.bool(forKey: joinedKey) ? .replacing : .joining) }
        } else if let local {
            store.set(local, forKey: key)
        }
        defaults.set(true, forKey: joinedKey)
    }

    private static func joinedKey(for key: String) -> String {
        CloudSync.recordKeyPrefix + "joined." + key
    }

    private func receive(_ keys: [String], reason: Int?) {
        let arrival: Arrival
        switch reason {
        case NSUbiquitousKeyValueStoreServerChange: arrival = .replacing
        case NSUbiquitousKeyValueStoreInitialSyncChange, NSUbiquitousKeyValueStoreAccountChange: arrival = .joining
        default: return
        }
        for key in keys {
            guard let value = mirrored[key], let data = store.data(forKey: key) else { continue }
            value.receive(data, arrival)
        }
    }
}
