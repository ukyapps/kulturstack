import Foundation

struct TMDBSearchResponse: Decodable {
    let results: [TMDBSearchResult]
}

struct TMDBSearchResult: Decodable {
    let id: Int
    let mediaType: String
    let popularity: Double?
    let knownForDepartment: String?
    let job: String?
    let title: String?
    let name: String?
    let originalTitle: String?
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let firstAirDate: String?
}

// Les crédits d'une personne : mêmes champs qu'un résultat de recherche, en deux listes.
struct TMDBPersonCreditsResponse: Decodable {
    let cast: [TMDBSearchResult]?
    let crew: [TMDBSearchResult]?
}

struct TMDBMovieDetailsResponse: Decodable {
    struct Genre: Decodable { let name: String }
    struct Credits: Decodable {
        struct Crew: Decodable {
            let name: String
            let job: String?
        }
        let crew: [Crew]
    }
    let runtime: Int?
    let genres: [Genre]?
    let credits: Credits?
}

struct TMDBTVDetailsResponse: Decodable {
    struct Genre: Decodable { let name: String }
    struct Creator: Decodable { let name: String }
    struct Season: Decodable {
        let seasonNumber: Int
        let name: String?
        let episodeCount: Int?
        let airDate: String?
    }
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let status: String?
    let genres: [Genre]?
    let createdBy: [Creator]?
    let seasons: [Season]?
}

// GET /tv/{id}/season/{n} — le détail d'une saison, chargé seulement au dépliement.
struct TMDBSeasonResponse: Decodable {
    struct Episode: Decodable {
        let episodeNumber: Int
        let name: String?
        let airDate: String?
        let runtime: Int?
    }
    let episodes: [Episode]?
}
