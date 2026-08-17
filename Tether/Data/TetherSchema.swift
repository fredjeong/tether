import SwiftData

enum TetherSchema {
    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            HabitModel.self,
            DailyCheckInModel.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
