import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct ItemDetailViewModelTests {
    private let dune = MediaCandidate(
        id: "tmdb:movie:438631", kind: .film, title: "Dune", originalTitle: "Dune", year: 2021, creators: ["Denis Villeneuve"],
        coverURL: nil, summary: "Paul…", externalKeys: ["tmdb:movie:438631"], details: FilmDetails(), providerID: "tmdb")

    private func make() throws -> (ModelContainer, MediaItem, ItemDetailViewModel) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: .film, title: "Dune", year: 2021)
        try repository.add(item, refs: [ExternalRef(provider: "tmdb", value: "movie:438631")])
        try repository.add(try LogEntry.make(item: item, status: .done, rating: 8))
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        return (container, item, ItemDetailViewModel(subject: .stored(item.id), repository: repository, logUseCase: logUseCase))
    }

    private func makeEmpty() throws -> (ModelContainer, SwiftDataMediaRepository, LogUseCase) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        return (container, repository, LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository)))
    }

    @Test func aCandidateNotYetStoredIsPreviewedWithoutLogs() throws {
        let (container, repository, logUseCase) = try makeEmpty()
        let viewModel = ItemDetailViewModel(subject: .candidate(dune), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.title == "Dune")
        #expect(model.logs.isEmpty)
        #expect(model.source == "TMDB")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<MediaItem>()) == 0)
    }

    @Test func aCandidateAlreadyStoredShowsTheStoredItemAndItsLogs() throws {
        let (container, item, _) = try make()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = ItemDetailViewModel(subject: .candidate(dune), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.id == item.id)
        #expect(model.logs.count == 1)
    }

    @Test func loadGivesASnapshotOfTheItem() throws {
        let (container, _, viewModel) = try make()
        #expect(viewModel.state == .loading)

        viewModel.load()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.title == "Dune")
        #expect(model.logs.count == 1)
        #expect(model.source == "TMDB")
        withExtendedLifetime(container) {}
    }

    @Test func anUnknownItemGivesTheMissingState() throws {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = ItemDetailViewModel(subject: .stored(UUID()), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        #expect(viewModel.state == .missing)
        withExtendedLifetime(container) {}
    }

    @Test func aRepositoryFailureGivesTheFailedState() {
        let repository = FailingMediaRepository()
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = ItemDetailViewModel(subject: .stored(UUID()), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test func wishingACandidateStoresItWithAWishlistLog() throws {
        let (container, repository, logUseCase) = try makeEmpty()
        let viewModel = ItemDetailViewModel(subject: .candidate(dune), repository: repository, logUseCase: logUseCase)
        viewModel.load()

        viewModel.wish()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.logs.map(\.status) == [.wishlist])
        #expect(try container.mainContext.fetchCount(FetchDescriptor<MediaItem>()) == 1)
    }

    @Test func wishingAStoredItemAddsAWishlistLog() throws {
        let (container, item, viewModel) = try make()
        viewModel.load()

        viewModel.wish()

        #expect(item.logs.map(\.status).contains(.wishlist))
        #expect(item.logs.count == 2)
        withExtendedLifetime(container) {}
    }

    @Test func aFilmWithoutDetailsIsEnrichedWhenItsPageOpens() async throws {
        let (container, item, _) = try make()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let provider = StubDetailsProvider(result: .success(MediaEnrichment(
            creators: ["Denis Villeneuve"], details: FilmDetails(runtimeMinutes: 155, genres: ["SF"]))))
        let enrich = EnrichUseCase(repository: repository, providers: [provider])
        let viewModel = ItemDetailViewModel(subject: .stored(item.id), repository: repository, logUseCase: logUseCase, enrich: enrich)

        viewModel.load()
        await viewModel.enrichmentTask?.value

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.headline.contains("Denis Villeneuve"))
        #expect(model.headline.contains("2h35"))
        #expect(model.facts == ["SF"])
        #expect(provider.keys == ["tmdb:movie:438631"])
    }

    // MARK: - « Je le commence » (retour du 27/09)

    @Test func startingAStoredWorkWritesAnInProgressLog() throws {
        let (container, repository, logUseCase) = try makeEmpty()
        let book = MediaItem(kind: .book, title: "Piranesi")
        try repository.add(book, refs: [ExternalRef(provider: "ol", value: "work:OL1W")])
        let viewModel = ItemDetailViewModel(subject: .stored(book.id), repository: repository, logUseCase: logUseCase)
        viewModel.load()

        viewModel.start()

        #expect(book.logs.map(\.status) == [.inProgress])
        #expect(viewModel.didFailToLog == false)
        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.watchStatus == .inProgress)
        #expect(model.canStart == false)
        withExtendedLifetime(container) {}
    }

    // Commencer un livre trouvé dans la recherche l'enregistre d'abord : un log tient à une œuvre.
    @Test func startingACandidateStoresItFirst() throws {
        let (container, repository, logUseCase) = try makeEmpty()
        let piranesi = MediaCandidate(id: "ol:work:OL1W", kind: .book, title: "Piranesi", originalTitle: nil,
                                      year: 2020, creators: ["Susanna Clarke"], coverURL: nil, summary: nil,
                                      externalKeys: ["ol:work:OL1W"], details: BookDetails(), providerID: "openlibrary")
        let viewModel = ItemDetailViewModel(subject: .candidate(piranesi), repository: repository, logUseCase: logUseCase)
        viewModel.load()

        viewModel.start()

        let stored = try #require(try repository.findItem(withAnyKey: ["ol:work:OL1W"]))
        #expect(stored.logs.map(\.status) == [.inProgress])
        #expect(viewModel.storedItemID == stored.id)
        withExtendedLifetime(container) {}
    }

    // Le modèle refuse « en cours » sur un film : rien n'est écrit, et l'échec se dit.
    @Test func startingAFilmIsRefusedWithoutWritingAnything() throws {
        let (container, item, viewModel) = try make()
        viewModel.load()

        viewModel.start()

        #expect(viewModel.didFailToLog)
        #expect(item.logs.contains { $0.status == .inProgress } == false)
        withExtendedLifetime(container) {}
    }
}

private struct FailingError: Error {}

@MainActor
private struct FailingMediaRepository: MediaRepository {
    func findItem(withAnyKey keys: [String]) throws -> MediaItem? { throw FailingError() }
    func find(itemID: UUID) throws -> MediaItem? { throw FailingError() }
    func add(_ item: MediaItem, refs: [ExternalRef]) throws { throw FailingError() }
    func add(_ refs: [ExternalRef], to item: MediaItem) throws { throw FailingError() }
    func add(_ log: LogEntry) throws { throw FailingError() }
    func save() throws { throw FailingError() }
    func deleteAll() throws { throw FailingError() }
}
