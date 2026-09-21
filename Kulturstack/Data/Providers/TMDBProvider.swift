import Foundation

struct TMDBProvider: MetadataProvider {
    static let baseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p/w342")!

    let id = "tmdb"
    let supportedKinds: Set<MediaKind> = [.film, .series]

    private let secrets: any SecretsProviding
    private let client: any HTTPClient
    private let language: String

    init(secrets: any SecretsProviding, client: any HTTPClient, language: String = language(for: .current)) {
        self.secrets = secrets
        self.client = client
        self.language = language
    }

    static func language(for locale: Locale) -> String {
        locale.language.languageCode?.identifier == "fr" ? "fr-FR" : "en-US"
    }

    func search(_ query: String) async throws -> [MediaCandidate] {
        let token = try secrets.value(for: .tmdbReadToken)
        var components = URLComponents(url: Self.baseURL.appending(path: "search/multi"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: "1"),
        ]
        let data = try await client.get(components.url!, headers: [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(TMDBSearchResponse.self, from: data)
        return response.results.compactMap { Self.candidate(from: $0) }
    }

    private static func candidate(from result: TMDBSearchResult) -> MediaCandidate? {
        let kind: MediaKind
        let title: String?
        let originalTitle: String?
        let date: String?
        let details: any DetailsPayload
        switch result.mediaType {
        case "movie":
            (kind, title, originalTitle, date) = (.film, result.title, result.originalTitle, result.releaseDate)
            details = FilmDetails()
        case "tv":
            (kind, title, originalTitle, date) = (.series, result.name, result.originalName, result.firstAirDate)
            details = SeriesDetails()
        default:
            return nil
        }
        guard let title, !title.isEmpty else { return nil }
        let key = ExternalRef.key(provider: "tmdb", value: "\(result.mediaType):\(result.id)")
        return MediaCandidate(
            id: key,
            kind: kind,
            title: title,
            originalTitle: originalTitle,
            year: date.flatMap { Int($0.prefix(4)) },
            creators: [],
            coverURL: result.posterPath.map { Self.imageBaseURL.appending(path: $0) },
            summary: result.overview.flatMap { $0.isEmpty ? nil : $0 },
            externalKeys: [key],
            details: details,
            providerID: "tmdb"
        )
    }
}
