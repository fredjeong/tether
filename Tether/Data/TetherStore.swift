import Foundation

enum TetherStoreError: Error, Equatable, Sendable {
    case habitAlreadyExists
    case habitNotFound
    case invalidStoredCheckInState(String)
}

@MainActor
protocol TetherStore: AnyObject {
    func loadHabit() throws -> Habit?
    func createHabit(from draft: HabitDraft, now: Date) throws -> Habit
    func updateHabit(id: UUID, from draft: HabitDraft, now: Date) throws -> Habit
    func loadCheckIns(habitID: UUID) throws -> [DailyCheckIn]
    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn
    func deleteCheckIn(habitID: UUID, day: LocalDay) throws
    func resetAll() throws
}
