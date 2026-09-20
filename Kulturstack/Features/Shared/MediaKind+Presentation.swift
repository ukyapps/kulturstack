import Foundation

extension MediaKind {
    var label: String {
        switch self {
        case .film: String(localized: "kind.film")
        case .series: String(localized: "kind.series")
        case .book: String(localized: "kind.book")
        case .album: String(localized: "kind.album")
        case .podcast: String(localized: "kind.podcast")
        case .game: String(localized: "kind.game")
        case .concert: String(localized: "kind.concert")
        case .theatre: String(localized: "kind.theatre")
        case .exhibition: String(localized: "kind.exhibition")
        }
    }

    var symbol: String {
        switch self {
        case .film: "film"
        case .series: "tv"
        case .book: "book.closed"
        case .album: "opticaldisc"
        case .podcast: "mic"
        case .game: "gamecontroller"
        case .concert: "music.mic"
        case .theatre: "theatermasks"
        case .exhibition: "photo.artframe"
        }
    }
}
