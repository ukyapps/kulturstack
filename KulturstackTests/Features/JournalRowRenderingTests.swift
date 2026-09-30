import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

struct JournalRowRenderingTests {
    @Test @MainActor func rowRendersWithAndWithoutRating() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = MediaItem(kind: .book, title: "Piranesi", year: 2020, creators: ["Susanna Clarke"])
        container.mainContext.insert(item)
        let rated = try LogEntry.make(item: item, status: .done, rating: 9)
        let unrated = try LogEntry.make(item: item, status: .inProgress)
        container.mainContext.insert(rated)
        container.mainContext.insert(unrated)

        for log in [rated, unrated] {
            let host = UIHostingController(rootView: JournalRow(model: JournalRowModel(log: log)))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            let size = host.sizeThatFits(in: CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude))
            #expect(size.height > 44)
        }
    }

    // Le commentaire prend la place de la date : la date du jour est déjà dans l'en-tête de section.
    @Test @MainActor func aCommentMakesTheRowTaller() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = MediaItem(kind: .film, title: "La Planète sauvage", year: 1973)
        container.mainContext.insert(item)
        let bare = try LogEntry.make(item: item, status: .done)
        let commented = try LogEntry.make(item: item, status: .done,
                                          note: "Vu au cinéma dans la copie restaurée, les décors de Topor valent le détour.")
        for log in [bare, commented] { container.mainContext.insert(log) }

        let heights = [bare, commented].map { log -> CGFloat in
            let host = UIHostingController(rootView: JournalRow(model: JournalRowModel(log: log)))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            return host.sizeThatFits(in: CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude)).height
        }

        #expect(heights[1] > heights[0])
        withExtendedLifetime(container) {}
    }

    // La ligne d'une série suivie porte sa barre et son ✓ ; celle d'un film, non.
    @Test @MainActor func aFollowedSeriesRowShowsItsProgressAndItsButton() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let series = MediaItem(kind: .series, title: "Severance")
        context.insert(series)
        let season = try Season.make(number: 2, item: series)
        context.insert(season)
        for number in 1...10 { context.insert(Episode(number: number, season: season)) }
        try context.save()
        context.insert(try LogEntry.make(item: series, status: .done, episode: season.orderedEpisodes[0]))
        let status = try LogEntry.make(item: series, status: .inProgress,
                                       source: WatchStatusUseCase.automaticSource)
        context.insert(status)
        let film = MediaItem(kind: .film, title: "La Planète sauvage")
        context.insert(film)
        let watched = try LogEntry.make(item: film, status: .done)
        context.insert(watched)
        try context.save()

        var shots: [Data] = []
        for log in [status, watched] {
            let host = UIHostingController(rootView:
                JournalRow(model: JournalRowModel(log: log), onAdvance: {}).frame(width: 390))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.frame = window.bounds
            host.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            shots.append(renderer.image { context in window.layer.render(in: context.cgContext) }.pngData() ?? Data())
        }

        #expect(Set(shots).count == 2)
        #expect(JournalRowModel(log: status).watch?.next?.number == 2)
        withExtendedLifetime(container) {}
    }
}
