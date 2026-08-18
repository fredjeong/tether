struct ReminderSettings: Equatable, Sendable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int

    static let defaultValue = ReminderSettings(
        isEnabled: false,
        hour: 20,
        minute: 0
    )
}
