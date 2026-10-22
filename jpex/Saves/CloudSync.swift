import CoreData
import Foundation
import SwiftData

/// The person's saves, kept in their own private iCloud database once they turn sync on, so each
/// of their devices shows the same places, levels and history.
enum CloudSync {
    /// The app's iCloud container, as named in its entitlements.
    static let containerID = "iCloud.itemic.jpex"

    /// Whether the person has chosen to sync through iCloud. Off until they turn it on, and kept
    /// through Reset Everything, so a reset still reaches their other devices.
    static let choiceKey = "syncsWithICloud"

    static var isChosen: Bool {
        UserDefaults.standard.bool(forKey: choiceKey)
    }

    /// Saved values that record what's already happened with iCloud on this device, all starting
    /// with this, so Reset Everything keeps them as it keeps the app's other one-time updates.
    static let recordKeyPrefix = "iCloud."

    private static let savesHaveIDsKey = recordKeyPrefix + "savesHaveIDs"

    /// The store, on this device alone or synced through iCloud. If iCloud's part can't be set up,
    /// the store opens on this device alone, so the app still opens with everything saved.
    static func makeModelContainer(syncing: Bool) -> ModelContainer {
        giveOlderSavesIDs()
        guard syncing else {
            do {
                return try ModelContainer(for: SaveModel.self, configurations: ModelConfiguration(cloudKitDatabase: .none))
            } catch {
                fatalError("The saved places couldn't be opened: \(error)")
            }
        }
        #if DEBUG
        // Away from launch: checking for an iCloud account can take a while, such as in a
        // Simulator that isn't signed in.
        Task.detached(priority: .utility) { initializeDevelopmentSchema() }
        #endif
        do {
            return try ModelContainer(
                for: SaveModel.self, configurations: ModelConfiguration(cloudKitDatabase: .private(containerID)))
        } catch {
            do {
                return try ModelContainer(for: SaveModel.self, configurations: ModelConfiguration(cloudKitDatabase: .none))
            } catch {
                fatalError("The saved places couldn't be opened: \(error)")
            }
        }
    }

    /// Gives saves from before iCloud sync an ID while the store is still this device's alone, so
    /// every save that reaches iCloud already has one, and every device keeps the same save. Once.
    private static func giveOlderSavesIDs() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: savesHaveIDsKey) else { return }
        do {
            let container = try ModelContainer(for: SaveModel.self, configurations: ModelConfiguration(cloudKitDatabase: .none))
            let context = ModelContext(container)
            for save in try context.fetch(FetchDescriptor<SaveModel>()) where save.saveID == nil {
                save.saveID = UUID()
            }
            if context.hasChanges { try context.save() }
            defaults.set(true, forKey: savesHaveIDsKey)
        } catch {
            // Tried again at the next launch, before iCloud starts.
        }
    }

    #if DEBUG
    /// Development builds tell iCloud's development environment about every field of the saves,
    /// once for each shape of them, so fields still empty in testing, such as custom levels, are in
    /// the schema deployed to production. Uses a store of its own, so the person's saves aren't
    /// touched. iCloud briefly holds a placeholder save while it does; the app never keeps one it
    /// can't read. Needs an iCloud account; without one it's tried again at the next launch.
    private static func initializeDevelopmentSchema() {
        let defaults = UserDefaults.standard
        let key = recordKeyPrefix + "developmentSchema"
        guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [SaveModel.self]),
              defaults.string(forKey: key) != model.versionChecksum else { return }
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appending(path: "CloudKitSchema-\(UUID().uuidString)")
        defer { try? fileManager.removeItem(at: directory) }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let description = NSPersistentStoreDescription(url: directory.appending(path: "Schema.store"))
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerID)
            description.shouldAddStoreAsynchronously = false
            let container = NSPersistentCloudKitContainer(name: "Schema", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            var loadError: (any Error)?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError { throw loadError }
            defer {
                for store in container.persistentStoreCoordinator.persistentStores {
                    try? container.persistentStoreCoordinator.remove(store)
                }
            }
            try container.initializeCloudKitSchema()
            defaults.set(model.versionChecksum, forKey: key)
        } catch {
            print("The CloudKit development schema wasn't initialized: \(error)")
        }
    }
    #endif
}
