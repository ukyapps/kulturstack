import Foundation
import Testing
@testable import Kulturstack

struct ProviderRegistryTests {
    @Test func liveRegistryHasTMDBOpenLibraryAndApple() {
        let registry = ProviderRegistry.live(secrets: MockSecrets(), client: StubHTTPClient(data: Data()), appVersion: "0.1.0")

        #expect(registry.providers.map(\.id) == ["tmdb", "openlibrary", "apple"])
        #expect(registry.families == [.screen, .books, .podcasts])
        // Apple cherche, il ne complète pas une fiche après coup : TMDB reste seul à le faire.
        #expect(registry.detailsProviders.count == 1)
        #expect(registry.detailsProviders.first is TMDBProvider)
        // Deux sources d'épisodes : TMDB pour les séries, le flux RSS pour les podcasts.
        #expect(registry.episodeProviders.count == 2)
        #expect(registry.episodeSources.first is RSSEpisodeProvider)
    }

    @Test func userAgentNamesTheAppAndAContact() {
        let agent = ProviderRegistry.userAgent(appVersion: "0.1.0")
        #expect(agent.hasPrefix("Kulturstack/0.1.0"))
        #expect(agent.contains("https://github.com/ukyapps/kulturstack"))
    }
}
