import Foundation
import Testing
@testable import Tether

@MainActor
struct OnboardingViewModelTests {
    @Test(arguments: [
        ("", "A full workout", "Move for 10 minutes"),
        ("Workout", "", "Move for 10 minutes"),
        ("Workout", "A full workout", ""),
    ])
    func cannotSubmitWhenARequiredFieldIsEmpty(
        name: String,
        doneMeaning: String,
        lightMeaning: String
    ) {
        let fixture = OnboardingFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.name = name
        viewModel.doneMeaning = doneMeaning
        viewModel.lightMeaning = lightMeaning

        #expect(!viewModel.canSubmit)
    }

    @Test
    func canSubmitWhenAllRequiredFieldsAreValid() {
        let fixture = OnboardingFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.name = "Workout"
        viewModel.doneMeaning = "A full workout"
        viewModel.lightMeaning = "Move for 10 minutes"

        #expect(viewModel.canSubmit)
    }

    @Test
    func submitTrimsValuesCreatesOneHabitAndReportsIt() throws {
        let fixture = OnboardingFixture()
        let viewModel = fixture.makeViewModel()
        viewModel.name = "  Workout  "
        viewModel.doneMeaning = "  A full workout  "
        viewModel.lightMeaning = "  Move for 10 minutes  "

        let created = try #require(viewModel.submit())

        #expect(created.name == "Workout")
        #expect(created.doneMeaning == "A full workout")
        #expect(created.lightMeaning == "Move for 10 minutes")
        #expect(fixture.store.habits == [created])
    }

    @Test
    func storageErrorShowsMessageAndKeepsTheAppOnOnboarding() throws {
        let fixture = OnboardingFixture(createError: .unavailable)
        let appModel = AppModel(environment: fixture.environment)
        try appModel.load()
        let viewModel = fixture.makeViewModel(onCreated: appModel.didCreateHabit)
        viewModel.name = "Workout"
        viewModel.doneMeaning = "A full workout"
        viewModel.lightMeaning = "Move for 10 minutes"

        #expect(viewModel.submit() == nil)
        #expect(viewModel.errorMessage == "Couldn't save your habit. Please try again.")
        expectOnboarding(appModel)
    }

    @Test
    func preExistingHabitRoutesTheAppModelToMain() throws {
        let existingHabit = Habit(
            id: UUID(),
            name: "Workout",
            doneMeaning: "A full workout",
            lightMeaning: "Move for 10 minutes",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        let fixture = OnboardingFixture(existingHabit: existingHabit)
        let appModel = AppModel(environment: fixture.environment)

        try appModel.load()

        #expect(appModel.habit == existingHabit)
        expectMain(appModel)
    }

    @Test
    func startupLoadFailureShowsErrorInsteadOfOnboardingAndRetryClearsIt() throws {
        let existingHabit = Habit(
            id: UUID(),
            name: "Workout",
            doneMeaning: "A full workout",
            lightMeaning: "Move for 10 minutes",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        let fixture = OnboardingFixture(
            existingHabit: existingHabit,
            loadError: .unavailable
        )
        let appModel = AppModel(environment: fixture.environment)

        #expect(throws: OnboardingStore.StorageError.unavailable) {
            try appModel.load()
        }

        #expect(appModel.startupErrorMessage == AppCopy.startupLoadError)
        #expect(appModel.rootContent == .startupError)

        fixture.store.loadError = nil

        try appModel.load()

        #expect(appModel.startupErrorMessage == nil)
        #expect(appModel.rootContent == .main)
        expectMain(appModel)
    }

    @Test
    func completingOrResettingOnboardingClearsHabitSetupPresentation() throws {
        let existingHabit = Habit(
            id: UUID(),
            name: "Workout",
            doneMeaning: "A full workout",
            lightMeaning: "Move for 10 minutes",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        let fixture = OnboardingFixture(existingHabit: existingHabit)
        let appModel = AppModel(environment: fixture.environment)
        try appModel.load()

        appModel.presentHabitSetup()
        #expect(appModel.isPresentingHabitSetup)

        appModel.didCreateHabit(existingHabit)

        #expect(!appModel.isPresentingHabitSetup)
        expectMain(appModel)

        appModel.presentHabitSetup()
        #expect(appModel.isPresentingHabitSetup)

        appModel.didReset()

        #expect(appModel.habit == nil)
        #expect(!appModel.isPresentingHabitSetup)
        expectOnboarding(appModel)
    }

    private func expectOnboarding(_ appModel: AppModel) {
        guard case .onboarding = appModel.route else {
            Issue.record("A storage failure must keep the app on onboarding.")
            return
        }
    }

    private func expectMain(_ appModel: AppModel) {
        guard case .main = appModel.route else {
            Issue.record("A stored habit must route the app to its main shell.")
            return
        }
    }
}

@MainActor
private final class OnboardingFixture {
    let store: OnboardingStore
    let environment: AppEnvironment

    init(
        existingHabit: Habit? = nil,
        createError: OnboardingStore.StorageError? = nil,
        loadError: OnboardingStore.StorageError? = nil
    ) {
        store = OnboardingStore(
            existingHabit: existingHabit,
            createError: createError,
            loadError: loadError
        )
        environment = AppEnvironment(
            store: store,
            dayProvider: FixedDayProvider(
                now: .distantPast,
                calendar: .autoupdatingCurrent
            )
        )
    }

    func makeViewModel(
        onCreated: @escaping (Habit) -> Void = { _ in }
    ) -> OnboardingViewModel {
        OnboardingViewModel(environment: environment, onCreated: onCreated)
    }
}

@MainActor
private final class OnboardingStore: TetherStore {
    enum StorageError: Error {
        case unavailable
    }

    private(set) var habits: [Habit]
    private let createError: StorageError?
    var loadError: StorageError?

    init(
        existingHabit: Habit?,
        createError: StorageError?,
        loadError: StorageError?
    ) {
        if let existingHabit {
            habits = [existingHabit]
        } else {
            habits = []
        }
        self.createError = createError
        self.loadError = loadError
    }

    func loadHabit() throws -> Habit? {
        if let loadError {
            throw loadError
        }
        return habits.first
    }

    func createHabit(from draft: HabitDraft, now: Date) throws -> Habit {
        if let createError {
            throw createError
        }
        guard habits.isEmpty else {
            throw TetherStoreError.habitAlreadyExists
        }

        let validated = try draft.validated()
        let habit = Habit(
            id: UUID(),
            name: validated.name,
            doneMeaning: validated.doneMeaning,
            lightMeaning: validated.lightMeaning,
            createdAt: now,
            updatedAt: now
        )
        habits = [habit]
        return habit
    }

    func updateHabit(id: UUID, from draft: HabitDraft, now: Date) throws -> Habit {
        throw TetherStoreError.habitNotFound
    }

    func loadCheckIns(habitID: UUID) throws -> [DailyCheckIn] {
        []
    }

    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn {
        throw TetherStoreError.habitNotFound
    }

    func deleteCheckIn(habitID: UUID, day: LocalDay) throws {
        throw TetherStoreError.habitNotFound
    }

    func resetAll() throws {
        habits = []
    }
}
