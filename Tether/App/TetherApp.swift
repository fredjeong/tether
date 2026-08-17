import SwiftData
import SwiftUI

@main
struct TetherApp: App {
    private let container: ModelContainer
    private let environment: AppEnvironment

    init() {
        do {
            let container = try TetherSchema.makeContainer(inMemory: false)
            let store = SwiftDataTetherStore(context: container.mainContext)
            if CommandLine.arguments.contains("-ui-testing-reset") {
                try store.resetAll()
            }
            self.container = container
            environment = AppEnvironment(
                store: store,
                dayProvider: SystemDayProvider()
            )
        } catch {
            fatalError("Unable to initialize Tether storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
                .modelContainer(container)
        }
    }
}
