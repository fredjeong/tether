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
        } catch {
            try? reloadPersistedState()
            errorMessage = AppCopy.checkInSaveError
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
            completionMessage = AppCopy.todayCompletedMessage
            return
        }

        let calendar = environment.dayProvider.calendar
        let today = LocalDay(date: environment.dayProvider.now, calendar: calendar)
        let checkIns = try environment.store.loadCheckIns(habitID: storedHabit.id)
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
