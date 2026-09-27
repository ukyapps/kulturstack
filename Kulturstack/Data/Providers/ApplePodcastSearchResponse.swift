import Foundation

struct ApplePodcastSearchResponse: Decodable {
    let results: [ApplePodcastResult]
}

struct ApplePodcastResult: Decodable {
    let collectionId: Int?
    let collectionName: String?
    let artistName: String?
    let feedUrl: URL?
    let artworkUrl600: URL?
    let artworkUrl100: URL?
    let trackCount: Int?
    let primaryGenreName: String?
}
