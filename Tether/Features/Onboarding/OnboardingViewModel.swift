import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var name = ""
    var doneMeaning = ""
    var lightMeaning = ""
    var isReminderEnabled = false
    var reminderTime: Date
    private(set) var errorMessage: String?
    private(set) var reminderPermissionMessage: String?
    private(set) var showsOpenSettingsAction = false
    private(set) var reminderErrorMessage: String?

    var reminderSettings: ReminderSettings {
        let components = environment.dayProvider.calendar.dateComponents(
            [.hour, .minute],
            from: reminderTime
        )
        return ReminderSettings(
            isEnabled: isReminderEnabled,
            hour: components.hour ?? ReminderSettings.defaultValue.hour,
            minute: components.minute ?? ReminderSettings.defaultValue.minute
        )
    }

    var canSubmit: Bool {
        (try? draft().validated()) != nil
    }

    private let environment: AppEnvironment
    private let onCreated: (Habit) -> Void
    private let onReminderError: (String?) -> Void

    init(
        environment: AppEnvironment,
        onCreated: @escaping (Habit) -> Void,
        onReminderError: @escaping (String?) -> Void = { _ in }
    ) {
        self.environment = environment
        self.onCreated = onCreated
        self.onReminderError = onReminderError
        reminderTime = Self.time(
            for: .defaultValue,
            now: environment.dayProvider.now,
            calendar: environment.dayProvider.calendar
        )
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

    func setReminderEnabled(_ isEnabled: Bool) async {
        guard isEnabled else {
            self.isReminderEnabled = false
            reminderPermissionMessage = nil
            showsOpenSettingsAction = false
            return
        }

        switch await environment.reminderScheduler.permission() {
        case .authorized:
            self.isReminderEnabled = true
            reminderPermissionMessage = nil
            showsOpenSettingsAction = false
        case .notDetermined:
            do {
                if try await environment.reminderScheduler.requestAuthorization() {
                    self.isReminderEnabled = true
                    reminderPermissionMessage = nil
                    showsOpenSettingsAction = false
                } else {
                    showDeniedPermission()
                }
            } catch {
                showDeniedPermission()
            }
        case .denied:
            showDeniedPermission()
        }
    }

    func submitWithReminderReconciliation() async -> Habit? {
        guard let habit = submit() else {
            return nil
        }
        guard isReminderEnabled else {
            return habit
        }

        let settings = reminderSettings
        environment.reminderSettingsStore.save(settings)
        do {
            try await reconcile(settings: settings, habit: habit)
            reminderErrorMessage = nil
            onReminderError(nil)
        } catch {
            environment.reminderSettingsStore.save(.defaultValue)
            await environment.reminderScheduler.cancelAll()
            isReminderEnabled = false
            reminderErrorMessage = "Couldn't schedule your reminder. Please try again."
            onReminderError(reminderErrorMessage)
        }
        return habit
    }

    private func draft() -> HabitDraft {
        HabitDraft(
            name: name,
            doneMeaning: doneMeaning,
            lightMeaning: lightMeaning
        )
    }

    private func reconcile(
        settings: ReminderSettings,
        habit: Habit
    ) async throws {
        let checkedDays = Set(
            try environment.store.loadCheckIns(habitID: habit.id).map(\.day)
        )
        try await environment.reminderScheduler.reconcile(
            settings: settings,
            now: environment.dayProvider.now,
            calendar: environment.dayProvider.calendar,
            checkedDays: checkedDays
        )
    }

    private func showDeniedPermission() {
        isReminderEnabled = false
        reminderPermissionMessage = AppCopy.notificationPermissionUnavailable
        showsOpenSettingsAction = true
    }

    private static func time(
        for settings: ReminderSettings,
        now: Date,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            bySettingHour: settings.hour,
            minute: settings.minute,
            second: 0,
            of: now
        ) ?? now
    }
}
