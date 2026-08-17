import Foundation
import SwiftData

@Model
final class DailyCheckInModel {
    @Attribute(.unique) var id: UUID
    var habitID: UUID
    var dayKey: String
    var dayEra: Int
    var dayYear: Int
    var dayMonth: Int
    var dayValue: Int
    var stateRawValue: String
    var createdAt: Date
    var updatedAt: Date
    @Attribute(.unique) var uniqueDayKey: String

    init(
        id: UUID,
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.habitID = habitID
        dayKey = day.storageKey
        dayEra = day.era
        dayYear = day.year
        dayMonth = day.month
        dayValue = day.day
        stateRawValue = state.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        uniqueDayKey = Self.makeUniqueDayKey(habitID: habitID, day: day)
    }

    var day: LocalDay {
        LocalDay(
            era: dayEra,
            year: dayYear,
            month: dayMonth,
            day: dayValue
        )
    }

    func checkIn() throws -> DailyCheckIn {
        guard let state = CheckInState(rawValue: stateRawValue) else {
            throw TetherStoreError.invalidStoredCheckInState(stateRawValue)
        }

        return DailyCheckIn(
            id: id,
            habitID: habitID,
            day: day,
            state: state,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeUniqueDayKey(habitID: UUID, day: LocalDay) -> String {
        habitID.uuidString.lowercased() + "|" + day.storageKey
    }
}
