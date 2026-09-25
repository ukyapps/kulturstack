import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct InProgressViewRenderingTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func render(_ view: some View, settles: Bool = false) async -> Data {
        // Sans NavigationStack : hors écran, une pile de navigation ne déclenche pas les `.task`
        // de son contenu, et la vue resterait sur son état de chargement.
        let host = UIHostingController(rootView: AnyView(view))
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

    private func severance(episodes: Int, watched: [Int]) throws {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 2, item: item)
        context.insert(season)
        for number in 1...episodes { context.insert(Episode(number: number, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes where watched.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        context.insert(try LogEntry.make(item: item, status: .inProgress,
                                         source: WatchStatusUseCase.automaticSource))
        try context.save()
    }

    // L'onglet vide est un écran d'accueil, pas un trou : il se distingue de la liste remplie.
    @Test func rendersTheEmptyTabAndTheList() async throws {
        let services = AppServices(context: container.mainContext)
        let empty = await render(InProgressView(services: services), settles: true)

        try severance(episodes: 10, watched: [1, 2, 3, 4])
        let filled = await render(InProgressView(services: services), settles: true)

        #expect(!empty.isEmpty)
        #expect(empty != filled)
    }

    // Une série a une suite à cocher ; un livre se termine. Deux lignes, deux actions.
    @Test func rendersARowWithANextEpisodeAndOneWithout() async throws {
        let context = container.mainContext
        let series = MediaItem(kind: .series, title: "Severance")
        let book = MediaItem(kind: .book, title: "Piranesi")
        context.insert(series)
        context.insert(book)
        let season = try Season.make(number: 2, item: series)
        context.insert(season)
        for number in 1...3 { context.insert(Episode(number: number, season: season)) }
        try context.save()
        context.insert(try LogEntry.make(item: series, status: .done, episode: season.orderedEpisodes[0]))
        try context.save()

        var shots: [Data] = []
        for item in [series, book] {
            shots.append(await render(InProgressRow(model: InProgressRowModel(item: item),
                                                    onAdvance: {}, onFinish: {})))
        }

        #expect(Set(shots).count == 2)
    }
}
