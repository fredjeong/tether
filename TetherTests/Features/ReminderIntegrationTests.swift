import Foundation
import Testing
@testable import Tether

@MainActor
struct ReminderIntegrationTests {
    @Test
    func reminderDefaultsToOff() throws {
        let fixture = try ReminderIntegrationFixture()
        let onboarding = fixture.makeOnboardingViewModel()
        let settings = fixture.makeSettingsViewModel()

        settings.load()

        #expect(!onboarding.isReminderEnabled)
        #expect(onboarding.reminderSettings == .defaultValue)
        #expect(!settings.reminderSettings.isEnabled)
        #expect(settings.reminderSettings == .defaultValue)
    }

    @Test
    func enablingFromNotDeterminedRequestsAuthorizationExactlyOnce() async throws {
        let fixture = try ReminderIntegrationFixture(permission: .notDetermined)
        let viewModel = fixture.makeOnboardingViewModel()

        await viewModel.setReminderEnabled(true)

        #expect(fixture.scheduler.authorizationRequestCount == 1)
        #expect(viewModel.isReminderEnabled)
        #expect(viewModel.reminderPermissionMessage == nil)
    }

    @Test
    func authorizedEnableSavesSettingsAndReconcilesAllPersistedDays() async throws {
        let fixture = try ReminderIntegrationFixture(permission: .authorized)
        let earlierDay = fixture.today.adding(days: -2, calendar: fixture.calendar)
        try fixture.store.seedCheckIn(
            habitID: fixture.habit.id,
            day: earlierDay,
            state: .light,
            now: fixture.now
        )
        let viewModel = fixture.makeSettingsViewModel()
        viewModel.load()

        await viewModel.setReminderEnabled(true)

        let expected = ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        #expect(fixture.settingsStore.load() == expected)
        #expect(fixture.scheduler.authorizationRequestCount == 0)
        #expect(fixture.scheduler.reconcileCalls == [FakeReminderScheduler.ReconcileCall(
            settings: expected,
            now: fixture.now,
            calendar: fixture.calendar,
            checkedDays: [earlierDay]
        )])
    }

    @Test
    func deniedEnableStaysOffAndExposesOpenSettingsState() async throws {
        let fixture = try ReminderIntegrationFixture(permission: .denied)
        let viewModel = fixture.makeSettingsViewModel()
        viewModel.load()

        await viewModel.setReminderEnabled(true)

        #expect(!viewModel.isReminderEnabled)
        #expect(fixture.settingsStore.load() == .defaultValue)
        #expect(viewModel.reminderPermissionMessage == AppCopy.notificationPermissionUnavailable)
        #expect(viewModel.showsOpenSettingsAction)
        #expect(fixture.scheduler.authorizationRequestCount == 0)
        #expect(fixture.scheduler.reconcileCalls.isEmpty)
    }

    @Test
    func changingReminderTimePersistsThenReconcilesTheNewTime() async throws {
        let fixture = try ReminderIntegrationFixture(
            permission: .authorized,
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        )
        let earlierDay = fixture.today.adding(days: -1, calendar: fixture.calendar)
        try fixture.store.seedCheckIn(
            habitID: fixture.habit.id,
            day: earlierDay,
            state: .done,
            now: fixture.now
        )
        let viewModel = fixture.makeSettingsViewModel()
        viewModel.load()
        let time = try #require(fixture.date(hour: 7, minute: 45))

        await viewModel.setReminderTime(time)

        let expected = ReminderSettings(isEnabled: true, hour: 7, minute: 45)
        #expect(fixture.settingsStore.load() == expected)
        #expect(fixture.scheduler.reconcileCalls == [FakeReminderScheduler.ReconcileCall(
            settings: expected,
            now: fixture.now,
            calendar: fixture.calendar,
            checkedDays: [earlierDay]
        )])
    }

    @Test
    func disablingSavesOffAndCancelsPendingReminders() async throws {
        let fixture = try ReminderIntegrationFixture(
            permission: .authorized,
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        )
        let viewModel = fixture.makeSettingsViewModel()
        viewModel.load()

        await viewModel.setReminderEnabled(false)

        #expect(fixture.settingsStore.load() == .defaultValue)
        #expect(fixture.scheduler.cancelAllCallCount == 1)
        #expect(fixture.scheduler.reconcileCalls.isEmpty)
    }

    @Test
    func settingsSchedulingFailureDisablesAndCancelsAnyPartialSchedule() async throws {
        let fixture = try ReminderIntegrationFixture(
            permission: .authorized,
            schedulerError: ReminderIntegrationError.unavailable
        )
        let viewModel = fixture.makeSettingsViewModel()
        viewModel.load()

        await viewModel.setReminderEnabled(true)

        #expect(viewModel.reminderSettings == .defaultValue)
        #expect(!viewModel.isReminderEnabled)
        #expect(fixture.settingsStore.load() == .defaultValue)
        #expect(fixture.scheduler.reconcileCalls.count == 1)
        #expect(fixture.scheduler.cancelAllCallCount == 1)
        #expect(viewModel.reminderErrorMessage != nil)
    }

    @Test
    func failedReminderTimeChangeDisablesAndCancelsAnyPartialSchedule() async throws {
        let fixture = try ReminderIntegrationFixture(
            permission: .authorized,
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0),
            schedulerError: ReminderIntegrationError.unavailable
        )
        let viewModel = fixture.makeSettingsViewModel()
        viewModel.load()
        let time = try #require(fixture.date(hour: 7, minute: 45))

        await viewModel.setReminderTime(time)

        #expect(viewModel.reminderSettings == .defaultValue)
        #expect(!viewModel.isReminderEnabled)
        #expect(fixture.settingsStore.load() == .defaultValue)
        #expect(fixture.scheduler.reconcileCalls.count == 1)
        #expect(fixture.scheduler.cancelAllCallCount == 1)
        #expect(viewModel.reminderErrorMessage != nil)
    }

    @Test
    func onboardingSchedulingFailureStillCreatesHabitAndLeavesReminderDisabled() async throws {
        let fixture = try ReminderIntegrationFixture(
            hasHabit: false,
            permission: .authorized,
            schedulerError: ReminderIntegrationError.unavailable
        )
        let viewModel = fixture.makeOnboardingViewModel()
        viewModel.name = "Workout"
        viewModel.doneMeaning = "A full workout"
        viewModel.lightMeaning = "Move for 10 minutes"
        await viewModel.setReminderEnabled(true)

        let submitted = await viewModel.submitWithReminderReconciliation()
        let created = try #require(submitted)

        #expect(try fixture.store.loadHabit() == created)
        #expect(fixture.settingsStore.load() == .defaultValue)
        #expect(fixture.scheduler.reconcileCalls.count == 1)
        #expect(viewModel.reminderErrorMessage != nil)
    }

    @Test
    func successfulTodayCheckInReconcilesWithEveryPersistedCheckedDay() async throws {
        let fixture = try ReminderIntegrationFixture(
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        )
        let yesterday = fixture.today.adding(days: -1, calendar: fixture.calendar)
        try fixture.store.seedCheckIn(habitID: fixture.habit.id, day: yesterday, state: .light, now: fixture.now)
        let viewModel = fixture.makeTodayViewModel()
        viewModel.load()

        await viewModel.selectAndReconcile(.done)

        let persistedDays = Set(try fixture.store.loadCheckIns(habitID: fixture.habit.id).map(\.day))
        #expect(viewModel.selectedState == .done)
        #expect(fixture.scheduler.reconcileCalls.last?.checkedDays == persistedDays)
        #expect(fixture.scheduler.reconcileCalls.last?.checkedDays.contains(fixture.today) == true)
        let plans = ReminderPlanBuilder.build(
            settings: fixture.scheduler.reconcileCalls.last!.settings,
            now: fixture.now,
            calendar: fixture.calendar,
            checkedDays: fixture.scheduler.reconcileCalls.last!.checkedDays
        )
        #expect(plans.count == 30)
        #expect(plans.first?.identifier == "tether.daily.1-2026-08-18")
    }

    @Test
    func clearingTodayCheckInReconcilesWithoutTheRemovedDay() async throws {
        let fixture = try ReminderIntegrationFixture(
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        )
        let viewModel = fixture.makeTodayViewModel()
        viewModel.load()
        await viewModel.selectAndReconcile(.done)

        await viewModel.clearTodayCheckInAndReconcile()

        #expect(try fixture.store.loadCheckIns(habitID: fixture.habit.id).isEmpty)
        #expect(viewModel.selectedState == nil)
        #expect(!viewModel.snapshot.isCheckedInToday)
        #expect(fixture.scheduler.reconcileCalls.last?.checkedDays == [])
    }

    @Test
    func checkInSchedulingFailureDoesNotRollBackTheSavedCheckIn() async throws {
        let fixture = try ReminderIntegrationFixture(
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0),
            schedulerError: ReminderIntegrationError.unavailable
        )
        let viewModel = fixture.makeTodayViewModel()
        viewModel.load()

        await viewModel.selectAndReconcile(.rest)

        #expect(try fixture.store.loadCheckIns(habitID: fixture.habit.id).map(\.state) == [.rest])
        #expect(viewModel.selectedState == .rest)
        #expect(viewModel.snapshot.isCheckedInToday)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func disabledReminderDoesNotShowSchedulingErrorAfterCheckIn() async throws {
        let fixture = try ReminderIntegrationFixture(
            reminderSettings: .defaultValue,
            schedulerError: ReminderIntegrationError.unavailable
        )
        let viewModel = fixture.makeTodayViewModel()
        viewModel.load()

        await viewModel.selectAndReconcile(.done)

        #expect(viewModel.selectedState == .done)
        #expect(viewModel.errorMessage == nil)
        #expect(fixture.scheduler.reconcileCalls.isEmpty)
    }

    @Test
    func successfulResetResetsReminderSettingsCancelsBeforeRoutingToWelcome() async throws {
        let fixture = try ReminderIntegrationFixture(
            reminderSettings: ReminderSettings(isEnabled: true, hour: 8, minute: 30)
        )
        let appModel = AppModel(environment: fixture.environment)
        try appModel.load()
        var callbackSawCleanReminderState = false
        let viewModel = fixture.makeSettingsViewModel(onReset: {
            callbackSawCleanReminderState = fixture.settingsStore.load() == .defaultValue
                && fixture.scheduler.cancelAllCallCount == 1
            appModel.didReset()
        })
        viewModel.load()

        let didReset = await viewModel.resetAllAndCancelReminders()

        #expect(didReset)

        #expect(callbackSawCleanReminderState)
        #expect(try fixture.store.loadHabit() == nil)
        #expect(fixture.settingsStore.resetCallCount == 1)
        #expect(fixture.scheduler.cancelAllCallCount == 1)
        #expect(appModel.rootContent == .onboarding)
    }

    @Test
    func failedDataResetLeavesReminderSettingsAndRouteUntouched() async throws {
        let initialSettings = ReminderSettings(isEnabled: true, hour: 8, minute: 30)
        let fixture = try ReminderIntegrationFixture(reminderSettings: initialSettings)
        fixture.store.resetError = ReminderIntegrationError.unavailable
        let appModel = AppModel(environment: fixture.environment)
        try appModel.load()
        var didReset = false
        let viewModel = fixture.makeSettingsViewModel(onReset: { didReset = true })
        viewModel.load()

        let resetResult = await viewModel.resetAllAndCancelReminders()

        #expect(!resetResult)

        #expect(fixture.settingsStore.load() == initialSettings)
        #expect(fixture.settingsStore.resetCallCount == 0)
        #expect(fixture.scheduler.cancelAllCallCount == 0)
        #expect(!didReset)
        #expect(appModel.rootContent == .main)
    }

    @Test
    func foregroundRefreshReloadsAppModelAndReconcilesRollingSchedule() async throws {
        let fixture = try ReminderIntegrationFixture(
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        )
        let appModel = AppModel(environment: fixture.environment)
        let today = fixture.makeTodayViewModel()
        try appModel.load()
        today.load()

        await appModel.refreshForCurrentDay()

        #expect(appModel.lifecycleRefreshID == 1)
        #expect(appModel.habit == fixture.habit)
        #expect(fixture.scheduler.reconcileCalls.last?.settings.isEnabled == true)
        #expect(fixture.scheduler.reconcileCalls.last?.now == fixture.now)
        today.refresh()
        #expect(today.habit == fixture.habit)
    }

    @Test
    func calendarDayChangeUsesTheSameRefreshAndReconciliationPath() async throws {
        let fixture = try ReminderIntegrationFixture(
            reminderSettings: ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        )
        let appModel = AppModel(environment: fixture.environment)
        try appModel.load()

        await appModel.refreshForCurrentDay()
        await appModel.refreshForCurrentDay()

        #expect(appModel.lifecycleRefreshID == 2)
        #expect(fixture.scheduler.reconcileCalls.count == 2)
        #expect(fixture.scheduler.reconcileCalls[0] == fixture.scheduler.reconcileCalls[1])
    }
}

private enum ReminderIntegrationError: Error {
    case unavailable
}

@MainActor
private final class ReminderIntegrationFixture {
    let calendar: Calendar
    let now: Date
    let today: LocalDay
    let store: ReminderIntegrationStore
    let scheduler: FakeReminderScheduler
    let settingsStore: ReminderIntegrationSettingsStore
    let environment: AppEnvironment
    let habit: Habit

    init(
        hasHabit: Bool = true,
        permission: NotificationPermission = .authorized,
        reminderSettings: ReminderSettings = .defaultValue,
        schedulerError: (any Error)? = nil
    ) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: 19
        )))
        let store = ReminderIntegrationStore()
        let habit = Habit(
            id: UUID(),
            name: "Workout",
            doneMeaning: "A full workout",
            lightMeaning: "Move for 10 minutes",
            createdAt: now.addingTimeInterval(-86_400),
            updatedAt: now.addingTimeInterval(-86_400)
        )
        if hasHabit {
            store.habit = habit
        }
        let scheduler = FakeReminderScheduler(
            permissionResult: permission,
            reconcileError: schedulerError
        )
        let settingsStore = ReminderIntegrationSettingsStore(value: reminderSettings)

        self.calendar = calendar
        self.now = now
        today = LocalDay(date: now, calendar: calendar)
        self.store = store
        self.scheduler = scheduler
        self.settingsStore = settingsStore
        environment = AppEnvironment(
            store: store,
            dayProvider: FixedDayProvider(now: now, calendar: calendar),
            reminderScheduler: scheduler,
            reminderSettingsStore: settingsStore
        )
        self.habit = habit
    }

    func date(hour: Int, minute: Int) -> Date? {
        calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: hour,
            minute: minute
        ))
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(environment: environment, onCreated: { _ in })
    }

    func makeSettingsViewModel(
        onReset: @escaping () -> Void = {}
    ) -> SettingsViewModel {
        SettingsViewModel(
            environment: environment,
            onHabitSaved: { _ in },
            onReset: onReset,
            version: "0.1",
            build: "1"
        )
    }

    func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(environment: environment)
    }
}

private final class ReminderIntegrationSettingsStore: ReminderSettingsStoring {
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

@MainActor
private final class ReminderIntegrationStore: TetherStore {
    var habit: Habit?
    private var checkIns: [DailyCheckIn] = []
    var resetError: (any Error)?

    func loadHabit() throws -> Habit? { habit }

    func createHabit(from draft: HabitDraft, now: Date) throws -> Habit {
        guard habit == nil else { throw TetherStoreError.habitAlreadyExists }
        let draft = try draft.validated()
        let created = Habit(
            id: UUID(),
            name: draft.name,
            doneMeaning: draft.doneMeaning,
            lightMeaning: draft.lightMeaning,
            createdAt: now,
            updatedAt: now
        )
        habit = created
        return created
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
        checkIns.filter { $0.habitID == habitID }
    }

    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn {
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

    func seedCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws {
        _ = try upsertCheckIn(habitID: habitID, day: day, state: state, now: now)
    }

    func resetAll() throws {
        if let resetError { throw resetError }
        habit = nil
        checkIns = []
    }
}
