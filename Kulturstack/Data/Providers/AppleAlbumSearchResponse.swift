import Foundation

struct AppleAlbumSearchResponse: Decodable {
    let results: [AppleAlbumResult]
}

struct AppleAlbumResult: Decodable {
    let collectionId: Int?
    let collectionName: String?
    let artistName: String?
    // Apple ne rend que la vignette de 100 px sur un disque, là où un podcast en donne une de
    // 600 : c'est `AppleAlbumProvider` qui remonte l'adresse.
    let artworkUrl100: URL?
    let releaseDate: String?
    let trackCount: Int?
    let primaryGenreName: String?
}
