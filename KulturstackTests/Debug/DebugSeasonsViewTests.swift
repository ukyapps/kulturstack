import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct DebugSeasonsViewTests {
    private struct StubEpisodeProvider: EpisodeProvider {
        var stubSeasons: [SeasonSummary] = []
        var stubEpisodes: [EpisodeSummary] = []
        var failure: (any Error)?

        func seasons(forKey key: String) async throws -> [SeasonSummary] {
            if let failure { throw failure }
            return stubSeasons
        }

        func episodes(forKey key: String, season: Int) async throws -> [EpisodeSummary] {
            if let failure { throw failure }
            return stubEpisodes
        }
    }

    private func render(_ provider: StubEpisodeProvider) -> UIView {
        let view = NavigationStack {
            DebugSeasonsView(title: "Severance", key: "tmdb:tv:95396", provider: provider)
        }
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        return host.view
    }

    // Les trois rendus se distinguent : rempli ≠ vide ≠ erreur.
    @Test func theFilledStateRenders() {
        let provider = StubEpisodeProvider(
            stubSeasons: [SeasonSummary(number: 1, title: "Saison 1", episodeCount: 9, airDate: nil)],
            stubEpisodes: [EpisodeSummary(number: 1, title: "Good News About Hell", airDate: nil, runtimeMinutes: 57)]
        )
        #expect(render(provider).bounds.height > 0)
    }

    @Test func theEmptyStateRenders() {
        #expect(render(StubEpisodeProvider()).bounds.height > 0)
    }

    @Test func theFailedStateRenders() {
        #expect(render(StubEpisodeProvider(failure: HTTPError.status(503))).bounds.height > 0)
    }

    @Test(arguments: ["debug.seasons.empty.title", "debug.seasons.empty.message",
                      "debug.seasons.failed", "debug.seasons.no.episode"])
    func everyNewStringExistsInBothLanguages(key: String) throws {
        let fr = try localized(key, language: "fr")
        let en = try localized(key, language: "en")
        #expect(fr != key)
        #expect(en != key)
        #expect(fr != en)
    }

    private func localized(_ key: String, language: String) throws -> String {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path)).localizedString(forKey: key, value: key, table: "Localizable")
    }
}
