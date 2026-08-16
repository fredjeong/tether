import Foundation

struct LocalDay: Hashable, Comparable, Codable, Sendable {
    let era: Int
    let year: Int
    let month: Int
    let day: Int

    init(era: Int, year: Int, month: Int, day: Int) {
        self.era = era
        self.year = year
        self.month = month
        self.day = day
    }

    init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        era = components.era ?? 1
        year = components.year ?? 1
        month = components.month ?? 1
        day = components.day ?? 1
    }

    var storageKey: String {
        String(format: "%d-%04d-%02d-%02d", era, year, month, day)
    }

    func adding(days: Int, calendar: Calendar) -> LocalDay {
        var components = DateComponents()
        components.era = era
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12

        guard
            let noon = calendar.date(from: components),
            let result = calendar.date(byAdding: .day, value: days, to: noon)
        else {
            return self
        }

        return LocalDay(date: result, calendar: calendar)
    }

    static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        if lhs.era != rhs.era { return lhs.era < rhs.era }
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}
