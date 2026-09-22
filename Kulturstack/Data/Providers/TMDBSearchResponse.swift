import Foundation

struct TMDBSearchResponse: Decodable {
    let results: [TMDBSearchResult]
}

struct TMDBSearchResult: Decodable {
    let id: Int
    let mediaType: String
    let title: String?
    let name: String?
    let originalTitle: String?
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let firstAirDate: String?
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
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let status: String?
    let genres: [Genre]?
    let createdBy: [Creator]?
}
