import Foundation

enum StatsUseCase {
    struct Counts: Equatable {
        let total: Int
        let byKind: [MediaKind: Int]
    }

    // T-16, retournée le 30/09 : on compte des œuvres, pas des logs. Le compteur dit ce que
    // la liste montre — un film revu occupe une ligne, il compte pour un.
    static func count(_ rows: [JournalRowModel], period: Period, now: Date, calendar: Calendar) -> Counts {
        let kept = groupByItem(filter(rows, period: period, kind: nil, now: now, calendar: calendar))
        var byKind: [MediaKind: Int] = [:]
        for row in kept { byKind[row.kind, default: 0] += 1 }
        return Counts(total: kept.count, byKind: byKind)
    }

    // Une envie n'est pas une consommation : elle ne compte pas et n'apparaît pas dans le journal daté.
    static func filter(_ rows: [JournalRowModel], period: Period, kind: MediaKind?, now: Date, calendar: Calendar) -> [JournalRowModel] {
        let range = period.range(containing: now, calendar: calendar)
        return rows
            .filter { $0.status != .wishlist }
            .filter { range?.contains($0.date) ?? true }
            .filter { kind == nil || $0.kind == kind }
            .sorted(by: JournalRowModel.newestFirst)
    }

    // « Une œuvre = une seule fiche dans le journal » (founder, 30/09). Le regroupement vient
    // après le filtre, jamais avant : une œuvre vue cette semaine et l'an dernier appartient
    // à « Semaine », datée de cette semaine. Un log orphelin n'a pas d'œuvre à partager —
    // il reste sa propre ligne plutôt que de se confondre avec les autres orphelins.
    static func groupByItem(_ rows: [JournalRowModel]) -> [JournalRowModel] {
        var order: [UUID] = []
        var groups: [UUID: [JournalRowModel]] = [:]
        for row in rows.sorted(by: JournalRowModel.newestFirst) {
            let key = row.itemID ?? row.id
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(row)
        }
        return order.compactMap { key in groups[key].flatMap(JournalRowModel.init(group:)) }
    }

    // Une envie est en attente tant que l'œuvre n'a pas été consommée après ; l'envie elle-même reste dans l'historique (ADR-006).
    static func pendingWishes(_ rows: [JournalRowModel]) -> [JournalRowModel] {
        rows
            .filter { $0.status == .wishlist }
            .filter { wish in
                !rows.contains { $0.status != .wishlist && $0.itemID == wish.itemID && $0.date >= wish.date }
            }
            .sorted(by: JournalRowModel.newestFirst)
    }

    static func groupByDay(_ rows: [JournalRowModel], now: Date, calendar: Calendar) -> [JournalDaySection] {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        var sections: [JournalDaySection] = []
        for row in rows.sorted(by: JournalRowModel.newestFirst) {
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
