import Foundation
import Testing
@testable import Tether

@MainActor
struct TodayViewModelTests {
    @Test
    func noRecordsShowsStartWithZeroCurrentDays() throws {
        let fixture = try TodayFixture()
        let viewModel = fixture.makeViewModel()

        viewModel.load()

        #expect(viewModel.habit == fixture.habit)
        #expect(viewModel.selectedState == nil)
        #expect(viewModel.snapshot.current == 0)
        #expect(viewModel.snapshot.phase == .start)
        #expect(viewModel.statusHeadline == "Start your tether today")
    }

    @Test
    func selectingDonePersistsTodayAndRecomputesCurrentDays() throws {
        let fixture = try TodayFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()

        viewModel.select(.done)

        let records = try fixture.store.loadCheckIns(habitID: fixture.habit.id)
        #expect(records.count == 1)
        #expect(records.first?.day == fixture.today)
        #expect(records.first?.state == .done)
        #expect(viewModel.selectedState == .done)
        #expect(viewModel.snapshot.current == 1)
        #expect(viewModel.snapshot.isCheckedInToday)
    }

    @Test(arguments: [CheckInState.light, CheckInState.rest])
    func selectingAnIntentionalAlternativeMaintainsTheConnection(
        state: CheckInState
    ) throws {
        let fixture = try TodayFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()

        viewModel.select(state)

        #expect(viewModel.selectedState == state)
        #expect(viewModel.snapshot.current == 1)
        #expect(viewModel.snapshot.phase == .active)
    }

    @Test
    func selectingASecondStateUpdatesTodayWithoutDuplication() throws {
        let fixture = try TodayFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()

        viewModel.select(.done)
        viewModel.select(.rest)

        let records = try fixture.store.loadCheckIns(habitID: fixture.habit.id)
        #expect(records.count == 1)
        #expect(records.first?.state == .rest)
        #expect(viewModel.selectedState == .rest)
        #expect(viewModel.snapshot.current == 1)
    }

    @Test
    func yesterdayCheckInPreservesCurrentWhileTodayIsPending() throws {
        let fixture = try TodayFixture()
        try fixture.seedCheckIn(dayOffset: -1, state: .light)
        let viewModel = fixture.makeViewModel()

        viewModel.load()

        #expect(viewModel.selectedState == nil)
        #expect(viewModel.snapshot.current == 1)
        #expect(viewModel.snapshot.phase == .active)
        #expect(!viewModel.snapshot.isCheckedInToday)
        #expect(viewModel.statusHeadline == "1 day tethered")
    }

    @Test
    func anOlderCheckInSeparatedByAMissedDayShowsReconnect() throws {
        let fixture = try TodayFixture()
        try fixture.seedCheckIn(dayOffset: -2, state: .done)
        let viewModel = fixture.makeViewModel()

        viewModel.load()

        #expect(viewModel.selectedState == nil)
        #expect(viewModel.snapshot.current == 0)
        #expect(viewModel.snapshot.best == 1)
        #expect(viewModel.snapshot.phase == .reconnect)
        #expect(viewModel.statusHeadline == "Reconnect today")
    }

    @Test
    func storeFailureDoesNotShowAnUnpersistedSuccess() throws {
        let fixture = try TodayFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()
        fixture.store.upsertError = .unavailable

        viewModel.select(.done)

        #expect(try fixture.store.loadCheckIns(habitID: fixture.habit.id).isEmpty)
        #expect(viewModel.selectedState == nil)
        #expect(viewModel.snapshot.current == 0)
        #expect(!viewModel.snapshot.isCheckedInToday)
        #expect(viewModel.errorMessage == "Couldn't save your check-in. Please try again.")
    }
}

@MainActor
private final class TodayFixture {
    let calendar: Calendar
    let now: Date
    let today: LocalDay
    let store: TodayInMemoryStore
    let environment: AppEnvironment
    let habit: Habit

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let now = try #require(
            calendar.date(from: DateComponents(
                year: 2026,
                month: 8,
                day: 17,
                hour: 9
            ))
        )
        let store = TodayInMemoryStore()
        let habit = try store.createHabit(
            from: HabitDraft(
                name: "Workout",
                doneMeaning: "A full workout",
                lightMeaning: "Move for 10 minutes"
            ),
            now: now.addingTimeInterval(-3 * 86_400)
        )

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

    func makeViewModel() -> TodayViewModel {
        TodayViewModel(environment: environment)
    }

    func seedCheckIn(dayOffset: Int, state: CheckInState) throws {
        _ = try store.upsertCheckIn(
            habitID: habit.id,
            day: today.adding(days: dayOffset, calendar: calendar),
            state: state,
            now: now.addingTimeInterval(TimeInterval(dayOffset * 86_400))
        )
    }
}

@MainActor
private final class TodayInMemoryStore: TetherStore {
    enum StorageError: Error {
        case unavailable
    }

    private var habit: Habit?
    private var checkIns: [DailyCheckIn] = []
    var upsertError: StorageError?

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
        checkIns.filter { $0.habitID == habitID }
    }

    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn {
        if let upsertError {
            throw upsertError
        }
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

    func resetAll() throws {
        habit = nil
        checkIns = []
    }
}
