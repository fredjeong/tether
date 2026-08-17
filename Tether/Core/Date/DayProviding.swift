import Foundation

protocol DayProviding: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}

struct SystemDayProvider: DayProviding {
    var now: Date { Date() }
    var calendar: Calendar { .autoupdatingCurrent }
}

struct FixedDayProvider: DayProviding {
    let now: Date
    let calendar: Calendar
}
