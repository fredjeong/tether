import Foundation
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
            let arguments = CommandLine.arguments
            if arguments.contains("-ui-testing-reset") {
                try store.resetAll()
            }
            let dayProvider: any DayProviding
            if arguments.contains("-ui-testing-seed-history") {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                let now = calendar.date(from: DateComponents(
                    year: 2026,
                    month: 8,
                    day: 17,
                    hour: 12
                ))!
                let createdAt = calendar.date(byAdding: .day, value: -3, to: now)!
                let habit = try store.loadHabit() ?? store.createHabit(
                    from: HabitDraft(
                        name: "Workout",
                        doneMeaning: "A full workout",
                        lightMeaning: "Move for 10 minutes"
                    ),
                    now: createdAt
                )
                let today = LocalDay(date: now, calendar: calendar)
                for (offset, state) in [
                    (-2, CheckInState.done),
                    (-1, CheckInState.light),
                    (0, CheckInState.rest),
                ] {
                    _ = try store.upsertCheckIn(
                        habitID: habit.id,
                        day: today.adding(days: offset, calendar: calendar),
                        state: state,
                        now: calendar.date(byAdding: .day, value: offset, to: now)!
                    )
                }
                dayProvider = FixedDayProvider(now: now, calendar: calendar)
            } else {
                dayProvider = SystemDayProvider()
            }
            if arguments.contains("-ui-testing-seed-habit"),
               try store.loadHabit() == nil {
                _ = try store.createHabit(
                    from: HabitDraft(
                        name: "Workout",
                        doneMeaning: "A full workout",
                        lightMeaning: "Move for 10 minutes"
                    ),
                    now: Date()
                )
            }
            self.container = container
            environment = AppEnvironment(
                store: store,
                dayProvider: dayProvider
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
