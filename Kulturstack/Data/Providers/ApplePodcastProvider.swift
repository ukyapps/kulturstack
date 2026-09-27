import Foundation

// Le catalogue d'Apple Podcasts, en lecture seule et sans clé : c'est la même API publique
// que celle des liens « Écouter sur Apple Podcasts ». Elle cherche très bien en français.
struct ApplePodcastProvider: MetadataProvider {
    static let baseURL = URL(string: "https://itunes.apple.com/search")!

    let id = "apple"
    let supportedKinds: Set<MediaKind> = [.podcast]

    private let client: any HTTPClient
    private let country: String

    init(client: any HTTPClient, country: String = ApplePodcastProvider.preferredCountry()) {
        self.client = client
        self.country = country
    }

    // Le catalogue est par pays : « the daily » depuis la France et depuis les États-Unis
    // ne rendent pas la même chose.
    static func preferredCountry(locale: Locale = .current) -> String {
        locale.region?.identifier ?? "US"
    }

    func search(_ query: String) async throws -> [MediaCandidate] {
        var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: "20"),
        ]
        let data = try await client.get(components.url!, headers: ["Accept": "application/json"])
        let response = try JSONDecoder().decode(ApplePodcastSearchResponse.self, from: data)
        return response.results.compactMap(Self.candidate(from:))
    }

    private static func candidate(from result: ApplePodcastResult) -> MediaCandidate? {
        guard let collectionID = result.collectionId,
              let title = result.collectionName, !title.isEmpty else { return nil }
        let key = ExternalRef.key(provider: "itunes", value: String(collectionID))
        // Le flux vaut une clé externe : c'est par lui que les épisodes se chargeront, et deux
        // catalogues qui pointent le même flux désignent le même podcast.
        let feedKey = result.feedUrl.map { ExternalRef.key(provider: "feed", value: $0.absoluteString) }
        return MediaCandidate(
            id: key,
            kind: .podcast,
            title: title,
            originalTitle: nil,
            // Apple rend la date du dernier épisode, pas celle du podcast : elle afficherait
            // « 2026 » sur un podcast lancé en 2020. Mieux vaut rien que faux.
            year: nil,
            creators: [result.artistName].compactMap { $0 },
            coverURL: result.artworkUrl600 ?? result.artworkUrl100,
            summary: nil,
            externalKeys: [key] + [feedKey].compactMap { $0 },
            details: PodcastDetails(feedURL: result.feedUrl, episodeCount: result.trackCount,
                                    publisher: result.artistName, genre: result.primaryGenreName),
            providerID: "apple"
        )
    }
}
