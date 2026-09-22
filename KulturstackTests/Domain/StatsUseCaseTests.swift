import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct StatsUseCaseTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeRows() throws -> (ModelContainer, [JournalRowModel]) {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        let book = MediaItem(kind: .book, title: "Dune")
        let series = MediaItem(kind: .series, title: "Severance")
        for item in [dune, book, series] { context.insert(item) }
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 22)),
            try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 21)),
            try LogEntry.make(item: book, status: .done, date: date(2026, 9, 15)),
            try LogEntry.make(item: series, status: .done, date: date(2026, 8, 30)),
            try LogEntry.make(item: book, status: .done, date: date(2025, 12, 31)),
        ]
        for log in logs { context.insert(log) }
        return (container, logs.map(JournalRowModel.init))
    }

    @Test func countsLogsNotItemsARewatchCountsTwice() throws {
        let (container, rows) = try makeRows()
        let now = date(2026, 9, 23)

        let week = StatsUseCase.count(rows, period: .week, now: now, calendar: calendar)
        #expect(week.total == 2)
        #expect(week.byKind == [.film: 2])

        let month = StatsUseCase.count(rows, period: .month, now: now, calendar: calendar)
        #expect(month.total == 3)
        #expect(month.byKind == [.film: 2, .book: 1])

        let year = StatsUseCase.count(rows, period: .year, now: now, calendar: calendar)
        #expect(year.total == 4)
        #expect(year.byKind == [.film: 2, .book: 1, .series: 1])

        let all = StatsUseCase.count(rows, period: .all, now: now, calendar: calendar)
        #expect(all.total == 5)
        #expect(all.byKind == [.film: 2, .book: 2, .series: 1])
        withExtendedLifetime(container) {}
    }

    @Test func filterKeepsRowsOfThePeriodAndKindNewestFirst() throws {
        let (container, rows) = try makeRows()
        let now = date(2026, 9, 23)

        let books = StatsUseCase.filter(rows, period: .year, kind: .book, now: now, calendar: calendar)
        #expect(books.map(\.date) == [date(2026, 9, 15)])

        let month = StatsUseCase.filter(rows, period: .month, kind: nil, now: now, calendar: calendar)
        #expect(month.map(\.date) == [date(2026, 9, 22), date(2026, 9, 21), date(2026, 9, 15)])
        withExtendedLifetime(container) {}
    }

    @Test func groupsRowsByDayWithTodayAndYesterdayFirst() throws {
        let (container, rows) = try makeRows()
        let now = date(2026, 9, 22)

        let sections = StatsUseCase.groupByDay(rows, now: now, calendar: calendar)

        #expect(sections.count == 5)
        #expect(sections[0].title == String(localized: "journal.day.today"))
        #expect(sections[1].title == String(localized: "journal.day.yesterday"))
        #expect(sections[2].title.contains("15"))
        #expect(sections[4].title.contains("2025"))
        #expect(sections.map(\.rows.count) == [1, 1, 1, 1, 1])
        withExtendedLifetime(container) {}
    }
}
