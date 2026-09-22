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

    var pluralLabel: String {
        switch self {
        case .film: String(localized: "kind.film.plural")
        case .series: String(localized: "kind.series.plural")
        case .book: String(localized: "kind.book.plural")
        case .album: String(localized: "kind.album.plural")
        case .podcast: String(localized: "kind.podcast.plural")
        case .game: String(localized: "kind.game.plural")
        case .concert: String(localized: "kind.concert.plural")
        case .theatre: String(localized: "kind.theatre.plural")
        case .exhibition: String(localized: "kind.exhibition.plural")
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

extension MediaKind {
    // « Vu le 12 mars » : le verbe suit le type.
    func loggedLabel(on date: Date) -> String {
        let day = date.formatted(.dateTime.day().month())
        switch self {
        case .film, .series, .concert, .theatre, .exhibition: return String(localized: "search.row.logged.seen \(day)")
        case .book: return String(localized: "search.row.logged.read \(day)")
        case .album, .podcast: return String(localized: "search.row.logged.listened \(day)")
        case .game: return String(localized: "search.row.logged.played \(day)")
        }
    }
}

extension MediaKind {
    // « Je l'ai vu » sur une envie : le verbe suit le type.
    var seenActionLabel: String {
        switch self {
        case .film, .series, .concert, .theatre, .exhibition: String(localized: "wishlist.seen.seen")
        case .book: String(localized: "wishlist.seen.read")
        case .album, .podcast: String(localized: "wishlist.seen.listened")
        case .game: String(localized: "wishlist.seen.played")
        }
    }
}
