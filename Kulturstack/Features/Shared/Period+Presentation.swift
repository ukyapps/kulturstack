import Foundation

extension Period {
    var label: String {
        switch self {
        case .week: String(localized: "period.week")
        case .month: String(localized: "period.month")
        case .year: String(localized: "period.year")
        case .all: String(localized: "period.all")
        }
    }

    // « cette semaine », « ce mois-ci »… pour les messages ; vide pour « tout ».
    var phrase: String {
        switch self {
        case .week: String(localized: "period.week.phrase")
        case .month: String(localized: "period.month.phrase")
        case .year: String(localized: "period.year.phrase")
        case .all: String(localized: "period.all.phrase")
        }
    }
}
