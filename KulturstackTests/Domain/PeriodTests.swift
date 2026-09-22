import Foundation
import Testing
@testable import Kulturstack

struct PeriodTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        calendar.firstWeekday = 1
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }

    @Test(arguments: [(2026, 9, 23), (2026, 9, 21), (2026, 9, 27)])
    func weekRunsFromMondayToSundayWhateverTheLocaleSays(day: (Int, Int, Int)) throws {
        let now = date(day.0, day.1, day.2, hour: 15)
        let range = try #require(Period.week.range(containing: now, calendar: calendar))
        #expect(range.lowerBound == date(2026, 9, 21))
        #expect(range.upperBound == date(2026, 9, 28))
        #expect(range.contains(now))
    }

    @Test func monthAndYearCoverTheirWholeSpan() throws {
        let now = date(2026, 9, 23, hour: 15)
        let month = try #require(Period.month.range(containing: now, calendar: calendar))
        #expect(month.lowerBound == date(2026, 9, 1))
        #expect(month.upperBound == date(2026, 10, 1))
        let year = try #require(Period.year.range(containing: now, calendar: calendar))
        #expect(year.lowerBound == date(2026, 1, 1))
        #expect(year.upperBound == date(2027, 1, 1))
    }

    @Test func allHasNoBounds() {
        #expect(Period.all.range(containing: .now, calendar: calendar) == nil)
    }

    @Test func aLogAtMidnightSundayIsStillInTheWeekAndMondayMidnightIsNot() throws {
        let now = date(2026, 9, 23)
        let week = try #require(Period.week.range(containing: now, calendar: calendar))
        #expect(week.contains(date(2026, 9, 27, hour: 23, minute: 59, second: 59)))
        #expect(!week.contains(date(2026, 9, 28)))
        #expect(week.contains(date(2026, 9, 21)))
    }

    @Test func everyPeriodHasALabel() {
        for period in Period.allCases {
            #expect(!period.label.isEmpty)
        }
        #expect(Period.week.phrase != Period.month.phrase)
    }
}
