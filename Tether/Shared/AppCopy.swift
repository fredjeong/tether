enum AppCopy {
    static let productName = "Tether"
    static let productOneLiner = "A habit tracker where rest counts."

    static let welcomeHeadline = "Stay connected to who you want to become."
    static let welcomeSupportingCopy = "You don't have to do it perfectly every day. Done, Light, and Rest all keep the connection alive."
    static let welcomePrimaryAction = "Set up my habit"

    static let habitSetupTitle = "Set up your habit"
    static let habitNameLabel = "Habit name"
    static let habitNameExample = "Workout"
    static let doneMeaningLabel = "Done means"
    static let doneMeaningExample = "A full workout"
    static let lightMeaningLabel = "Light means"
    static let lightMeaningExample = "Move for 10 minutes"
    static let dailyReminderLabel = "Daily reminder"
    static let habitSetupSubmitAction = "Start my tether"
    static let habitSaveError = "Couldn't save your habit. Please try again."
    static let startupLoadError = "Couldn't load your habit. Please try again."
    static let retryAction = "Retry"

    static let todayPrompt = "How was today?"
    static let doneLabel = "Done"
    static let doneHelper = "I did what I planned."
    static let lightLabel = "Light"
    static let lightHelper = "I did a smaller version."
    static let restLabel = "Rest"
    static let restHelper = "I chose to rest today."
    static let todayPendingReminder = "You haven't checked in today."
    static let firstCheckInHeadline = "Start your tether today"
    static let todayCompletedMessage = "You're still connected."
    static let changeAction = "Change"
    static let checkInSaveError = "Couldn't save your check-in. Please try again."
    static let todayLoadError = "Couldn't load today's check-in. Please try again."

    static let reconnectHeadline = "Reconnect today"
    static let reconnectSupportingCopy = "The connection ended, but your habit is still here."
    static let reconnectCompletion = "Connected again."

    static let historyTitle = "History"
    static let currentTetherLabel = "Current Tether"
    static let bestTetherLabel = "Best Tether"
    static let missedStateLabel = "No check-in"
    static let historyEmptyState = "Your check-ins will appear here."

    static let settingsTitle = "Settings"
    static let habitSettingsSection = "Habit"
    static let editHabitAction = "Edit habit"
    static let aboutSettingsSection = "About"
    static let dataSettingsSection = "Data"
    static let saveAction = "Save"
    static let doneAction = "Done"
    static let settingsLoadError = "Couldn't load your habit. Please try again."
    static let habitChangesSaveError = "Couldn't save your changes. Please try again."
    static let resetError = "Couldn't reset your data. Please try again."
    static let reminderSettingsSection = "Reminder"
    static let notificationPermissionUnavailable = "Notifications are turned off in iOS Settings."
    static let openIOSSettingsAction = "Open iOS Settings"
    static let resetAllDataAction = "Reset all data"
    static let resetTitle = "Reset Tether?"
    static let resetBody = "This will permanently delete your habit and all check-ins from this iPhone."
    static let resetConfirmation = "Reset"
    static let cancelAction = "Cancel"

    static func versionBuild(version: String, build: String) -> String {
        "Version \(version) (\(build))"
    }

    static func daysTethered(_ count: Int) -> String {
        count == 1 ? "1 day tethered" : "\(count) days tethered"
    }
}
