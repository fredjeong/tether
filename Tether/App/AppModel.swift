import Observation

@MainActor
@Observable
final class AppModel {
    enum Route {
        case onboarding
        case main
    }

    private(set) var route: Route = .onboarding
    private(set) var habit: Habit?
    private(set) var isPresentingHabitSetup = false

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func load() throws {
        habit = try environment.store.loadHabit()
        route = habit == nil ? .onboarding : .main
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
