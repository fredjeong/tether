import Foundation
import Testing
@testable import Tether

@MainActor
struct HistoryViewModelTests {
    @Test
    func loadBuildsSummaryFromPersistedHabitAndCheckIns() throws {
        let fixture = try HistoryViewModelFixture()
        try fixture.seed(dayOffset: -2, state: .done)
        try fixture.seed(dayOffset: -1, state: .light)
        try fixture.seed(dayOffset: 0, state: .rest)
        let viewModel = fixture.makeViewModel()

        viewModel.load()

        #expect(viewModel.summary.current == 3)
        #expect(viewModel.summary.best == 3)
        #expect(viewModel.summary.doneCount == 1)
        #expect(viewModel.summary.lightCount == 1)
        #expect(viewModel.summary.restCount == 1)
        #expect(viewModel.summary.days.first == HistoryDay(day: fixture.today, state: .rest))
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func loadWithoutAHabitUsesAnEmptySummary() throws {
        let fixture = try HistoryViewModelFixture(createHabit: false)
        let viewModel = fixture.makeViewModel()

        viewModel.load()

        #expect(viewModel.summary == HistorySummary(
            current: 0,
            best: 0,
            doneCount: 0,
            lightCount: 0,
            restCount: 0,
            days: []
        ))
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func refreshRebuildsHistoryAfterPersistedDataChanges() throws {
        let fixture = try HistoryViewModelFixture()
        try fixture.seed(dayOffset: -1, state: .done)
        let viewModel = fixture.makeViewModel()
        viewModel.load()

        try fixture.seed(dayOffset: 0, state: .light)
        viewModel.refresh()

        #expect(viewModel.summary.current == 2)
        #expect(viewModel.summary.doneCount == 1)
        #expect(viewModel.summary.lightCount == 1)
        #expect(viewModel.summary.days.first?.state == .light)
    }

    @Test
    func loadFailureReportsAnErrorWithoutInventingHistory() throws {
        let fixture = try HistoryViewModelFixture()
        fixture.store.loadCheckInsError = .unavailable
        let viewModel = fixture.makeViewModel()

        viewModel.load()

        #expect(viewModel.summary.days.isEmpty)
        #expect(viewModel.summary.current == 0)
        #expect(viewModel.summary.best == 0)
        #expect(viewModel.errorMessage == "Couldn't load your history. Please try again.")
    }
}

@MainActor
private final class HistoryViewModelFixture {
    let calendar: Calendar
    let now: Date
    let today: LocalDay
    let store: HistoryInMemoryStore
    let environment: AppEnvironment
    let habit: Habit?

    init(createHabit: Bool = true) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: 9
        )))
        let store = HistoryInMemoryStore()
        let habit: Habit?
        if createHabit {
            habit = try store.createHabit(
                from: HabitDraft(
                    name: "Workout",
                    doneMeaning: "A full workout",
                    lightMeaning: "Move for 10 minutes"
                ),
                now: now.addingTimeInterval(-2 * 86_400)
            )
        } else {
            habit = nil
        }

        self.calendar = calendar
        self.now = now
        today = LocalDay(date: now, calendar: calendar)
        self.store = store
        self.habit = habit
        environment = AppEnvironment(
            store: store,
            dayProvider: FixedDayProvider(now: now, calendar: calendar)
        )
    }

    func makeViewModel() -> HistoryViewModel {
        HistoryViewModel(environment: environment)
    }

    func seed(dayOffset: Int, state: CheckInState) throws {
        let habit = try #require(habit)
        _ = try store.upsertCheckIn(
            habitID: habit.id,
            day: today.adding(days: dayOffset, calendar: calendar),
            state: state,
            now: now.addingTimeInterval(TimeInterval(dayOffset * 86_400))
        )
    }
}

@MainActor
private final class HistoryInMemoryStore: TetherStore {
    enum StorageError: Error {
        case unavailable
    }

    private var habit: Habit?
    private var checkIns: [DailyCheckIn] = []
    var loadCheckInsError: StorageError?

    func loadHabit() throws -> Habit? {
        habit
    }

    func createHabit(from draft: HabitDraft, now: Date) throws -> Habit {
        guard habit == nil else {
            throw TetherStoreError.habitAlreadyExists
        }
        let validated = try draft.validated()
        let created = Habit(
            id: UUID(),
            name: validated.name,
            doneMeaning: validated.doneMeaning,
            lightMeaning: validated.lightMeaning,
            createdAt: now,
            updatedAt: now
        )
        habit = created
        return created
    }

    func updateHabit(id: UUID, from draft: HabitDraft, now: Date) throws -> Habit {
        guard let current = habit, current.id == id else {
            throw TetherStoreError.habitNotFound
        }
        let validated = try draft.validated()
        let updated = Habit(
            id: current.id,
            name: validated.name,
            doneMeaning: validated.doneMeaning,
            lightMeaning: validated.lightMeaning,
            createdAt: current.createdAt,
            updatedAt: now
        )
        habit = updated
        return updated
    }

    func loadCheckIns(habitID: UUID) throws -> [DailyCheckIn] {
        if let loadCheckInsError {
            throw loadCheckInsError
        }
        return checkIns.filter { $0.habitID == habitID }
    }

    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn {
        guard habit?.id == habitID else {
            throw TetherStoreError.habitNotFound
        }

        if let index = checkIns.firstIndex(where: {
            $0.habitID == habitID && $0.day == day
        }) {
            checkIns[index].state = state
            checkIns[index].updatedAt = now
            return checkIns[index]
        }

        let created = DailyCheckIn(
            id: UUID(),
            habitID: habitID,
            day: day,
            state: state,
            createdAt: now,
            updatedAt: now
        )
        checkIns.append(created)
        return created
    }

    func deleteCheckIn(habitID: UUID, day: LocalDay) throws {
        guard habit?.id == habitID else {
            throw TetherStoreError.habitNotFound
        }
        checkIns.removeAll { $0.habitID == habitID && $0.day == day }
    }

    func resetAll() throws {
        habit = nil
        checkIns = []
    }
}
