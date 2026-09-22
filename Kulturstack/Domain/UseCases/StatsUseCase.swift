import Foundation

enum StatsUseCase {
    struct Counts: Equatable {
        let total: Int
        let byKind: [MediaKind: Int]
    }

    // T-16 : on compte des logs, pas des fiches — un film revu compte deux fois.
    static func count(_ rows: [JournalRowModel], period: Period, now: Date, calendar: Calendar) -> Counts {
        let kept = filter(rows, period: period, kind: nil, now: now, calendar: calendar)
        var byKind: [MediaKind: Int] = [:]
        for row in kept { byKind[row.kind, default: 0] += 1 }
        return Counts(total: kept.count, byKind: byKind)
    }

    static func filter(_ rows: [JournalRowModel], period: Period, kind: MediaKind?, now: Date, calendar: Calendar) -> [JournalRowModel] {
        let range = period.range(containing: now, calendar: calendar)
        return rows
            .filter { range?.contains($0.date) ?? true }
            .filter { kind == nil || $0.kind == kind }
            .sorted { $0.date > $1.date }
    }

    static func groupByDay(_ rows: [JournalRowModel], now: Date, calendar: Calendar) -> [JournalDaySection] {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        var sections: [JournalDaySection] = []
        for row in rows.sorted(by: { $0.date > $1.date }) {
            let day = calendar.startOfDay(for: row.date)
            if let last = sections.last, last.id == day {
                sections[sections.count - 1].rows.append(row)
            } else {
                sections.append(JournalDaySection(id: day, title: title(for: day, today: today, yesterday: yesterday, calendar: calendar), rows: [row]))
            }
        }
        return sections
    }

    private static func title(for day: Date, today: Date, yesterday: Date?, calendar: Calendar) -> String {
        if day == today { return String(localized: "journal.day.today") }
        if day == yesterday { return String(localized: "journal.day.yesterday") }
        let sameYear = calendar.component(.year, from: day) == calendar.component(.year, from: today)
        var format = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide)
        format.calendar = calendar
        format.timeZone = calendar.timeZone
        return sameYear ? day.formatted(format) : day.formatted(format.year())
    }
}
