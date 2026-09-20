import Foundation

protocol DetailsPayload: Codable, Sendable {
    static var kind: MediaKind { get }
}

struct FilmDetails: DetailsPayload, Equatable {
    static let kind = MediaKind.film
    var runtimeMinutes: Int?
    var genres: [String] = []
    var directors: [String] = []

    init(runtimeMinutes: Int? = nil, genres: [String] = [], directors: [String] = []) {
        self.runtimeMinutes = runtimeMinutes
        self.genres = genres
        self.directors = directors
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        runtimeMinutes = try c.decodeIfPresent(Int.self, forKey: .runtimeMinutes)
        genres = try c.decodeIfPresent([String].self, forKey: .genres) ?? []
        directors = try c.decodeIfPresent([String].self, forKey: .directors) ?? []
    }
}

struct SeriesDetails: DetailsPayload, Equatable {
    static let kind = MediaKind.series
    var seasonCount: Int?
    var episodeCount: Int?
    var status: String?
    var genres: [String] = []

    init(seasonCount: Int? = nil, episodeCount: Int? = nil, status: String? = nil, genres: [String] = []) {
        self.seasonCount = seasonCount
        self.episodeCount = episodeCount
        self.status = status
        self.genres = genres
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seasonCount = try c.decodeIfPresent(Int.self, forKey: .seasonCount)
        episodeCount = try c.decodeIfPresent(Int.self, forKey: .episodeCount)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        genres = try c.decodeIfPresent([String].self, forKey: .genres) ?? []
    }
}

struct BookDetails: DetailsPayload, Equatable {
    static let kind = MediaKind.book
    var pageCount: Int?
    var publisher: String?
    var firstPublishYear: Int?
    var subjects: [String] = []

    init(pageCount: Int? = nil, publisher: String? = nil, firstPublishYear: Int? = nil, subjects: [String] = []) {
        self.pageCount = pageCount
        self.publisher = publisher
        self.firstPublishYear = firstPublishYear
        self.subjects = subjects
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pageCount = try c.decodeIfPresent(Int.self, forKey: .pageCount)
        publisher = try c.decodeIfPresent(String.self, forKey: .publisher)
        firstPublishYear = try c.decodeIfPresent(Int.self, forKey: .firstPublishYear)
        subjects = try c.decodeIfPresent([String].self, forKey: .subjects) ?? []
    }
}

struct GenericDetails: DetailsPayload, Equatable {
    static let kind = MediaKind.exhibition
    var venue: String?
    var city: String?

    init(venue: String? = nil, city: String? = nil) {
        self.venue = venue
        self.city = city
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        venue = try c.decodeIfPresent(String.self, forKey: .venue)
        city = try c.decodeIfPresent(String.self, forKey: .city)
    }
}
