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

// Le vocabulaire des épisodes n'est pas le même pour une série et pour un podcast. Une série
// a des saisons qu'on regarde ; un podcast a une liste qu'on écoute, du plus récent au plus
// ancien. Les mots suivent (retour du 27/09 : « les podcasts et tout »).
extension MediaKind {
    // Un podcast n'a qu'une saison, implicite : l'afficher serait du bruit. C'est la même
    // frontière que « se suit dans l'ordre » — une seule définition, pas deux.
    var showsSeasons: Bool { isFollowedInOrder }

    var episodesSectionTitle: String {
        showsSeasons ? String(localized: "series.seasons.title") : String(localized: "podcast.episodes.title")
    }

    var checkEverythingLabel: String {
        showsSeasons ? String(localized: "series.season.checkAll") : String(localized: "podcast.checkAll")
    }

    var dropLabel: String {
        showsSeasons ? String(localized: "series.drop") : String(localized: "podcast.drop")
    }

    var resumeLabel: String {
        showsSeasons ? String(localized: "series.resume") : String(localized: "podcast.resume")
    }

    var statusMenuLabel: String {
        showsSeasons ? String(localized: "series.status.menu") : String(localized: "podcast.status.menu")
    }

    var uncheckEverythingTitle: String {
        showsSeasons ? String(localized: "series.season.uncheck.title") : String(localized: "podcast.uncheck.title")
    }

    var uncheckEverythingMessage: String {
        showsSeasons ? String(localized: "series.season.uncheck.message") : String(localized: "podcast.uncheck.message")
    }

    var noEpisodesTitle: String {
        showsSeasons ? String(localized: "series.seasons.empty.title") : String(localized: "podcast.episodes.empty.title")
    }

    var noEpisodesMessage: String {
        showsSeasons ? String(localized: "series.seasons.empty.message") : String(localized: "podcast.episodes.empty.message")
    }

    var episodesFailedTitle: String {
        showsSeasons ? String(localized: "series.seasons.failed.title") : String(localized: "podcast.episodes.failed.title")
    }
}
