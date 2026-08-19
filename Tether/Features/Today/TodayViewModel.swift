import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var habit: Habit?
    private(set) var selectedState: CheckInState?
    private(set) var snapshot = TetherSnapshot(
        current: 0,
        best: 0,
        phase: .start,
        isCheckedInToday: false
    )
    private(set) var recentDays: [RecentCheckInDay] = []
    private(set) var errorMessage: String?
    private(set) var completionMessage = AppCopy.todayCompletedMessage

    var statusHeadline: String {
        switch snapshot.phase {
        case .start:
            AppCopy.firstCheckInHeadline
        case .active:
            AppCopy.daysTethered(snapshot.current)
        case .reconnect:
            AppCopy.reconnectHeadline
        }
    }

    var supportingCopy: String {
        if selectedState != nil {
            return completionMessage
        }

        switch snapshot.phase {
        case .start, .active:
            return AppCopy.todayPendingReminder
        case .reconnect:
            return AppCopy.reconnectSupportingCopy
        }
    }

    private let environment: AppEnvironment
    private var reminderReconciliationTask: Task<Void, Never>?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func load() {
        refresh()
    }

    func refresh() {
        do {
            try reloadPersistedState()
            errorMessage = nil
        } catch {
            errorMessage = AppCopy.todayLoadError
        }
    }

    func select(_ state: CheckInState) {
        guard saveSelection(state) else {
            return
        }
        reminderReconciliationTask = Task { @MainActor in
            await reconcileReminderAfterCheckIn()
        }
    }

    func selectAndReconcile(_ state: CheckInState) async {
        select(state)
        await reminderReconciliationTask?.value
    }

    func clearTodayCheckIn() {
        guard removeTodayCheckIn() else {
            return
        }
        reminderReconciliationTask = Task { @MainActor in
            await reconcileReminderAfterCheckIn()
        }
    }

    func clearTodayCheckInAndReconcile() async {
        clearTodayCheckIn()
        await reminderReconciliationTask?.value
    }

    private func saveSelection(_ state: CheckInState) -> Bool {
        do {
            let storedHabit = try environment.store.loadHabit()
            guard let storedHabit else {
                throw TetherStoreError.habitNotFound
            }

            let today = LocalDay(
                date: environment.dayProvider.now,
                calendar: environment.dayProvider.calendar
            )
            _ = try environment.store.upsertCheckIn(
                habitID: storedHabit.id,
                day: today,
                state: state,
                now: environment.dayProvider.now
            )
            try reloadPersistedState()
            errorMessage = nil
            return true
        } catch {
            try? reloadPersistedState()
            errorMessage = AppCopy.checkInSaveError
            return false
        }
    }

    private func removeTodayCheckIn() -> Bool {
        do {
            guard let storedHabit = try environment.store.loadHabit() else {
                throw TetherStoreError.habitNotFound
            }

            let today = LocalDay(
                date: environment.dayProvider.now,
                calendar: environment.dayProvider.calendar
            )
            try environment.store.deleteCheckIn(habitID: storedHabit.id, day: today)
            try reloadPersistedState()
            errorMessage = nil
            return true
        } catch {
            try? reloadPersistedState()
            errorMessage = AppCopy.checkInRemoveError
            return false
        }
    }

    private func reconcileReminderAfterCheckIn() async {
        let settings = environment.reminderSettingsStore.load()
        guard settings.isEnabled else {
            return
        }

        do {
            guard let storedHabit = try environment.store.loadHabit() else {
                throw TetherStoreError.habitNotFound
            }
            let checkedDays = Set(
                try environment.store.loadCheckIns(habitID: storedHabit.id).map(\.day)
            )
            try await environment.reminderScheduler.reconcile(
                settings: settings,
                now: environment.dayProvider.now,
                calendar: environment.dayProvider.calendar,
                checkedDays: checkedDays
            )
        } catch {
            errorMessage = "Couldn't update your reminder. Please try again."
        }
    }

    private func reloadPersistedState() throws {
        guard let storedHabit = try environment.store.loadHabit() else {
            habit = nil
            selectedState = nil
            snapshot = TetherSnapshot(
                current: 0,
                best: 0,
                phase: .start,
                isCheckedInToday: false
            )
            recentDays = []
            completionMessage = AppCopy.todayCompletedMessage
            return
        }

        let calendar = environment.dayProvider.calendar
        let today = LocalDay(date: environment.dayProvider.now, calendar: calendar)
        let checkIns = try environment.store.loadCheckIns(habitID: storedHabit.id)
        recentDays = HistoryBuilder.recentDays(
            habit: storedHabit,
            checkIns: checkIns,
            today: today,
            calendar: calendar
        )
        let todayCheckIn = checkIns
            .filter { $0.day == today }
            .max { $0.updatedAt < $1.updatedAt }
        let yesterday = today.adding(days: -1, calendar: calendar)
        let hasEarlierCheckIn = checkIns.contains { $0.day < today }
        let wasReconnect = todayCheckIn != nil
            && hasEarlierCheckIn
            && !checkIns.contains { $0.day == yesterday }

        habit = storedHabit
        selectedState = todayCheckIn?.state
        snapshot = TetherCalculator.snapshot(
            habitCreatedOn: LocalDay(
                date: storedHabit.createdAt,
                calendar: calendar
            ),
            checkIns: checkIns,
            today: today,
            calendar: calendar
        )
        completionMessage = wasReconnect
            ? AppCopy.reconnectCompletion
            : AppCopy.todayCompletedMessage
    }
}
