enum MediaKind: String, Codable, CaseIterable, Sendable {
    case film, series, book, album, podcast, game, concert, theatre, exhibition

    var hasEpisodes: Bool { self == .series || self == .podcast }

    // Une série se suit dans l'ordre, du premier épisode au dernier. Un podcast s'écoute par
    // le plus récent : sa « suite », c'est le dernier épisode pas encore écouté, pas le
    // premier. Les deux ont des épisodes, ils ne se reprennent pas par le même bout.
    var isFollowedInOrder: Bool { self == .series }

    // Un podcast n'a pas de fin : il publiera encore la semaine prochaine. Lui proposer
    // « terminé » parce qu'on a écouté ce que le flux contient n'aurait pas de sens.
    var hasAnEnd: Bool { self != .podcast }

    var hasDuration: Bool {
        switch self {
        case .series, .book, .podcast, .game: true
        case .film, .album, .concert, .theatre, .exhibition: false
        }
    }

    var allowedStatuses: [LogStatus] {
        hasDuration ? [.wishlist, .inProgress, .done, .dropped] : [.wishlist, .done]
    }

    var searchFamily: SearchFamily {
        switch self {
        case .film, .series: .screen
        case .book: .books
        case .album: .music
        case .podcast: .podcasts
        case .game: .games
        case .concert, .theatre, .exhibition: .live
        }
    }
}

enum SearchFamily: String, CaseIterable, Sendable {
    case screen, books, music, podcasts, games, live

    var kinds: [MediaKind] { MediaKind.allCases.filter { $0.searchFamily == self } }
}
