import Foundation
import SwiftData
import Testing
@testable import Tether

@MainActor
struct SwiftDataTetherStoreTests {
    @Test
    func emptyStoreReturnsNoHabit() throws {
        let fixture = try StoreFixture()

        #expect(try fixture.store.loadHabit() == nil)
    }

    @Test
    func creatingHabitReturnsAndReloadsIt() throws {
        let fixture = try StoreFixture()

        let created = try fixture.makeHabit()

        #expect(try fixture.store.loadHabit() == created)
    }

    @Test
    func creatingSecondHabitIsRejected() throws {
        let fixture = try StoreFixture()
        _ = try fixture.makeHabit()

        #expect(throws: TetherStoreError.habitAlreadyExists) {
            try fixture.store.createHabit(
                from: .init(
                    name: "Reading",
                    doneMeaning: "Read a chapter",
                    lightMeaning: "Read one page"
                ),
                now: fixture.now.addingTimeInterval(60)
            )
        }
    }

    @Test
    func updatingHabitPreservesIdentityAndCreationDate() throws {
        let fixture = try StoreFixture()
        let created = try fixture.makeHabit()
        let updateTime = fixture.now.addingTimeInterval(60)

        let updated = try fixture.store.updateHabit(
            id: created.id,
            from: .init(
                name: "Strength training",
                doneMeaning: "Complete the program",
                lightMeaning: "Do one set"
            ),
            now: updateTime
        )

        #expect(updated.id == created.id)
        #expect(updated.createdAt == created.createdAt)
        #expect(updated.updatedAt == updateTime)
        #expect(updated.name == "Strength training")
        #expect(try fixture.store.loadHabit() == updated)
    }

    @Test
    func upsertChangesStateWithoutDuplicatingDay() throws {
        let fixture = try StoreFixture()
        let habit = try fixture.makeHabit()
        let day = LocalDay(date: fixture.now, calendar: fixture.calendar)

        let created = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: day,
            state: .done,
            now: fixture.now
        )
        let updateTime = fixture.now.addingTimeInterval(60)
        let updated = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: day,
            state: .rest,
            now: updateTime
        )

        let records = try fixture.store.loadCheckIns(habitID: habit.id)
        #expect(records.count == 1)
        #expect(records.first?.id == created.id)
        #expect(records.first?.createdAt == created.createdAt)
        #expect(records.first?.updatedAt == updateTime)
        #expect(records.first?.state == .rest)
        #expect(updated == records.first)
    }

    @Test
    func differentDaysRemainSeparateRecords() throws {
        let fixture = try StoreFixture()
        let habit = try fixture.makeHabit()
        let firstDay = LocalDay(date: fixture.now, calendar: fixture.calendar)
        let secondDay = firstDay.adding(days: 1, calendar: fixture.calendar)

        _ = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: firstDay,
            state: .done,
            now: fixture.now
        )
        _ = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: secondDay,
            state: .light,
            now: fixture.now.addingTimeInterval(86_400)
        )

        let records = try fixture.store.loadCheckIns(habitID: habit.id)
        #expect(records.map(\.day) == [firstDay, secondDay])
        #expect(records.map(\.state) == [.done, .light])
    }

    @Test
    func deletingACheckInRemovesOnlyTheRequestedDay() throws {
        let fixture = try StoreFixture()
        let habit = try fixture.makeHabit()
        let today = LocalDay(date: fixture.now, calendar: fixture.calendar)
        let yesterday = today.adding(days: -1, calendar: fixture.calendar)

        _ = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: yesterday,
            state: .light,
            now: fixture.now.addingTimeInterval(-86_400)
        )
        _ = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: today,
            state: .done,
            now: fixture.now
        )

        try fixture.store.deleteCheckIn(habitID: habit.id, day: today)

        #expect(try fixture.store.loadCheckIns(habitID: habit.id).map(\.day) == [yesterday])
    }

    @Test
    func resetAllRemovesHabitAndCheckIns() throws {
        let fixture = try StoreFixture()
        let habit = try fixture.makeHabit()
        _ = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: LocalDay(date: fixture.now, calendar: fixture.calendar),
            state: .done,
            now: fixture.now
        )

        try fixture.store.resetAll()

        #expect(try fixture.store.loadHabit() == nil)
        #expect(try fixture.store.loadCheckIns(habitID: habit.id).isEmpty)
    }

    @Test
    func newContextOnSameContainerReadsSavedRecords() throws {
        let fixture = try StoreFixture()
        let habit = try fixture.makeHabit()
        let checkIn = try fixture.store.upsertCheckIn(
            habitID: habit.id,
            day: LocalDay(date: fixture.now, calendar: fixture.calendar),
            state: .light,
            now: fixture.now
        )

        let reloadedStore = SwiftDataTetherStore(
            context: ModelContext(fixture.container)
        )

        #expect(try reloadedStore.loadHabit() == habit)
        #expect(try reloadedStore.loadCheckIns(habitID: habit.id) == [checkIn])
    }
}

@MainActor
private struct StoreFixture {
    let container: ModelContainer
    let store: SwiftDataTetherStore
    let calendar: Calendar
    let now: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let now = try #require(
            calendar.date(from: DateComponents(
                year: 2026,
                month: 8,
                day: 17,
                hour: 9
            ))
        )
        let container = try TetherSchema.makeContainer(inMemory: true)

        self.container = container
        store = SwiftDataTetherStore(context: container.mainContext)
        self.calendar = calendar
        self.now = now
    }

    func makeHabit() throws -> Habit {
        try store.createHabit(
            from: .init(
                name: "Workout",
                doneMeaning: "Gym",
                lightMeaning: "Walk"
            ),
            now: now
        )
    }
}
