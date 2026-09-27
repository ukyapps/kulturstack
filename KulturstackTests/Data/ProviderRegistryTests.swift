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
        // Et il ne sait pas encore découper un podcast en épisodes : c'est la PR suivante.
        #expect(registry.episodeProviders.count == 1)
    }

    @Test func userAgentNamesTheAppAndAContact() {
        let agent = ProviderRegistry.userAgent(appVersion: "0.1.0")
        #expect(agent.hasPrefix("Kulturstack/0.1.0"))
        #expect(agent.contains("https://github.com/ukyapps/kulturstack"))
    }
}
