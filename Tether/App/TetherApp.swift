import SwiftData
import SwiftUI

@main
struct TetherApp: App {
    private let container: ModelContainer
    private let store: SwiftDataTetherStore

    init() {
        do {
            let container = try TetherSchema.makeContainer(inMemory: false)
            self.container = container
            store = SwiftDataTetherStore(context: container.mainContext)
        } catch {
            fatalError("Unable to initialize Tether storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
