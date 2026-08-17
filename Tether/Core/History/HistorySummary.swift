struct HistorySummary: Equatable, Sendable {
    let current: Int
    let best: Int
    let doneCount: Int
    let lightCount: Int
    let restCount: Int
    let days: [HistoryDay]
}
