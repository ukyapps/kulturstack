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
        // Trois sources d'épisodes : TMDB pour les séries, le flux RSS pour les podcasts, et
        // la page de Radio France pour ceux dont Apple ne donne pas le flux. Le flux d'abord :
        // il répond pour tous les podcasts sauf ceux-là, qui ne coûtent donc rien aux autres.
        #expect(registry.episodeProviders.count == 3)
        #expect(registry.episodeSources.first is RSSEpisodeProvider)
        #expect(registry.episodeSources.last is RadioFranceEpisodeProvider)
    }

    @Test func userAgentNamesTheAppAndAContact() {
        let agent = ProviderRegistry.userAgent(appVersion: "0.1.0")
        #expect(agent.hasPrefix("Kulturstack/0.1.0"))
        #expect(agent.contains("https://github.com/ukyapps/kulturstack"))
    }
}
