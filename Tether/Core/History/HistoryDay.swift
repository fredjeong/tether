struct HistoryDay: Identifiable, Equatable, Sendable {
    var id: String { day.storageKey }
    let day: LocalDay
    let state: CheckInState?
}
