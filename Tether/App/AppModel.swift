import Observation

@MainActor
@Observable
final class AppModel {
    enum Route {
        case onboarding
        case main
    }

    enum RootContent: Equatable {
        case startupError
        case onboarding
        case main
    }

    private(set) var route: Route = .onboarding
    private(set) var habit: Habit?
    private(set) var isPresentingHabitSetup = false
    private(set) var startupErrorMessage: String?
    private(set) var persistenceErrorMessage: String?
    private(set) var reminderErrorMessage: String?
    private(set) var lifecycleRefreshID = 0

    var rootContent: RootContent {
        if startupErrorMessage != nil {
            return .startupError
        }
        return route == .onboarding ? .onboarding : .main
    }

    private let environment: AppEnvironment
    private var isRefreshingForCurrentDay = false
    private var needsCurrentDayRefresh = false

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func load() throws {
        do {
            habit = try environment.store.loadHabit()
            route = habit == nil ? .onboarding : .main
            startupErrorMessage = nil
        } catch {
            startupErrorMessage = AppCopy.startupLoadError
            throw error
        }
    }

    func didCreateHabit(_ habit: Habit) {
        self.habit = habit
        route = .main
        isPresentingHabitSetup = false
    }

    func didUpdateHabit(_ habit: Habit) {
        self.habit = habit
    }

    func didReset() {
        habit = nil
        route = .onboarding
        isPresentingHabitSetup = false
    }

    func presentHabitSetup() {
        isPresentingHabitSetup = true
    }

    func dismissHabitSetup() {
        isPresentingHabitSetup = false
    }

    func setReminderError(_ message: String?) {
        reminderErrorMessage = message
    }

    func refreshForCurrentDay() async {
        guard !isRefreshingForCurrentDay else {
            needsCurrentDayRefresh = true
            return
        }

        repeat {
            isRefreshingForCurrentDay = true
            needsCurrentDayRefresh = false
            await refreshPersistedStateAndReminders()
            isRefreshingForCurrentDay = false
        } while needsCurrentDayRefresh
    }

    private func refreshPersistedStateAndReminders() async {
        let now = environment.dayProvider.now
        let calendar = environment.dayProvider.calendar

        let loadedHabit: Habit
        let checkedDays: Set<LocalDay>
        do {
            guard let persistedHabit = try environment.store.loadHabit() else {
                habit = nil
                route = .onboarding
                startupErrorMessage = nil
                persistenceErrorMessage = nil
                reminderErrorMessage = nil
                lifecycleRefreshID += 1
                return
            }

            loadedHabit = persistedHabit
            checkedDays = Set(
                try environment.store.loadCheckIns(habitID: persistedHabit.id).map(\.day)
            )
            habit = loadedHabit
            route = .main
            startupErrorMessage = nil
            persistenceErrorMessage = nil
            lifecycleRefreshID += 1
        } catch {
            persistenceErrorMessage = AppCopy.todayLoadError
            lifecycleRefreshID += 1
            return
        }

        let settings = environment.reminderSettingsStore.load()
        guard settings.isEnabled else {
            reminderErrorMessage = nil
            return
        }

        do {
            try await environment.reminderScheduler.reconcile(
                settings: settings,
                now: now,
                calendar: calendar,
                checkedDays: checkedDays
            )
            reminderErrorMessage = nil
        } catch {
            reminderErrorMessage = "Couldn't update your reminder. Please try again."
        }
    }
}
