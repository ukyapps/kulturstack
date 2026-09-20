enum MediaKind: String, Codable, CaseIterable, Sendable {
    case film, series, book, album, podcast, game, concert, theatre, exhibition

    var hasEpisodes: Bool { self == .series || self == .podcast }

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
