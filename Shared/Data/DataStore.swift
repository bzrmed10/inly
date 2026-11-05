import Foundation
import SwiftData

enum DataStore {
    static let schema = Schema([WearSession.self, Tray.self])

    /// Shared container so the app, widgets and intents read the same store.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        do {
            let config: ModelConfiguration
            if inMemory {
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
            fatalError("Could not create the data store: \(error)")
        }
    }
}
