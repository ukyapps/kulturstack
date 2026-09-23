import Foundation

struct TMDBProvider: MetadataProvider, DetailsProvider {
    static let baseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p/w342")!

    let id = "tmdb"
    let supportedKinds: Set<MediaKind> = [.film, .series]

    // Une personne loin dans la liste est un homonyme (« Aggy Dune » sur « dune ») : on ne va
    // chercher une filmographie que si TMDB reconnaît la personne tout de suite.
    private static let personLookupDepth = 3
    private static let maxPersonWorks = 20

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
        let response = try Self.decoder().decode(TMDBSearchResponse.self, from: data)
        let titles = response.results.compactMap { Self.candidate(from: $0) }
        guard let person = response.results.prefix(Self.personLookupDepth).first(where: { $0.mediaType == "person" })
        else { return titles }
        let works = (try? await filmography(of: person, token: token)) ?? []
        // Si TMDB met la personne en tête, c'est elle qu'on cherchait : son œuvre passe devant.
        return response.results.first?.mediaType == "person" ? Self.merge(works, titles) : Self.merge(titles, works)
    }

    // Une œuvre qui sort des deux côtés garde sa place dans la première liste.
    private static func merge(_ first: [MediaCandidate], _ second: [MediaCandidate]) -> [MediaCandidate] {
        let known = Set(first.map(\.id))
        return first + second.filter { !known.contains($0.id) }
    }

    // La filmographie de la personne, du plus populaire au moins populaire.
    private func filmography(of person: TMDBSearchResult, token: String) async throws -> [MediaCandidate] {
        var components = URLComponents(url: Self.baseURL.appending(path: "person/\(person.id)/combined_credits"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "language", value: language)]
        let data = try await client.get(components.url!, headers: [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ])
        let credits = try Self.decoder().decode(TMDBPersonCreditsResponse.self, from: data)
        var seen = Set<String>()
        return Self.works(credits, department: person.knownForDepartment)
            .sorted { $0.popularity ?? 0 > $1.popularity ?? 0 }
            .compactMap { Self.candidate(from: $0) }
            .filter { seen.insert($0.id).inserted }
            .prefix(Self.maxPersonWorks)
            .map { $0 }
    }

    // Un réalisateur cherché ramène ce qu'il a réalisé, pas les films où il double un personnage ;
    // une actrice, ce qu'elle a joué. Métier inconnu : tout, faute de mieux.
    private static func works(_ credits: TMDBPersonCreditsResponse, department: String?) -> [TMDBSearchResult] {
        switch department {
        case "Directing": (credits.crew ?? []).filter { $0.job == "Director" }
        case "Acting": credits.cast ?? []
        default: (credits.cast ?? []) + (credits.crew ?? [])
        }
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // Clés « tmdb:movie:<id> » et « tmdb:tv:<id> » seulement ; les autres ne sont pas à nous.
    func details(forKey key: String) async throws -> MediaEnrichment? {
        let parts = key.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3, parts[0] == id, ["movie", "tv"].contains(parts[1]), Int(parts[2]) != nil else { return nil }
        let token = try secrets.value(for: .tmdbReadToken)
        var components = URLComponents(url: Self.baseURL.appending(path: "\(parts[1])/\(parts[2])"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "language", value: language)]
        if parts[1] == "movie" {
            components.queryItems?.append(URLQueryItem(name: "append_to_response", value: "credits"))
        }
        let data = try await client.get(components.url!, headers: [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ])
        let decoder = Self.decoder()
        if parts[1] == "movie" {
            let movie = try decoder.decode(TMDBMovieDetailsResponse.self, from: data)
            let directors = (movie.credits?.crew ?? []).filter { $0.job == "Director" }.map(\.name)
            return MediaEnrichment(
                creators: directors,
                details: FilmDetails(runtimeMinutes: movie.runtime, genres: (movie.genres ?? []).map(\.name), directors: directors))
        }
        let show = try decoder.decode(TMDBTVDetailsResponse.self, from: data)
        return MediaEnrichment(
            creators: (show.createdBy ?? []).map(\.name),
            details: SeriesDetails(seasonCount: show.numberOfSeasons, episodeCount: show.numberOfEpisodes,
                                   status: show.status, genres: (show.genres ?? []).map(\.name)))
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
