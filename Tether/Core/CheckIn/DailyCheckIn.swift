import Foundation

struct DailyCheckIn: Identifiable, Equatable, Sendable {
    let id: UUID
    let habitID: UUID
    let day: LocalDay
    var state: CheckInState
    let createdAt: Date
    var updatedAt: Date
}
