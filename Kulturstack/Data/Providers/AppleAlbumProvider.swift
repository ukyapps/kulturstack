import Foundation

// Le catalogue musical d'Apple, en lecture seule et sans clé : la même API publique que celle
// des podcasts, interrogée avec `media=music`. Mesurée le 17/10 sur 25 albums (ADR-016).
struct AppleAlbumProvider: MetadataProvider {
    static let baseURL = URL(string: "https://itunes.apple.com/search")!

    let id = "apple-music"
    let supportedKinds: Set<MediaKind> = [.album]

    private let client: any HTTPClient
    private let country: String

    init(client: any HTTPClient, country: String = ApplePodcastProvider.preferredCountry()) {
        self.client = client
        self.country = country
    }

    func search(_ query: String) async throws -> [MediaCandidate] {
        var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "album"),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: "20"),
        ]
        let data = try await client.get(components.url!, headers: ["Accept": "application/json"])
        let response = try JSONDecoder().decode(AppleAlbumSearchResponse.self, from: data)
        return response.results.compactMap(Self.candidate(from:))
    }

    private static func candidate(from result: AppleAlbumResult) -> MediaCandidate? {
        guard let collectionID = result.collectionId,
              let title = result.collectionName, !title.isEmpty else { return nil }
        // Les podcasts portent `itunes:<id>` depuis la T4a. Nommer le type ici plutôt que de
        // préfixer les leurs évite de réécrire des clés déjà dans la base de la founder.
        let key = ExternalRef.key(provider: "itunes", value: "album:\(collectionID)")
        return MediaCandidate(
            id: key,
            kind: .album,
            title: title,
            originalTitle: nil,
            year: result.releaseDate.flatMap { Int($0.prefix(4)) },
            creators: [result.artistName].compactMap { $0 },
            coverURL: result.artworkUrl100.map(cover(from:)),
            summary: nil,
            externalKeys: [key],
            details: AlbumDetails(trackCount: result.trackCount, genre: result.primaryGenreName),
            providerID: "apple-music"
        )
    }

    // Une jaquette de 100 px tiendrait mal sur une fiche. L'adresse d'Apple porte sa taille :
    // la réécrire en 600 rend une vraie image de 600 × 600 (vérifié le 17/10). Une adresse qui
    // ne suit pas le gabarit est gardée telle quelle — la vignette vaut mieux que rien.
    private static func cover(from thumbnail: URL) -> URL {
        let raised = thumbnail.absoluteString.replacingOccurrences(of: "/100x100bb", with: "/600x600bb")
        return URL(string: raised) ?? thumbnail
    }
}
