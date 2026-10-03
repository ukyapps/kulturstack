import Foundation

struct ProviderRegistry: Sendable {
    let providers: [any MetadataProvider]
    // Les sources d'épisodes qui ne cherchent rien : un flux RSS sait découper un podcast,
    // il ne sait pas le trouver.
    let episodeSources: [any EpisodeProvider]

    init(providers: [any MetadataProvider], episodeSources: [any EpisodeProvider] = []) {
        self.providers = providers
        self.episodeSources = episodeSources
    }

    var families: [SearchFamily] { SearchUseCase(providers: providers).families }

    // Les sources qui savent compléter une fiche après coup (TMDB aujourd'hui).
    var detailsProviders: [any DetailsProvider] { providers.compactMap { $0 as? any DetailsProvider } }

    // Celles qui savent découper une œuvre en saisons et en épisodes : TMDB pour les séries,
    // le flux RSS pour les podcasts.
    var episodeProviders: [any EpisodeProvider] {
        providers.compactMap { $0 as? any EpisodeProvider } + episodeSources
    }

    static func live(secrets: any SecretsProviding, client: any HTTPClient, appVersion: String) -> ProviderRegistry {
        ProviderRegistry(providers: [
            TMDBProvider(secrets: secrets, client: client),
            OpenLibraryProvider(client: client, userAgent: userAgent(appVersion: appVersion)),
            ApplePodcastProvider(client: client),
        ], episodeSources: [
            RSSEpisodeProvider(client: client, userAgent: userAgent(appVersion: appVersion)),
            // En dernier : il n'a quelque chose à dire que des podcasts dont Apple ne donne
            // pas le flux, et le flux répond pour tous les autres.
            RadioFranceEpisodeProvider(client: client, userAgent: userAgent(appVersion: appVersion)),
        ])
    }

    static func userAgent(appVersion: String) -> String {
        "Kulturstack/\(appVersion) (+https://github.com/ukyapps/kulturstack)"
    }
}
