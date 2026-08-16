struct TetherSnapshot: Equatable, Sendable {
    let current: Int
    let best: Int
    let phase: ConnectionPhase
    let isCheckedInToday: Bool
}
