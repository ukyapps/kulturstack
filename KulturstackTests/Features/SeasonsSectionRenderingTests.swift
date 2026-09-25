import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct SeasonsSectionRenderingTests {
    // Le conteneur doit vivre aussi longtemps que son contexte : rendu dans une fonction,
    // il serait relâché avant l'affichage et SwiftData s'arrêterait net.
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    // La fenêtre reste dans la même portée que sa vue, sans quoi elle emporte tout avant la mesure.
    // On rend l'image : deux états qui donnent le même pixel ne sont pas deux états.
    private func render(_ view: some View, scrolls: Bool = true, settles: Bool = false) async -> Data {
        let root = scrolls ? AnyView(ScrollView { AnyView(view) }) : AnyView(view)
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        if settles {
            for _ in 0..<5 {
                try? await Task.sleep(for: .milliseconds(120))
                host.view.setNeedsLayout()
                host.view.layoutIfNeeded()
            }
        }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { context in window.layer.render(in: context.cgContext) }.pngData() ?? Data()
    }

    // La clé de l'œuvre doit être celle que la source reconnaît, sinon la section rend « aucune saison ».
    private func series(_ provider: StubEpisodeProvider, id: Int) throws -> (UUID, AppServices) {
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: .series, title: "Severance \(id)")
        try repository.add(item, refs: [ExternalRef(provider: "tmdb", value: "tv:\(id)")])
        return (item.id, AppServices(context: container.mainContext, episodeProviders: [provider]))
    }

    private static func key(_ id: Int) -> String { "tmdb:tv:\(id)" }

    // Les trois rendus de la section : la liste, la série sans saison, le chargement raté.
    @Test func rendersTheSeasonsTheEmptyStateAndTheError() async throws {
        let providers = [
            StubEpisodeProvider(key: Self.key(1),
                                seasons: .success([StubEpisodeProvider.season(1, episodes: 9),
                                                   StubEpisodeProvider.season(0, episodes: 3, isSpecials: true)]),
                                episodes: [1: .success((1...9).map { StubEpisodeProvider.episode($0) })]),
            StubEpisodeProvider(key: Self.key(2), seasons: .success([])),
            StubEpisodeProvider(key: Self.key(3), seasons: .failure(HTTPError.status(500))),
        ]

        var shots: [Data] = []
        for (index, provider) in providers.enumerated() {
            let (itemID, services) = try series(provider, id: index + 1)
            shots.append(await render(SeasonsSection(itemID: itemID, services: services), settles: true))
        }

        #expect(shots.allSatisfy { !$0.isEmpty })
        #expect(Set(shots).count == 3)
    }

    // Une saison ouverte d'emblée charge ses épisodes : les trois rendus d'une saison dépliée.
    @Test func rendersAnOpenedSeasonEmptyFailedAndFull() async throws {
        let providers = [
            StubEpisodeProvider(key: Self.key(11), seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0, title: "Épisode") })]),
            StubEpisodeProvider(key: Self.key(12), seasons: .success([StubEpisodeProvider.season(1, episodes: 0)]),
                                episodes: [1: .success([])]),
            StubEpisodeProvider(key: Self.key(13), seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                episodes: [1: .failure(HTTPError.status(500))]),
        ]

        var shots: [Data] = []
        for (index, provider) in providers.enumerated() {
            let (itemID, services) = try series(provider, id: index + 11)
            shots.append(await render(SeasonsSection(itemID: itemID, services: services, opened: [1]), settles: true))
        }

        #expect(Set(shots).count == 3)
    }

    // Le bandeau de statut : rien, en cours, abandonnée — trois lignes différentes.
    @Test func rendersTheStatusBadge() async throws {
        var shots: [Data] = []
        for (index, status) in [nil, LogStatus.inProgress, .dropped].enumerated() {
            let provider = StubEpisodeProvider(key: Self.key(index + 31),
                                               seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]))
            let (itemID, services) = try series(provider, id: index + 31)
            if let status {
                let item = try #require(try services.mediaRepository.find(itemID: itemID))
                container.mainContext.insert(try LogEntry.make(item: item, status: status))
                try container.mainContext.save()
            }
            shots.append(await render(SeasonsSection(itemID: itemID, services: services), settles: true))
        }

        #expect(Set(shots).count == 3)
    }

    @Test func rendersAnEpisodeCheckedAndUnchecked() async throws {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        let seen = Episode(number: 1, title: "Good News About Hell", runtimeMinutes: 57, season: season)
        let unseen = Episode(number: 2, season: season)
        context.insert(seen)
        context.insert(unseen)
        context.insert(try LogEntry.make(item: item, status: .done, episode: seen))
        try context.save()

        var shots: [Data] = []
        for episode in [seen, unseen] {
            shots.append(await render(EpisodeRow(model: EpisodeRowModel(episode), toggle: {}, checkUpTo: {})))
        }

        #expect(Set(shots).count == 2)
    }

    // Une série ouverte depuis la recherche, pas encore en base, n'a pas d'épisodes à cocher.
    @Test func theDetailOfASeriesShowsItsSeasonsAndACandidateDoesNot() async throws {
        let (itemID, services) = try series(
            StubEpisodeProvider(key: Self.key(21), seasons: .success([StubEpisodeProvider.season(1)]),
                                episodes: [1: .success([StubEpisodeProvider.episode(1)])]), id: 21)
        let candidate = MediaCandidate(id: "tmdb:tv:1", kind: .series, title: "Shogun", originalTitle: nil, year: 2024,
                                       creators: [], coverURL: nil, summary: nil, externalKeys: ["tmdb:tv:1"],
                                       details: SeriesDetails(), providerID: "tmdb")

        var shots: [Data] = []
        for subject in [ItemDetailViewModel.Subject.stored(itemID), .candidate(candidate)] {
            shots.append(await render(NavigationStack { ItemDetailView(subject: subject, services: services) },
                                      scrolls: false, settles: true))
        }

        #expect(Set(shots).count == 2)
    }
}
