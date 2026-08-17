import Foundation
import SwiftData
import Testing
@testable import Tether

@MainActor
struct SettingsViewModelTests {
    @Test
    func loadUsesTheExistingHabitValues() throws {
        let fixture = try SettingsFixture()
        let viewModel = fixture.makeViewModel()

        viewModel.load()

        #expect(viewModel.name == "Workout")
        #expect(viewModel.doneMeaning == "A full workout")
        #expect(viewModel.lightMeaning == "Move for 10 minutes")
        #expect(!viewModel.canSave)
    }

    @Test
    func saveAppliesHabitDraftValidation() throws {
        let fixture = try SettingsFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()

        viewModel.name = "   "
        #expect(!viewModel.canSave)
        #expect(viewModel.saveHabit() == nil)
        #expect(fixture.store.updateCallCount == 0)

        viewModel.name = "  Workout  "
        #expect(!viewModel.canSave)
        #expect(viewModel.saveHabit() == nil)
        #expect(fixture.store.updateCallCount == 0)

        viewModel.name = String(repeating: "a", count: 41)
        #expect(!viewModel.canSave)
        #expect(viewModel.saveHabit() == nil)
        #expect(fixture.store.updateCallCount == 0)
    }

    @Test
    func saveTrimsChangesAndPreservesHabitIdentityAndCreationDate() throws {
        let fixture = try SettingsFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()
        viewModel.name = "  Training  "
        viewModel.doneMeaning = "  Complete the program  "
        viewModel.lightMeaning = "  Do one set  "

        let updated = try #require(viewModel.saveHabit())

        #expect(updated.id == fixture.habit.id)
        #expect(updated.createdAt == fixture.habit.createdAt)
        #expect(updated.updatedAt == fixture.now)
        #expect(updated.name == "Training")
        #expect(updated.doneMeaning == "Complete the program")
        #expect(updated.lightMeaning == "Do one set")
        #expect(!viewModel.canSave)
        #expect(fixture.appModel.habit == updated)
    }

    @Test
    func savePreservesEveryExistingCheckIn() throws {
        let fixture = try SettingsFixture()
        let before = try fixture.store.loadCheckIns(habitID: fixture.habit.id)
        let viewModel = fixture.makeViewModel()
        viewModel.load()
        viewModel.name = "Training"

        _ = try #require(viewModel.saveHabit())

        #expect(try fixture.store.loadCheckIns(habitID: fixture.habit.id) == before)
    }

    @Test
    func saveFailureShowsTheRequiredMessageAndKeepsTheOriginalHabit() throws {
        let fixture = try SettingsFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()
        viewModel.name = "Training"
        fixture.store.updateError = .unavailable

        #expect(viewModel.saveHabit() == nil)
        #expect(viewModel.errorMessage == "Couldn't save your changes. Please try again.")
        #expect(try fixture.store.loadHabit() == fixture.habit)
        #expect(fixture.appModel.habit == fixture.habit)
    }

    @Test
    func resetDeletesHabitAndCheckInsBeforeCallingAppModelDidReset() throws {
        let fixture = try SettingsFixture()
        var callbackObservedCleanStore = false
        let viewModel = fixture.makeViewModel(onReset: {
            callbackObservedCleanStore = (try? fixture.store.loadHabit()) == nil
                && ((try? fixture.store.loadCheckIns(habitID: fixture.habit.id)) ?? []).isEmpty
            fixture.appModel.didReset()
        })
        viewModel.load()

        #expect(viewModel.resetAll())

        #expect(callbackObservedCleanStore)
        #expect(try fixture.store.loadHabit() == nil)
        #expect(try fixture.store.loadCheckIns(habitID: fixture.habit.id).isEmpty)
        #expect(fixture.appModel.habit == nil)
        #expect(fixture.appModel.rootContent == .onboarding)
    }

    @Test
    func resetFailureKeepsSettingsStateReportsErrorAndDoesNotCallDidReset() throws {
        let fixture = try SettingsFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()
        fixture.store.resetError = .unavailable

        #expect(!viewModel.resetAll())

        #expect(viewModel.errorMessage == "Couldn't reset your data. Please try again.")
        #expect(viewModel.name == fixture.habit.name)
        #expect(try fixture.store.loadHabit() == fixture.habit)
        #expect(fixture.appModel.habit == fixture.habit)
        #expect(fixture.appModel.rootContent == .main)
    }

    @Test
    func versionAndBuildCanBeInjectedForDeterministicPresentation() throws {
        let fixture = try SettingsFixture()
        let viewModel = fixture.makeViewModel(version: "0.1", build: "7")

        #expect(viewModel.versionBuildText == "Version 0.1 (7)")
    }

    @Test
    func swiftDataEditPreservesExactCheckInsAcrossAFreshContext() throws {
        let fixture = try SettingsSwiftDataFixture()
        let before = try fixture.store.loadCheckIns(habitID: fixture.habit.id)
        let viewModel = fixture.makeViewModel()
        viewModel.load()
        viewModel.name = "Training"

        let updated = try #require(viewModel.saveHabit())
        let reloadedStore = SwiftDataTetherStore(
            context: ModelContext(fixture.container)
        )

        #expect(try reloadedStore.loadHabit() == updated)
        #expect(try reloadedStore.loadCheckIns(habitID: fixture.habit.id) == before)
    }

    @Test
    func swiftDataResetRemovesHabitAndCheckInsAcrossAFreshContext() throws {
        let fixture = try SettingsSwiftDataFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.load()

        #expect(viewModel.resetAll())

        let reloadedStore = SwiftDataTetherStore(
            context: ModelContext(fixture.container)
        )
        #expect(try reloadedStore.loadHabit() == nil)
        #expect(try reloadedStore.loadCheckIns(habitID: fixture.habit.id).isEmpty)
    }
}

@MainActor
private struct SettingsSwiftDataFixture {
    let container: ModelContainer
    let store: SwiftDataTetherStore
    let environment: AppEnvironment
    let habit: Habit

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: 9
        )))
        let container = try TetherSchema.makeContainer(inMemory: true)
        let store = SwiftDataTetherStore(context: container.mainContext)
        let habit = try store.createHabit(
            from: HabitDraft(
                name: "Workout",
                doneMeaning: "A full workout",
                lightMeaning: "Move for 10 minutes"
            ),
            now: now.addingTimeInterval(-3 * 86_400)
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
                now: now.addingTimeInterval(TimeInterval(offset * 86_400))
            )
        }

        self.container = container
        self.store = store
        environment = AppEnvironment(
            store: store,
            dayProvider: FixedDayProvider(now: now, calendar: calendar)
        )
        self.habit = habit
    }

    func makeViewModel() -> SettingsViewModel {
        SettingsViewModel(
            environment: environment,
            onHabitSaved: { _ in },
            onReset: {},
            version: "0.1",
            build: "1"
        )
    }
}

@MainActor
private final class SettingsFixture {
    let now: Date
    let store: SettingsInMemoryStore
    let environment: AppEnvironment
    let habit: Habit
    let appModel: AppModel

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: 9
        )))
        let store = SettingsInMemoryStore()
        let habit = try store.createHabit(
            from: HabitDraft(
                name: "Workout",
                doneMeaning: "A full workout",
                lightMeaning: "Move for 10 minutes"
            ),
            now: now.addingTimeInterval(-3 * 86_400)
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
                now: now.addingTimeInterval(TimeInterval(offset * 86_400))
            )
        }
        let environment = AppEnvironment(
            store: store,
            dayProvider: FixedDayProvider(now: now, calendar: calendar)
        )
        let appModel = AppModel(environment: environment)
        try appModel.load()

        self.now = now
        self.store = store
        self.environment = environment
        self.habit = habit
        self.appModel = appModel
    }

    func makeViewModel(
        onReset: (() -> Void)? = nil,
        version: String = "0.1",
        build: String = "1"
    ) -> SettingsViewModel {
        SettingsViewModel(
            environment: environment,
            onHabitSaved: appModel.didUpdateHabit,
            onReset: onReset ?? appModel.didReset,
            version: version,
            build: build
        )
    }
}

@MainActor
private final class SettingsInMemoryStore: TetherStore {
    enum StorageError: Error {
        case unavailable
    }

    private var habit: Habit?
    private var checkIns: [DailyCheckIn] = []
    private(set) var updateCallCount = 0
    var updateError: StorageError?
    var resetError: StorageError?

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
        updateCallCount += 1
        if let updateError {
            throw updateError
        }
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
        guard habit?.id == habitID else {
            throw TetherStoreError.habitNotFound
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
        if let resetError {
            throw resetError
        }
        habit = nil
        checkIns = []
    }
}
