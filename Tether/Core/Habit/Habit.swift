import Foundation

struct Habit: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var doneMeaning: String
    var lightMeaning: String
    let createdAt: Date
    var updatedAt: Date
}
