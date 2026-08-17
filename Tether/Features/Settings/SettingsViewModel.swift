import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var name = ""
    var doneMeaning = ""
    var lightMeaning = ""
    private(set) var errorMessage: String?
    let versionBuildText: String

    var canSave: Bool {
        guard let originalHabit,
              let validated = try? draft().validated() else {
            return false
        }

        return validated != HabitDraft(
            name: originalHabit.name,
            doneMeaning: originalHabit.doneMeaning,
            lightMeaning: originalHabit.lightMeaning
        )
    }

    private let environment: AppEnvironment
    private let onHabitSaved: (Habit) -> Void
    private let onReset: () -> Void
    private var originalHabit: Habit?

    init(
        environment: AppEnvironment,
        onHabitSaved: @escaping (Habit) -> Void,
        onReset: @escaping () -> Void,
        bundle: Bundle = .main,
        version: String? = nil,
        build: String? = nil
    ) {
        self.environment = environment
        self.onHabitSaved = onHabitSaved
        self.onReset = onReset

        let resolvedVersion = version
            ?? bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "—"
        let resolvedBuild = build
            ?? bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "—"
        versionBuildText = AppCopy.versionBuild(
            version: resolvedVersion,
            build: resolvedBuild
        )
    }

    func load() {
        do {
            guard let habit = try environment.store.loadHabit() else {
                throw TetherStoreError.habitNotFound
            }
            apply(habit)
            errorMessage = nil
        } catch {
            errorMessage = AppCopy.settingsLoadError
        }
    }

    @discardableResult
    func saveHabit() -> Habit? {
        guard let originalHabit,
              let validated = try? draft().validated(),
              canSave else {
            return nil
        }

        do {
            let updated = try environment.store.updateHabit(
                id: originalHabit.id,
                from: validated,
                now: environment.dayProvider.now
            )
            apply(updated)
            errorMessage = nil
            onHabitSaved(updated)
            return updated
        } catch {
            errorMessage = AppCopy.habitChangesSaveError
            return nil
        }
    }

    @discardableResult
    func resetAll() -> Bool {
        do {
            try environment.store.resetAll()
            originalHabit = nil
            name = ""
            doneMeaning = ""
            lightMeaning = ""
            errorMessage = nil
            onReset()
            return true
        } catch {
            errorMessage = AppCopy.resetError
            return false
        }
    }

    private func draft() -> HabitDraft {
        HabitDraft(
            name: name,
            doneMeaning: doneMeaning,
            lightMeaning: lightMeaning
        )
    }

    private func apply(_ habit: Habit) {
        originalHabit = habit
        name = habit.name
        doneMeaning = habit.doneMeaning
        lightMeaning = habit.lightMeaning
    }
}
