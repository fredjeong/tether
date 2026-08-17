import Foundation

@MainActor
struct AppEnvironment {
    let store: any TetherStore
    let dayProvider: any DayProviding
}
