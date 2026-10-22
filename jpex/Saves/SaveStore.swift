import Foundation
import Observation
import SwiftData

/// The store the person's saves are in, on this device alone or synced through iCloud, as they
/// choose in Settings. A change of choice takes effect when Settings closes, on a new store, and
/// the screens built on the old one start afresh on it.
@MainActor @Observable
final class SaveStore {
    private(set) var container: ModelContainer
    /// Whether the store in use syncs, which can differ from the choice until Settings closes.
    private(set) var isSyncing: Bool
    /// Counts each change of store, so the screens built on the last one are made anew.
    private(set) var generation = 0
    /// The store just replaced, kept a moment while the screens built on it go.
    @ObservationIgnored private var retired: ModelContainer?

    init() {
        let syncing = CloudSync.isChosen
        isSyncing = syncing
        container = CloudSync.makeModelContainer(syncing: syncing)
        CloudKeyValueMirror.shared.setActive(syncing)
    }

    /// Opens the store the person chose, if it isn't the one in use.
    func applyChoice() {
        let syncing = CloudSync.isChosen
        guard syncing != isSyncing else { return }
        isSyncing = syncing
        CloudKeyValueMirror.shared.setActive(syncing)
        retired = container
        container = CloudSync.makeModelContainer(syncing: syncing)
        generation += 1
        Task {
            try? await Task.sleep(for: .seconds(2))
            retired = nil
        }
    }
}
