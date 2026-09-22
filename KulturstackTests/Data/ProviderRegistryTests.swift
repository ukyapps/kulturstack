import Foundation
import Testing
@testable import Kulturstack

struct ProviderRegistryTests {
    @Test func liveRegistryHasTMDBAndOpenLibrary() {
        let registry = ProviderRegistry.live(secrets: MockSecrets(), client: StubHTTPClient(data: Data()), appVersion: "0.1.0")

        #expect(registry.providers.map(\.id) == ["tmdb", "openlibrary"])
        #expect(registry.families == [.screen, .books])
        #expect(registry.detailsProviders.count == 1)
        #expect(registry.detailsProviders.first is TMDBProvider)
    }

    @Test func userAgentNamesTheAppAndAContact() {
        let agent = ProviderRegistry.userAgent(appVersion: "0.1.0")
        #expect(agent.hasPrefix("Kulturstack/0.1.0"))
        #expect(agent.contains("https://github.com/ukyapps/kulturstack"))
    }
}
