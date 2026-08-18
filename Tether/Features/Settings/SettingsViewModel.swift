import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var name = ""
    var doneMeaning = ""
    var lightMeaning = ""
    private(set) var reminderSettings = ReminderSettings.defaultValue
    var reminderTime: Date
    private(set) var errorMessage: String?
    private(set) var reminderPermissionMessage: String?
    private(set) var showsOpenSettingsAction = false
    private(set) var reminderErrorMessage: String?
    let versionBuildText: String

    var isReminderEnabled: Bool {
        reminderSettings.isEnabled
    }

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
    private var reminderOperation: Task<Void, Never>?

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
        reminderTime = Self.time(
            for: .defaultValue,
            now: environment.dayProvider.now,
            calendar: environment.dayProvider.calendar
        )

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
        reminderSettings = environment.reminderSettingsStore.load()
        reminderTime = Self.time(
            for: reminderSettings,
            now: environment.dayProvider.now,
            calendar: environment.dayProvider.calendar
        )
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

    func loadReminderPermission() async {
        await enqueueReminderOperation { [weak self] in
            guard let self else { return }
            await self.refreshReminderPermission()
        }
    }

    func setReminderEnabled(_ isEnabled: Bool) async {
        await enqueueReminderOperation { [weak self] in
            guard let self else { return }
            await self.updateReminderEnabled(isEnabled)
        }
    }

    func setReminderTime(_ time: Date) async {
        await enqueueReminderOperation { [weak self] in
            guard let self else { return }
            await self.updateReminderTime(time)
        }
    }

    private func refreshReminderPermission() async {
        switch await environment.reminderScheduler.permission() {
        case .denied:
            if reminderSettings.isEnabled {
                environment.reminderSettingsStore.save(.defaultValue)
                reminderSettings = .defaultValue
                await environment.reminderScheduler.cancelAll()
            }
            showDeniedPermission()
        case .authorized, .notDetermined:
            reminderPermissionMessage = nil
            showsOpenSettingsAction = false
        }
    }

    private func updateReminderEnabled(_ isEnabled: Bool) async {
        guard isEnabled else {
            environment.reminderSettingsStore.save(.defaultValue)
            reminderSettings = .defaultValue
            reminderTime = Self.time(
                for: .defaultValue,
                now: environment.dayProvider.now,
                calendar: environment.dayProvider.calendar
            )
            reminderPermissionMessage = nil
            showsOpenSettingsAction = false
            reminderErrorMessage = nil
            await environment.reminderScheduler.cancelAll()
            return
        }

        switch await environment.reminderScheduler.permission() {
        case .authorized:
            await enableReminder()
        case .notDetermined:
            do {
                if try await environment.reminderScheduler.requestAuthorization() {
                    await enableReminder()
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

    private func updateReminderTime(_ time: Date) async {
        guard reminderSettings.isEnabled else {
            return
        }

        let candidate = settings(with: time, enabled: true)
        environment.reminderSettingsStore.save(candidate)
        do {
            try await reconcile(settings: candidate)
            reminderSettings = candidate
            reminderTime = time
            reminderErrorMessage = nil
        } catch {
            await disableReminderAfterSchedulingFailure()
        }
    }

    @discardableResult
    func resetAllAndCancelReminders() async -> Bool {
        do {
            try environment.store.resetAll()
            environment.reminderSettingsStore.reset()
            await environment.reminderScheduler.cancelAll()
            originalHabit = nil
            name = ""
            doneMeaning = ""
            lightMeaning = ""
            reminderSettings = .defaultValue
            reminderTime = Self.time(
                for: .defaultValue,
                now: environment.dayProvider.now,
                calendar: environment.dayProvider.calendar
            )
            reminderPermissionMessage = nil
            showsOpenSettingsAction = false
            reminderErrorMessage = nil
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

    private func enableReminder() async {
        let candidate = settings(with: reminderTime, enabled: true)
        environment.reminderSettingsStore.save(candidate)
        do {
            try await reconcile(settings: candidate)
            reminderSettings = candidate
            reminderPermissionMessage = nil
            showsOpenSettingsAction = false
            reminderErrorMessage = nil
        } catch {
            await disableReminderAfterSchedulingFailure()
        }
    }

    private func disableReminderAfterSchedulingFailure() async {
        environment.reminderSettingsStore.save(.defaultValue)
        reminderSettings = .defaultValue
        reminderTime = Self.time(
            for: .defaultValue,
            now: environment.dayProvider.now,
            calendar: environment.dayProvider.calendar
        )
        reminderErrorMessage = "Couldn't schedule your reminder. Please try again."
        await environment.reminderScheduler.cancelAll()
    }

    private func enqueueReminderOperation(
        _ operation: @escaping @MainActor () async -> Void
    ) async {
        let previousOperation = reminderOperation
        let nextOperation = Task { @MainActor in
            await previousOperation?.value
            await operation()
        }
        reminderOperation = nextOperation
        await nextOperation.value
    }

    private func reconcile(settings: ReminderSettings) async throws {
        guard let habit = try environment.store.loadHabit() else {
            throw TetherStoreError.habitNotFound
        }
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

    private func settings(with time: Date, enabled: Bool) -> ReminderSettings {
        let components = environment.dayProvider.calendar.dateComponents(
            [.hour, .minute],
            from: time
        )
        return ReminderSettings(
            isEnabled: enabled,
            hour: components.hour ?? ReminderSettings.defaultValue.hour,
            minute: components.minute ?? ReminderSettings.defaultValue.minute
        )
    }

    private func showDeniedPermission() {
        reminderSettings = .defaultValue
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
