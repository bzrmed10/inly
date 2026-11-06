import Foundation
import SwiftData

enum DataStore {
    static let schema = Schema([WearSession.self, Tray.self])

    /// Shared container so the app, widgets and intents read the same store.
    /// Crashes only if the store can never be opened (app); widgets use `makeContainerIfPossible`.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        guard let container = makeContainerIfPossible(inMemory: inMemory, attempts: 5) else {
            fatalError("Could not create the data store")
        }
        return container
    }

    /// Tries a few times (the app may be writing the file at that very moment) and returns nil instead of crashing.
    static func makeContainerIfPossible(inMemory: Bool = false, attempts: Int = 3) -> ModelContainer? {
        for attempt in 0..<max(1, attempts) {
            if let c = openContainer(inMemory: inMemory) { return c }
            if attempt < attempts - 1 { Thread.sleep(forTimeInterval: 0.25) }
        }
        return nil
    }

    private static func openContainer(inMemory: Bool) -> ModelContainer? {
        do {
            let config: ModelConfiguration
            if inMemory || DemoData.isEnabled || DemoData.isFresh {
                config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            } else if let dir = AppGroup.containerURL {
                config = ModelConfiguration(
                    schema: schema,
                    url: dir.appending(path: "Inly.store"),
                    cloudKitDatabase: .none
                )
            } else {
                config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            }
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            return nil
        }
    }
}
