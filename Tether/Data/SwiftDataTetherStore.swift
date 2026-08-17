import Foundation
import SwiftData

@MainActor
final class SwiftDataTetherStore: TetherStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadHabit() throws -> Habit? {
        var descriptor = FetchDescriptor<HabitModel>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first?.habit
    }

    func createHabit(from draft: HabitDraft, now: Date) throws -> Habit {
        guard try loadHabit() == nil else {
            throw TetherStoreError.habitAlreadyExists
        }

        let validatedDraft = try draft.validated()
        let habit = Habit(
            id: UUID(),
            name: validatedDraft.name,
            doneMeaning: validatedDraft.doneMeaning,
            lightMeaning: validatedDraft.lightMeaning,
            createdAt: now,
            updatedAt: now
        )
        context.insert(HabitModel(habit: habit))
        try saveOrRollback()

        return habit
    }

    func updateHabit(id: UUID, from draft: HabitDraft, now: Date) throws -> Habit {
        let requestedID = id
        var descriptor = FetchDescriptor<HabitModel>(
            predicate: #Predicate { $0.id == requestedID }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw TetherStoreError.habitNotFound
        }

        let validatedDraft = try draft.validated()
        model.name = validatedDraft.name
        model.doneMeaning = validatedDraft.doneMeaning
        model.lightMeaning = validatedDraft.lightMeaning
        model.updatedAt = now
        try saveOrRollback()

        return model.habit
    }

    func loadCheckIns(habitID: UUID) throws -> [DailyCheckIn] {
        let requestedHabitID = habitID
        let descriptor = FetchDescriptor<DailyCheckInModel>(
            predicate: #Predicate { $0.habitID == requestedHabitID },
            sortBy: [
                SortDescriptor(\.dayEra),
                SortDescriptor(\.dayYear),
                SortDescriptor(\.dayMonth),
                SortDescriptor(\.dayValue),
            ]
        )

        return try context.fetch(descriptor).map { try $0.checkIn() }
    }

    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn {
        guard try habitExists(id: habitID) else {
            throw TetherStoreError.habitNotFound
        }

        let uniqueDayKey = DailyCheckInModel.makeUniqueDayKey(
            habitID: habitID,
            day: day
        )
        var descriptor = FetchDescriptor<DailyCheckInModel>(
            predicate: #Predicate { $0.uniqueDayKey == uniqueDayKey }
        )
        descriptor.fetchLimit = 1

        let model: DailyCheckInModel
        if let existingModel = try context.fetch(descriptor).first {
            existingModel.stateRawValue = state.rawValue
            existingModel.updatedAt = now
            model = existingModel
        } else {
            let newModel = DailyCheckInModel(
                id: UUID(),
                habitID: habitID,
                day: day,
                state: state,
                createdAt: now,
                updatedAt: now
            )
            context.insert(newModel)
            model = newModel
        }

        try saveOrRollback()
        return try model.checkIn()
    }

    func resetAll() throws {
        for checkIn in try context.fetch(FetchDescriptor<DailyCheckInModel>()) {
            context.delete(checkIn)
        }
        for habit in try context.fetch(FetchDescriptor<HabitModel>()) {
            context.delete(habit)
        }

        try saveOrRollback()
    }

    private func habitExists(id: UUID) throws -> Bool {
        let requestedID = id
        var descriptor = FetchDescriptor<HabitModel>(
            predicate: #Predicate { $0.id == requestedID }
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first != nil
    }

    private func saveOrRollback() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
