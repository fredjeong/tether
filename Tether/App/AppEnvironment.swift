import Foundation

@MainActor
struct AppEnvironment {
    let store: any TetherStore
    let dayProvider: any DayProviding
    let reminderScheduler: any ReminderScheduling
    let reminderSettingsStore: any ReminderSettingsStoring

    init(
        store: any TetherStore,
        dayProvider: any DayProviding,
        reminderScheduler: (any ReminderScheduling)? = nil,
        reminderSettingsStore: any ReminderSettingsStoring = UserDefaultsReminderSettingsStore()
    ) {
        self.store = store
        self.dayProvider = dayProvider
        self.reminderScheduler = reminderScheduler ?? Self.defaultReminderScheduler()
        self.reminderSettingsStore = reminderSettingsStore
    }

    private static func defaultReminderScheduler() -> any ReminderScheduling {
        let environment = ProcessInfo.processInfo.environment
        let isUITesting = CommandLine.arguments.contains {
            $0.hasPrefix("-ui-testing-")
        }
        if isUITesting
            || environment["XCTestConfigurationFilePath"] != nil
            || environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return FakeReminderScheduler()
        }
        return UserNotificationReminderScheduler()
    }
}
