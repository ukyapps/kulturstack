import Foundation

struct ProviderRegistry: Sendable {
    let providers: [any MetadataProvider]

    var families: [SearchFamily] { SearchUseCase(providers: providers).families }

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
