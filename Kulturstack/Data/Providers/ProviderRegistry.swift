import Foundation

struct ProviderRegistry: Sendable {
    let providers: [any MetadataProvider]

    var families: [SearchFamily] { SearchUseCase(providers: providers).families }

    // Les sources qui savent compléter une fiche après coup (TMDB aujourd'hui).
    var detailsProviders: [any DetailsProvider] { providers.compactMap { $0 as? any DetailsProvider } }

    // Celles qui savent découper une série en saisons et en épisodes.
    var episodeProviders: [any EpisodeProvider] { providers.compactMap { $0 as? any EpisodeProvider } }

    static func live(secrets: any SecretsProviding, client: any HTTPClient, appVersion: String) -> ProviderRegistry {
        ProviderRegistry(providers: [
            TMDBProvider(secrets: secrets, client: client),
            OpenLibraryProvider(client: client, userAgent: userAgent(appVersion: appVersion)),
        ])
    }

    static func userAgent(appVersion: String) -> String {
        "Kulturstack/\(appVersion) (+https://github.com/ukyapps/kulturstack)"
    }
}
