import Foundation

extension SearchFamily {
    var label: String {
        switch self {
        case .screen: String(localized: "family.screen")
        case .books: String(localized: "family.books")
        case .music: String(localized: "family.music")
        case .podcasts: String(localized: "family.podcasts")
        case .games: String(localized: "family.games")
        case .live: String(localized: "family.live")
        }
    }
}
