import Foundation
import os
import Testing
@testable import Tether

@MainActor
struct LifecycleRegressionTests {
    @Test
    func refreshAfterMidnightReloadsTodayHistoryAndTheRollingReminderSchedule() async throws {
        let fixture = try LifecycleFixture(
            now: .date(year: 2026, month: 8, day: 17, hour: 23, minute: 59),
            reminderSettings: .init(isEnabled: true, hour: 20, minute: 0)
        )
        try fixture.seedCheckIn(dayOffset: 0, state: .done)
        let appModel = AppModel(environment: fixture.environment)
        let today = TodayViewModel(environment: fixture.environment)
        let history = HistoryViewModel(environment: fixture.environment)
        try appModel.load()
        today.load()
        history.load()
        let checkInLoadsBeforeRefresh = fixture.store.loadCheckInsCallCount

        let nextDay = try fixture.date(year: 2026, month: 8, day: 18, hour: 0, minute: 1)
        fixture.dayProvider.update(now: nextDay, calendar: fixture.calendar)

        await appModel.refreshForCurrentDay()
        today.refresh()
        history.load()

        let expectedToday = LocalDay(era: 1, year: 2026, month: 8, day: 18)
        #expect(appModel.lifecycleRefreshID == 1)
        #expect(fixture.store.loadCheckInsCallCount == checkInLoadsBeforeRefresh + 3)
        #expect(today.selectedState == nil)
        #expect(today.snapshot == TetherSnapshot(
            current: 1,
            best: 1,
            phase: .active,
            isCheckedInToday: false
        ))
        #expect(today.statusHeadline == "1 day tethered")
        #expect(today.supportingCopy == "You haven't checked in today.")
        #expect(history.summary.days.first == HistoryDay(day: expectedToday, state: nil))
        #expect(fixture.scheduler.reconcileCalls == [
            .init(
                settings: .init(isEnabled: true, hour: 20, minute: 0),
                now: nextDay,
                calendar: fixture.calendar,
                checkedDays: [LocalDay(era: 1, year: 2026, month: 8, day: 17)]
            )
        ])
    }

    @Test
    func foregroundRefreshAfterAMissedDayChangesActivePendingToReconnect() async throws {
        let fixture = try LifecycleFixture(
            now: .date(year: 2026, month: 8, day: 17, hour: 9, minute: 0)
        )
        try fixture.seedCheckIn(dayOffset: -1, state: .light)
        let appModel = AppModel(environment: fixture.environment)
        let today = TodayViewModel(environment: fixture.environment)
        try appModel.load()
        today.load()
        #expect(today.snapshot.phase == .active)
        #expect(today.snapshot.current == 1)

        fixture.dayProvider.update(
            now: try fixture.date(year: 2026, month: 8, day: 18, hour: 9, minute: 0),
            calendar: fixture.calendar
        )
        await appModel.refreshForCurrentDay()
        today.refresh()

        #expect(today.selectedState == nil)
        #expect(today.snapshot == TetherSnapshot(
            current: 0,
            best: 1,
            phase: .reconnect,
            isCheckedInToday: false
        ))
        #expect(today.statusHeadline == "Reconnect today")
        #expect(today.supportingCopy == "The connection ended, but your habit is still here.")
    }

    @Test
    func concurrentRefreshRequestsCoalesceAndFinishWithTheNewestDay() async throws {
        let fixture = try LifecycleFixture(
            now: .date(year: 2026, month: 8, day: 17, hour: 23, minute: 59),
            reminderSettings: .init(isEnabled: true, hour: 20, minute: 0)
        )
        let scheduler = SuspendingReminderScheduler()
        let environment = AppEnvironment(
            store: fixture.store,
            dayProvider: fixture.dayProvider,
            reminderScheduler: scheduler,
            reminderSettingsStore: fixture.settingsStore
        )
        let appModel = AppModel(environment: environment)

        let firstRefresh = Task { @MainActor in
            await appModel.refreshForCurrentDay()
        }
        await scheduler.waitForReconcileCall(1)
        let nextDay = try fixture.date(year: 2026, month: 8, day: 18, hour: 0, minute: 1)
        fixture.dayProvider.update(now: nextDay, calendar: fixture.calendar)
        let secondRefresh = Task { @MainActor in
            await appModel.refreshForCurrentDay()
        }
        await secondRefresh.value

        scheduler.resumeNextReconcile()
        await scheduler.waitForReconcileCall(2)
        scheduler.resumeNextReconcile()
        await firstRefresh.value

        #expect(appModel.lifecycleRefreshID == 2)
        #expect(scheduler.reconcileCalls.count == 2)
        #expect(scheduler.reconcileCalls.last?.now == nextDay)
    }

    @Test
    func aTimeZoneChangeCreatesOnlyNewLocalDayValues() async throws {
        var seoul = Calendar(identifier: .gregorian)
        seoul.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let instant = Date(timeIntervalSince1970: 1_786_982_400)
        let fixture = try LifecycleFixture(now: instant, calendar: seoul)
        let storedDay = LocalDay(date: instant, calendar: seoul)
        try fixture.seedCheckIn(day: storedDay, state: .done)
        let today = TodayViewModel(environment: fixture.environment)
        today.load()

        fixture.dayProvider.update(now: instant, calendar: losAngeles)
        await AppModel(environment: fixture.environment).refreshForCurrentDay()
        today.select(.rest)

        let records = try fixture.store.loadCheckIns(habitID: fixture.habit.id)
        #expect(records.map(\.day).contains(storedDay))
        #expect(records.map(\.day).contains(LocalDay(era: 1, year: 2026, month: 8, day: 17)))
        #expect(storedDay == LocalDay(era: 1, year: 2026, month: 8, day: 18))
    }

    @Test
    func lifecycleStoreFailureKeepsReminderErrorSeparateFromPersistenceError() async throws {
        let fixture = try LifecycleFixture(
            now: .date(year: 2026, month: 8, day: 17, hour: 9, minute: 0),
            reminderSettings: .init(isEnabled: true, hour: 20, minute: 0),
            schedulerError: LifecycleError.unavailable
        )
        let appModel = AppModel(environment: fixture.environment)
        try appModel.load()

        await appModel.refreshForCurrentDay()
        fixture.store.loadCheckInsError = LifecycleError.unavailable
        await appModel.refreshForCurrentDay()

        #expect(appModel.reminderErrorMessage == "Couldn't update your reminder. Please try again.")
        #expect(appModel.persistenceErrorMessage == "Couldn't load today's check-in. Please try again.")
        #expect(appModel.lifecycleRefreshID == 2)
        #expect(fixture.scheduler.reconcileCalls.count == 1)
    }

    @Test
    func checkInSaveFailureKeepsThePersistedSnapshotAndReminderFailureDoesNotRollback() async throws {
        let fixture = try LifecycleFixture(
            now: .date(year: 2026, month: 8, day: 17, hour: 9, minute: 0),
            reminderSettings: .init(isEnabled: true, hour: 20, minute: 0),
            schedulerError: LifecycleError.unavailable
        )
        let today = TodayViewModel(environment: fixture.environment)
        today.load()
        fixture.store.upsertError = LifecycleError.unavailable

        today.select(.done)

        #expect(try fixture.store.loadCheckIns(habitID: fixture.habit.id).isEmpty)
        #expect(today.selectedState == nil)
        #expect(today.snapshot.current == 0)
        #expect(today.errorMessage == "Couldn't save your check-in. Please try again.")

        fixture.store.upsertError = nil
        await today.selectAndReconcile(.rest)

        #expect(try fixture.store.loadCheckIns(habitID: fixture.habit.id).map(\.state) == [.rest])
        #expect(today.selectedState == .rest)
        #expect(today.snapshot.isCheckedInToday)
        #expect(today.errorMessage == "Couldn't update your reminder. Please try again.")
    }

    @Test
    func disabledReminderNeverShowsASchedulingFailure() async throws {
        let fixture = try LifecycleFixture(
            now: .date(year: 2026, month: 8, day: 17, hour: 9, minute: 0),
            schedulerError: LifecycleError.unavailable
        )
        let today = TodayViewModel(environment: fixture.environment)
        today.load()

        await today.selectAndReconcile(.done)

        #expect(today.selectedState == .done)
        #expect(today.errorMessage == nil)
        #expect(fixture.scheduler.reconcileCalls.isEmpty)
    }

    @Test
    func failedResetDoesNotChangeReminderSettingsCancelOrRoute() async throws {
        let initialSettings = ReminderSettings(isEnabled: true, hour: 8, minute: 30)
        let fixture = try LifecycleFixture(
            now: .date(year: 2026, month: 8, day: 17, hour: 9, minute: 0),
            reminderSettings: initialSettings
        )
        let appModel = AppModel(environment: fixture.environment)
        try appModel.load()
        var didReset = false
        let settings = SettingsViewModel(
            environment: fixture.environment,
            onHabitSaved: { _ in },
            onReset: { didReset = true },
            version: "0.1",
            build: "1"
        )
        settings.load()
        fixture.store.resetError = LifecycleError.unavailable

        let didSucceed = await settings.resetAllAndCancelReminders()

        #expect(!didSucceed)
        #expect(fixture.settingsStore.load() == initialSettings)
        #expect(fixture.settingsStore.resetCallCount == 0)
        #expect(fixture.scheduler.cancelAllCallCount == 0)
        #expect(!didReset)
        #expect(appModel.rootContent == .main)
        #expect(settings.name == fixture.habit.name)
    }
}

private enum LifecycleError: Error {
    case unavailable
}

private extension Date {
    static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}

@MainActor
private final class LifecycleFixture {
    let calendar: Calendar
    let dayProvider: MutableDayProvider
    let store: LifecycleStore
    let scheduler: FakeReminderScheduler
    let settingsStore: LifecycleSettingsStore
    let environment: AppEnvironment
    let habit: Habit

    init(
        now: Date,
        calendar: Calendar? = nil,
        reminderSettings: ReminderSettings = .defaultValue,
        schedulerError: (any Error)? = nil
    ) throws {
        var resolvedCalendar = calendar ?? Calendar(identifier: .gregorian)
        if calendar == nil {
            resolvedCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        }
        let store = LifecycleStore()
        let habit = Habit(
            id: UUID(),
            name: "Workout",
            doneMeaning: "A full workout",
            lightMeaning: "Move for 10 minutes",
            createdAt: now.addingTimeInterval(-2 * 86_400),
            updatedAt: now.addingTimeInterval(-2 * 86_400)
        )
        store.habit = habit
        let dayProvider = MutableDayProvider(now: now, calendar: resolvedCalendar)
        let scheduler = FakeReminderScheduler(reconcileError: schedulerError)
        let settingsStore = LifecycleSettingsStore(value: reminderSettings)

        self.calendar = resolvedCalendar
        self.dayProvider = dayProvider
        self.store = store
        self.scheduler = scheduler
        self.settingsStore = settingsStore
        environment = AppEnvironment(
            store: store,
            dayProvider: dayProvider,
            reminderScheduler: scheduler,
            reminderSettingsStore: settingsStore
        )
        self.habit = habit
    }

    func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )))
    }

    func seedCheckIn(dayOffset: Int, state: CheckInState) throws {
        let day = LocalDay(date: dayProvider.now, calendar: dayProvider.calendar)
            .adding(days: dayOffset, calendar: dayProvider.calendar)
        try seedCheckIn(day: day, state: state)
    }

    func seedCheckIn(day: LocalDay, state: CheckInState) throws {
        _ = try store.upsertCheckIn(
            habitID: habit.id,
            day: day,
            state: state,
            now: dayProvider.now
        )
    }
}

private final class MutableDayProvider: DayProviding {
    private struct State {
        var now: Date
        var calendar: Calendar
    }

    private let state: OSAllocatedUnfairLock<State>

    init(now: Date, calendar: Calendar) {
        state = OSAllocatedUnfairLock(initialState: State(now: now, calendar: calendar))
    }

    var now: Date {
        state.withLock(\.now)
    }

    var calendar: Calendar {
        state.withLock(\.calendar)
    }

    func update(now: Date, calendar: Calendar) {
        state.withLock { state in
            state.now = now
            state.calendar = calendar
        }
    }
}

@MainActor
private final class SuspendingReminderScheduler: ReminderScheduling {
    private(set) var reconcileCalls: [FakeReminderScheduler.ReconcileCall] = []
    private var reconcileContinuations: [CheckedContinuation<Void, Never>] = []
    private var callWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func permission() async -> NotificationPermission { .authorized }

    func requestAuthorization() async throws -> Bool { true }

    func reconcile(
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar,
        checkedDays: Set<LocalDay>
    ) async throws {
        reconcileCalls.append(.init(
            settings: settings,
            now: now,
            calendar: calendar,
            checkedDays: checkedDays
        ))
        resumeCallWaiters()
        await withCheckedContinuation { continuation in
            reconcileContinuations.append(continuation)
        }
    }

    func cancelAll() async {}

    func waitForReconcileCall(_ count: Int) async {
        guard reconcileCalls.count < count else { return }
        await withCheckedContinuation { continuation in
            callWaiters.append((count, continuation))
        }
    }

    func resumeNextReconcile() {
        reconcileContinuations.removeFirst().resume()
    }

    private func resumeCallWaiters() {
        let readyWaiters = callWaiters.filter { $0.0 <= reconcileCalls.count }
        callWaiters.removeAll { $0.0 <= reconcileCalls.count }
        readyWaiters.forEach { $0.1.resume() }
    }
}

@MainActor
private final class LifecycleStore: TetherStore {
    var habit: Habit?
    var checkIns: [DailyCheckIn] = []
    var loadCheckInsError: (any Error)?
    var upsertError: (any Error)?
    var resetError: (any Error)?
    private(set) var loadCheckInsCallCount = 0

    func loadHabit() throws -> Habit? { habit }

    func createHabit(from draft: HabitDraft, now: Date) throws -> Habit {
        guard habit == nil else { throw TetherStoreError.habitAlreadyExists }
        let draft = try draft.validated()
        let habit = Habit(
            id: UUID(),
            name: draft.name,
            doneMeaning: draft.doneMeaning,
            lightMeaning: draft.lightMeaning,
            createdAt: now,
            updatedAt: now
        )
        self.habit = habit
        return habit
    }

    func updateHabit(id: UUID, from draft: HabitDraft, now: Date) throws -> Habit {
        guard let habit, habit.id == id else { throw TetherStoreError.habitNotFound }
        let draft = try draft.validated()
        let updated = Habit(
            id: habit.id,
            name: draft.name,
            doneMeaning: draft.doneMeaning,
            lightMeaning: draft.lightMeaning,
            createdAt: habit.createdAt,
            updatedAt: now
        )
        self.habit = updated
        return updated
    }

    func loadCheckIns(habitID: UUID) throws -> [DailyCheckIn] {
        loadCheckInsCallCount += 1
        if let loadCheckInsError { throw loadCheckInsError }
        return checkIns.filter { $0.habitID == habitID }
    }

    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn {
        if let upsertError { throw upsertError }
        guard habit?.id == habitID else { throw TetherStoreError.habitNotFound }
        if let index = checkIns.firstIndex(where: { $0.habitID == habitID && $0.day == day }) {
            checkIns[index].state = state
            checkIns[index].updatedAt = now
            return checkIns[index]
        }
        let checkIn = DailyCheckIn(
            id: UUID(),
            habitID: habitID,
            day: day,
            state: state,
            createdAt: now,
            updatedAt: now
        )
        checkIns.append(checkIn)
        return checkIn
    }

    func deleteCheckIn(habitID: UUID, day: LocalDay) throws {
        guard habit?.id == habitID else { throw TetherStoreError.habitNotFound }
        checkIns.removeAll { $0.habitID == habitID && $0.day == day }
    }

    func resetAll() throws {
        if let resetError { throw resetError }
        habit = nil
        checkIns = []
    }
}

private final class LifecycleSettingsStore: ReminderSettingsStoring {
    private var value: ReminderSettings
    private(set) var resetCallCount = 0

    init(value: ReminderSettings) {
        self.value = value
    }

    func load() -> ReminderSettings { value }

    func save(_ settings: ReminderSettings) {
        value = settings
    }

    func reset() {
        resetCallCount += 1
        value = .defaultValue
    }
}
