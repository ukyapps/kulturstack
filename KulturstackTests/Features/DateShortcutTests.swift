import Foundation
import Testing
@testable import Kulturstack

struct DateShortcutTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 21, minute: Int = 40) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func todayIsNow() {
        let now = date(2026, 9, 23)
        #expect(DateShortcut.today.date(now: now, calendar: calendar) == now)
    }

    @Test func yesterdayKeepsTheTimeOfDay() {
        let now = date(2026, 9, 23)
        #expect(DateShortcut.yesterday.date(now: now, calendar: calendar) == date(2026, 9, 22))
    }

    @Test(arguments: [
        (date: (2026, 9, 23), saturday: (2026, 9, 19)),
        (date: (2026, 9, 21), saturday: (2026, 9, 19)),
        (date: (2026, 9, 20), saturday: (2026, 9, 19)),
        (date: (2026, 9, 19), saturday: (2026, 9, 19)),
        (date: (2026, 9, 25), saturday: (2026, 9, 19)),
    ])
    func weekendIsTheMostRecentSaturday(date: (Int, Int, Int), saturday: (Int, Int, Int)) {
        let now = self.date(date.0, date.1, date.2)
        let expected = self.date(saturday.0, saturday.1, saturday.2)
        #expect(DateShortcut.weekend.date(now: now, calendar: calendar) == expected)
    }

    @Test func everyShortcutHasALabel() {
        for shortcut in DateShortcut.allCases {
            #expect(!shortcut.label.isEmpty)
        }
    }
}
