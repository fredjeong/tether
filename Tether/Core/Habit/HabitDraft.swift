import Foundation

struct HabitDraft: Equatable, Sendable {
    enum ValidationError: Error, Equatable, Sendable {
        case emptyField
        case tooLong
    }

    var name: String
    var doneMeaning: String
    var lightMeaning: String

    func validated() throws -> HabitDraft {
        let result = HabitDraft(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            doneMeaning: doneMeaning.trimmingCharacters(in: .whitespacesAndNewlines),
            lightMeaning: lightMeaning.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        guard !result.name.isEmpty,
              !result.doneMeaning.isEmpty,
              !result.lightMeaning.isEmpty else {
            throw ValidationError.emptyField
        }

        guard result.name.count <= 40,
              result.doneMeaning.count <= 80,
              result.lightMeaning.count <= 80 else {
            throw ValidationError.tooLong
        }

        return result
    }
}
