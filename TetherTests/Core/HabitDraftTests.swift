import Testing
@testable import Tether

struct HabitDraftTests {
    @Test func trimsValidInput() throws {
        let result = try HabitDraft(
            name: "\n  Workout  \t",
            doneMeaning: "  Full workout \r\n",
            lightMeaning: "\t Move for 10 minutes  \n"
        ).validated()

        #expect(result.name == "Workout")
        #expect(result.doneMeaning == "Full workout")
        #expect(result.lightMeaning == "Move for 10 minutes")
    }

    @Test(arguments: [
        HabitDraft(name: " ", doneMeaning: "Done", lightMeaning: "Light"),
        HabitDraft(name: "Workout", doneMeaning: " ", lightMeaning: "Light"),
        HabitDraft(name: "Workout", doneMeaning: "Done", lightMeaning: " ")
    ])
    func rejectsEmptyRequiredFields(_ draft: HabitDraft) {
        #expect(throws: HabitDraft.ValidationError.emptyField) {
            try draft.validated()
        }
    }

    @Test func enforcesNameCharacterLimit() {
        #expect(throws: HabitDraft.ValidationError.tooLong) {
            try HabitDraft(
                name: String(repeating: "a", count: 41),
                doneMeaning: "Done",
                lightMeaning: "Light"
            ).validated()
        }
    }

    @Test(arguments: [
        HabitDraft(
            name: "Workout",
            doneMeaning: String(repeating: "a", count: 81),
            lightMeaning: "Light"
        ),
        HabitDraft(
            name: "Workout",
            doneMeaning: "Done",
            lightMeaning: String(repeating: "a", count: 81)
        )
    ])
    func enforcesMeaningCharacterLimits(_ draft: HabitDraft) {
        #expect(throws: HabitDraft.ValidationError.tooLong) {
            try draft.validated()
        }
    }

    @Test func acceptsValuesAtCharacterLimits() throws {
        let draft = HabitDraft(
            name: String(repeating: "a", count: 40),
            doneMeaning: String(repeating: "b", count: 80),
            lightMeaning: String(repeating: "c", count: 80)
        )

        #expect(try draft.validated() == draft)
    }
}
