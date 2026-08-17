import Foundation

final class UserDefaultsReminderSettingsStore: ReminderSettingsStoring {
    private enum Key {
        static let isEnabled = "reminder.enabled"
        static let hour = "reminder.hour"
        static let minute = "reminder.minute"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> ReminderSettings {
        ReminderSettings(
            isEnabled: userDefaults.object(forKey: Key.isEnabled) == nil
                ? ReminderSettings.defaultValue.isEnabled
                : userDefaults.bool(forKey: Key.isEnabled),
            hour: userDefaults.object(forKey: Key.hour) == nil
                ? ReminderSettings.defaultValue.hour
                : userDefaults.integer(forKey: Key.hour),
            minute: userDefaults.object(forKey: Key.minute) == nil
                ? ReminderSettings.defaultValue.minute
                : userDefaults.integer(forKey: Key.minute)
        )
    }

    func save(_ settings: ReminderSettings) {
        userDefaults.set(settings.isEnabled, forKey: Key.isEnabled)
        userDefaults.set(settings.hour, forKey: Key.hour)
        userDefaults.set(settings.minute, forKey: Key.minute)
    }

    func reset() {
        userDefaults.removeObject(forKey: Key.isEnabled)
        userDefaults.removeObject(forKey: Key.hour)
        userDefaults.removeObject(forKey: Key.minute)
    }
}
