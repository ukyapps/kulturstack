import Foundation

// Les épisodes d'un podcast dont le catalogue d'Apple ne donne pas le flux. On demande son nom
// et son producteur à Apple, puis on lit le flux que sa page déclare — voir `RadioFrancePage`.
// Si la page ne le déclare pas, Podcast Index le connaît souvent (ADR-015). Le flux trouvé,
// c'est `RSSEpisodeProvider` qui fait le reste : il ne sait rien de tout ça.
struct RadioFranceEpisodeProvider: EpisodeProvider {
    static let lookupURL = URL(string: "https://itunes.apple.com/lookup")!
    static let keyPrefix = "itunes:"

    private let client: any HTTPClient
    private let userAgent: String
    private let country: String
    private let index: PodcastIndexFeedResolver?
    private let feeds: RSSEpisodeProvider
    private let resolved = ResolvedFeeds()

    init(client: any HTTPClient, userAgent: String, country: String = ApplePodcastProvider.preferredCountry(),
         index: PodcastIndexFeedResolver? = nil, freshness: TimeInterval = 60) {
        self.client = client
        self.userAgent = userAgent
        self.country = country
        self.index = index
        feeds = RSSEpisodeProvider(client: client, userAgent: userAgent, freshness: freshness)
    }

    func seasons(forKey key: String) async throws -> [SeasonSummary] {
        guard let feed = try await feedKey(for: key) else { return [] }
        return try await feeds.seasons(forKey: feed)
    }

    func episodes(forKey key: String, season: Int) async throws -> [EpisodeSummary] {
        guard let feed = try await feedKey(for: key) else { return [] }
        return try await feeds.episodes(forKey: feed, season: season)
    }

    // Une clé qui n'est pas un podcast Apple ne déclenche aucune requête : un podcast dont le
    // flux est connu porte une clé `feed:`, et c'est le flux qui répond pour lui.
    private func feedKey(for key: String) async throws -> String? {
        guard key.hasPrefix(Self.keyPrefix) else { return nil }
        let id = String(key.dropFirst(Self.keyPrefix.count))
        guard !id.isEmpty, id.allSatisfy(\.isNumber) else { return nil }
        if let known = await resolved.known(id) { return Self.key(of: known) }
        let feed = try await resolve(id)
        await resolved.store(feed, for: id)
        return Self.key(of: feed)
    }

    private static func key(of feed: URL?) -> String? {
        feed.map { RSSEpisodeProvider.keyPrefix + $0.absoluteString }
    }

    private func resolve(_ id: String) async throws -> URL? {
        guard let podcast = try await lookup(id) else { return nil }
        // Si Apple a le flux, c'est lui qui gagne : aucune page à lire.
        if let feed = podcast.feedUrl { return feed }
        let title = podcast.collectionName ?? ""
        // Un producteur qui n'est pas de Radio France n'a ni page à lire, ni rien à chercher
        // dans l'index : cette source ne couvre qu'eux.
        guard RadioFrancePage.isStation(podcast.artistName) else { return nil }
        for url in RadioFrancePage.urls(title: title, publisher: podcast.artistName) {
            do {
                let page = try await client.get(url, headers: ["User-Agent": userAgent, "Accept": "text/html"])
                if let feed = RadioFrancePage.feedURL(inPage: page) { return feed }
            } catch HTTPError.status(404) {
                // Cette orthographe de l'adresse n'existe pas ; les autres valent d'être essayées.
                // Toute autre panne remonte : une absence n'est pas une erreur de chargement.
                continue
            }
        }
        // La page n'a rien dit — soit elle n'existe pas, soit elle ne déclare pas son flux.
        // L'index, lui, l'a souvent : 22 fois sur 25 (ADR-015).
        return try await index?.feedURL(title: title, publisher: podcast.artistName)
    }

    private func lookup(_ id: String) async throws -> ApplePodcastResult? {
        var components = URLComponents(url: Self.lookupURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "entity", value: "podcast"),
            // Le même catalogue que la recherche : un podcast n'a pas le même nom partout.
            URLQueryItem(name: "country", value: country),
        ]
        let data = try await client.get(components.url!, headers: ["Accept": "application/json"])
        return try JSONDecoder().decode(ApplePodcastSearchResponse.self, from: data).results.first
    }
}

// La page pèse 450 Ko et la réponse ne change pas d'une visite à l'autre : on la retient, y
// compris quand c'est une absence — sinon un podcast sans page la rechercherait à chaque fois.
private actor ResolvedFeeds {
    private var feeds: [String: URL?] = [:]

    func known(_ id: String) -> URL?? { feeds.index(forKey: id).map { feeds[$0].value } }

    func store(_ feed: URL?, for id: String) { feeds[id] = feed }
}
