import Foundation

enum DateShortcut: CaseIterable {
    case today, yesterday, weekend

    var label: String {
        switch self {
        case .today: String(localized: "log.edit.shortcut.today")
        case .yesterday: String(localized: "log.edit.shortcut.yesterday")
        case .weekend: String(localized: "log.edit.shortcut.weekend")
        }
    }

    // Garde l'heure du jour : seul le jour bouge.
    func date(now: Date = .now, calendar: Calendar = .current) -> Date {
        switch self {
        case .today:
            return now
        case .yesterday:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .weekend:
            let saturday = 7
            let weekday = calendar.component(.weekday, from: now)
            let daysBack = (weekday - saturday + 7) % 7
            return calendar.date(byAdding: .day, value: -daysBack, to: now) ?? now
        }
    }
}
