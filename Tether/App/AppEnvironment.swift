import Foundation
import SwiftUI
import UIKit

enum ThemePreference: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: AppCopy.systemAppearanceLabel
        case .light: AppCopy.lightAppearanceLabel
        case .dark: AppCopy.darkAppearanceLabel
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

protocol ThemePreferenceStoring: AnyObject {
    func load() -> ThemePreference
    func save(_ preference: ThemePreference)
    func reset()
}

final class UserDefaultsThemePreferenceStore: ThemePreferenceStoring {
    private enum Key {
        static let preference = "appearance.preference"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> ThemePreference {
        guard let rawValue = userDefaults.string(forKey: Key.preference),
              let preference = ThemePreference(rawValue: rawValue) else {
            return .light
        }
        return preference
    }

    func save(_ preference: ThemePreference) {
        userDefaults.set(preference.rawValue, forKey: Key.preference)
    }

    func reset() {
        userDefaults.removeObject(forKey: Key.preference)
    }
}

enum TetherTheme {
    static let canvas = adaptive(light: 0xF8F4EC, dark: 0x0D111B)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x1A202B)
    static let textPrimary = adaptive(light: 0x172235, dark: 0xF7F5F0)
    static let textSecondary = adaptive(light: 0x5E6878, dark: 0xB7BAC5)
    static let separator = adaptive(light: 0xE4DED5, dark: 0x303744)
    static let accent = adaptive(light: 0x5C5BB4, dark: 0x8D8CFF)
    static let done = adaptive(light: 0x2C7754, dark: 0x54D28A)
    static let light = adaptive(light: 0xA86D20, dark: 0xF0BA52)
    static let rest = adaptive(light: 0x5A5BB7, dark: 0x9391FF)
    static let missed = adaptive(light: 0x717988, dark: 0x949AA7)

    private static func adaptive(light: Int, dark: Int) -> Color {
        Color(uiColor: UIColor { traits in
            color(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    private static func color(_ rgb: Int) -> UIColor {
        UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

@MainActor
struct AppEnvironment {
    let store: any TetherStore
    let dayProvider: any DayProviding
    let reminderScheduler: any ReminderScheduling
    let reminderSettingsStore: any ReminderSettingsStoring
    let themePreferenceStore: any ThemePreferenceStoring

    init(
        store: any TetherStore,
        dayProvider: any DayProviding,
        reminderScheduler: (any ReminderScheduling)? = nil,
        reminderSettingsStore: any ReminderSettingsStoring = UserDefaultsReminderSettingsStore(),
        themePreferenceStore: any ThemePreferenceStoring = UserDefaultsThemePreferenceStore()
    ) {
        self.store = store
        self.dayProvider = dayProvider
        self.reminderScheduler = reminderScheduler ?? Self.defaultReminderScheduler()
        self.reminderSettingsStore = reminderSettingsStore
        self.themePreferenceStore = themePreferenceStore
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
