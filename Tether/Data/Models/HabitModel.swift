import Foundation
import SwiftData

@Model
final class HabitModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var doneMeaning: String
    var lightMeaning: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        doneMeaning: String,
        lightMeaning: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.doneMeaning = doneMeaning
        self.lightMeaning = lightMeaning
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(habit: Habit) {
        self.init(
            id: habit.id,
            name: habit.name,
            doneMeaning: habit.doneMeaning,
            lightMeaning: habit.lightMeaning,
            createdAt: habit.createdAt,
            updatedAt: habit.updatedAt
        )
    }

    var habit: Habit {
        Habit(
            id: id,
            name: name,
            doneMeaning: doneMeaning,
            lightMeaning: lightMeaning,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
