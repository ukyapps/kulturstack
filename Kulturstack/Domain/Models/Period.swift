import Foundation

enum Period: CaseIterable, Sendable {
    case week, month, year, all

    // La semaine commence le lundi quelle que soit la locale ; « all » n'a pas de bornes.
    func range(containing now: Date, calendar: Calendar) -> Range<Date>? {
        var calendar = calendar
        calendar.firstWeekday = 2
        let component: Calendar.Component
        switch self {
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        case .all: return nil
        }
        guard let interval = calendar.dateInterval(of: component, for: now) else { return nil }
        return interval.start..<interval.end
    }
}
