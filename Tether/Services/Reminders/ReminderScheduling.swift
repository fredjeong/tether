import Foundation

@MainActor
protocol ReminderScheduling: AnyObject {
    func permission() async -> NotificationPermission
    func requestAuthorization() async throws -> Bool
    func reconcile(
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar,
        checkedDays: Set<LocalDay>
    ) async throws
    func cancelAll() async
}

@MainActor
final class FakeReminderScheduler: ReminderScheduling {
    struct ReconcileCall: Equatable, Sendable {
        let settings: ReminderSettings
        let now: Date
        let calendar: Calendar
        let checkedDays: Set<LocalDay>
    }

    var permissionResult: NotificationPermission
    var authorizationResult: Bool
    var authorizationError: (any Error)?
    var reconcileError: (any Error)?

    private(set) var permissionCallCount = 0
    private(set) var authorizationRequestCount = 0
    private(set) var authorizationResults: [Bool] = []
    private(set) var reconcileCalls: [ReconcileCall] = []
    private(set) var cancelAllCallCount = 0

    init(
        permissionResult: NotificationPermission = .notDetermined,
        authorizationResult: Bool = true,
        authorizationError: (any Error)? = nil,
        reconcileError: (any Error)? = nil
    ) {
        self.permissionResult = permissionResult
        self.authorizationResult = authorizationResult
        self.authorizationError = authorizationError
        self.reconcileError = reconcileError
    }

    func permission() async -> NotificationPermission {
        permissionCallCount += 1
        return permissionResult
    }

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        if let authorizationError {
            throw authorizationError
        }
        authorizationResults.append(authorizationResult)
        return authorizationResult
    }

    func reconcile(
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar,
        checkedDays: Set<LocalDay>
    ) async throws {
        reconcileCalls.append(ReconcileCall(
            settings: settings,
            now: now,
            calendar: calendar,
            checkedDays: checkedDays
        ))
        if let reconcileError {
            throw reconcileError
        }
    }

    func cancelAll() async {
        cancelAllCallCount += 1
    }
}
