import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var name = ""
    var doneMeaning = ""
    var lightMeaning = ""
    private(set) var errorMessage: String?

    var canSubmit: Bool {
        (try? draft().validated()) != nil
    }

    private let environment: AppEnvironment
    private let onCreated: (Habit) -> Void

    init(
        environment: AppEnvironment,
        onCreated: @escaping (Habit) -> Void
    ) {
        self.environment = environment
        self.onCreated = onCreated
    }

    func submit() -> Habit? {
        guard canSubmit else {
            return nil
        }

        do {
            let habit = try environment.store.createHabit(
                from: draft(),
                now: environment.dayProvider.now
            )
            errorMessage = nil
            onCreated(habit)
            return habit
        } catch {
            errorMessage = AppCopy.habitSaveError
            return nil
        }
    }

    private func draft() -> HabitDraft {
        HabitDraft(
            name: name,
            doneMeaning: doneMeaning,
            lightMeaning: lightMeaning
        )
    }
}
