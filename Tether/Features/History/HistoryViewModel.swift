import Observation

@MainActor
@Observable
final class HistoryViewModel {
    private(set) var summary = HistorySummary(
        current: 0,
        best: 0,
        doneCount: 0,
        lightCount: 0,
        restCount: 0,
        days: []
    )
    private(set) var errorMessage: String?

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func load() {
        refresh()
    }

    func refresh() {
        do {
            guard let habit = try environment.store.loadHabit() else {
                summary = Self.emptySummary
                errorMessage = nil
                return
            }

            let checkIns = try environment.store.loadCheckIns(habitID: habit.id)
            let calendar = environment.dayProvider.calendar
            summary = HistoryBuilder.build(
                habit: habit,
                checkIns: checkIns,
                today: LocalDay(date: environment.dayProvider.now, calendar: calendar),
                calendar: calendar,
                limit: 30
            )
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your history. Please try again."
        }
    }

    private static let emptySummary = HistorySummary(
        current: 0,
        best: 0,
        doneCount: 0,
        lightCount: 0,
        restCount: 0,
        days: []
    )
}
