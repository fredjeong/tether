protocol ReminderSettingsStoring: AnyObject {
    func load() -> ReminderSettings
    func save(_ settings: ReminderSettings)
    func reset()
}
