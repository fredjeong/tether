import Foundation
import UserNotifications

@MainActor
final class UserNotificationReminderScheduler: ReminderScheduling {
    static let identifierPrefix = "tether.daily."

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func permission() async -> NotificationPermission {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { @Sendable settings in
                continuation.resume(returning: Self.permission(
                    from: settings.authorizationStatus
                ))
            }
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: [.alert, .badge, .sound]) {
                @Sendable isGranted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: isGranted)
                }
            }
        }
    }

    func reconcile(
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar,
        checkedDays: Set<LocalDay>
    ) async throws {
        await removePendingTetherRequests()

        guard settings.isEnabled, await permission() == .authorized else {
            return
        }

        let plans = ReminderPlanBuilder.build(
            settings: settings,
            now: now,
            calendar: calendar,
            checkedDays: checkedDays
        )
        for plan in plans {
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: plan.dateComponents,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: plan.identifier,
                content: content,
                trigger: trigger
            )
            try await add(request)
        }
    }

    func cancelAll() async {
        await removePendingTetherRequests()
    }

    nonisolated static func permission(
        from status: UNAuthorizationStatus
    ) -> NotificationPermission {
        switch status {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .authorized, .provisional, .ephemeral:
            .authorized
        @unknown default:
            .denied
        }
    }

    private func removePendingTetherRequests() async {
        let prefix = Self.identifierPrefix
        let identifiers: [String] = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { @Sendable requests in
                continuation.resume(returning: requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(prefix) })
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, any Error>) in
            center.add(request) { @Sendable error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
