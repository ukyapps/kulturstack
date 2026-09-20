import Foundation

enum DetailsCodec {
    static let currentVersion = 1

    static func encode(_ payload: some DetailsPayload) throws -> Data {
        try JSONEncoder().encode(payload)
    }

    static func decode(kind: MediaKind, from data: Data) throws -> any DetailsPayload {
        let decoder = JSONDecoder()
        switch kind {
        case .film: return try decoder.decode(FilmDetails.self, from: data)
        case .series: return try decoder.decode(SeriesDetails.self, from: data)
        case .book: return try decoder.decode(BookDetails.self, from: data)
        case .album, .podcast, .game, .concert, .theatre, .exhibition:
            return try decoder.decode(GenericDetails.self, from: data)
        }
    }
}
