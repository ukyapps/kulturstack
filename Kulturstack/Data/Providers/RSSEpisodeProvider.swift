import Foundation

// Les épisodes d'un podcast viennent de son flux RSS. Une seule requête par consultation :
// le flux pèse 250 à 500 Ko et porte à la fois la liste et les métadonnées.
struct RSSEpisodeProvider: EpisodeProvider {
    // Un flux long ne remplit pas la base : on garde les plus récents, ceux qu'on écoute.
    static let maxEpisodes = 300
    static let keyPrefix = "feed:"

    private let client: any HTTPClient
    private let userAgent: String
    private let cache: FeedCache

    init(client: any HTTPClient, userAgent: String, freshness: TimeInterval = 60) {
        self.client = client
        self.userAgent = userAgent
        cache = FeedCache(freshness: freshness)
    }

    // Un podcast n'a pas de saisons : il en a une, implicite, qui porte tous ses épisodes.
    // L'écran ne l'affiche pas — il montre la liste à plat.
    func seasons(forKey key: String) async throws -> [SeasonSummary] {
        let episodes = try await load(key)
        guard !episodes.isEmpty else { return [] }
        return [SeasonSummary(number: 1, title: nil, episodeCount: episodes.count,
                              airDate: episodes.first?.airDate)]
    }

    func episodes(forKey key: String, season: Int) async throws -> [EpisodeSummary] {
        try await load(key)
    }

    // Une clé qui n'est pas un flux ne déclenche aucune requête : TMDB répond pour les séries.
    private func load(_ key: String) async throws -> [EpisodeSummary] {
        guard key.hasPrefix(Self.keyPrefix),
              let url = URL(string: String(key.dropFirst(Self.keyPrefix.count))),
              url.scheme?.hasPrefix("http") == true else { return [] }
        if let known = await cache.episodes(for: key) { return known }
        let data = try await client.get(url, headers: [
            "User-Agent": userAgent,
            "Accept": "application/rss+xml, application/xml",
        ])
        let episodes = RSSFeedParser.parse(data, limit: Self.maxEpisodes)
        await cache.store(episodes, for: key)
        return episodes
    }
}

// Lister la saison puis la déplier, c'est deux appels dans la même seconde pour le même flux.
// Le cache ne garde rien longtemps : un podcast publie, et la fiche doit le voir à la visite suivante.
private actor FeedCache {
    private var entries: [String: (episodes: [EpisodeSummary], at: Date)] = [:]
    private let freshness: TimeInterval

    init(freshness: TimeInterval) { self.freshness = freshness }

    func episodes(for key: String) -> [EpisodeSummary]? {
        guard let entry = entries[key], Date.now.timeIntervalSince(entry.at) < freshness else { return nil }
        return entry.episodes
    }

    func store(_ episodes: [EpisodeSummary], for key: String) {
        entries[key] = (episodes, .now)
    }
}
