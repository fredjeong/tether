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

    var rootContent: RootContent {
        if startupErrorMessage != nil {
            return .startupError
        }
        return route == .onboarding ? .onboarding : .main
    }

    private let environment: AppEnvironment

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
}
