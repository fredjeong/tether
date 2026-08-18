struct HistoryDay: Identifiable, Equatable, Sendable {
    var id: String { day.storageKey }
    let day: LocalDay
    let state: CheckInState?
}

struct RecentCheckInDay: Identifiable, Equatable, Sendable {
    var id: String { day.storageKey }
    let day: LocalDay
    let state: CheckInState?
    let isBeforeHabitStarted: Bool
}
