import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct ItemDetailViewRenderingTests {
    @Test func rendersTheDetailThePreviewAndTheMissingState() throws {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: .book, title: "Piranesi", year: 2020, creators: ["Susanna Clarke"], summary: "Un homme…")
        try item.setDetails(BookDetails(pageCount: 272, publisher: "Bloomsbury"))
        try repository.add(item, refs: [ExternalRef(provider: "ol", value: "work:1")])
        try repository.add(try LogEntry.make(item: item, status: .done, rating: 9))
        let services = AppServices(context: container.mainContext)

        let candidate = MockProvider.candidate("tmdb:movie:2", kind: .film, title: "Dune")
        for subject in [ItemDetailViewModel.Subject.stored(item.id), .stored(UUID()), .candidate(candidate)] {
            let view = ItemDetailView(subject: subject, services: services)
            let host = UIHostingController(rootView: NavigationStack { view })
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            #expect(host.view.bounds.height > 0)
        }
    }
}
