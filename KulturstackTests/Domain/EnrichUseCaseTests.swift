import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct EnrichUseCaseTests {
    private func makeItem(kind: MediaKind = .film, creators: [String] = [], details: (any DetailsPayload)? = nil,
                          keys: [(String, String)] = [("tmdb", "movie:438631")]) throws -> (ModelContainer, MediaItem, SwiftDataMediaRepository) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: kind, title: "Dune", year: 2021, creators: creators)
        if let details { try item.setDetails(details) }
        try repository.add(item, refs: keys.map { ExternalRef(provider: $0.0, value: $0.1) })
        return (container, item, repository)
    }

    private let dune = MediaEnrichment(creators: ["Denis Villeneuve"],
                                       details: FilmDetails(runtimeMinutes: 155, genres: ["SF"], directors: ["Denis Villeneuve"]))

    @Test func fillsCreatorsAndDetailsFromTheProviderAndSaves() async throws {
        let (container, item, repository) = try makeItem()
        let provider = StubDetailsProvider(result: .success(dune))
        let useCase = EnrichUseCase(repository: repository, providers: [provider])

        let didEnrich = await useCase.enrich(item)

        #expect(didEnrich)
        #expect(item.creators == ["Denis Villeneuve"])
        #expect((item.details as? FilmDetails)?.runtimeMinutes == 155)
        #expect(provider.keys == ["tmdb:movie:438631"])
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func existingCreatorsAreKept() async throws {
        let (container, item, repository) = try makeItem(creators: ["Quelqu'un"])
        let useCase = EnrichUseCase(repository: repository, providers: [StubDetailsProvider(result: .success(dune))])

        _ = await useCase.enrich(item)

        #expect(item.creators == ["Quelqu'un"])
        #expect((item.details as? FilmDetails)?.runtimeMinutes == 155)
        withExtendedLifetime(container) {}
    }

    @Test func aProviderFailureLeavesTheItemUntouched() async throws {
        let (container, item, repository) = try makeItem()
        let useCase = EnrichUseCase(repository: repository, providers: [StubDetailsProvider(result: .failure(HTTPError.status(500)))])

        let didEnrich = await useCase.enrich(item)

        #expect(didEnrich == false)
        #expect(item.creators.isEmpty)
        #expect(item.details == nil)
        withExtendedLifetime(container) {}
    }

    @Test func anItemWithoutAKnownKeyIsSkipped() async throws {
        let (container, item, repository) = try makeItem(keys: [("ol", "work:1")])
        let provider = StubDetailsProvider(result: .success(dune))
        let useCase = EnrichUseCase(repository: repository, providers: [provider])

        let didEnrich = await useCase.enrich(item)

        #expect(didEnrich == false)
        #expect(provider.keys == ["ol:work:1"])
        withExtendedLifetime(container) {}
    }

    @Test(arguments: [
        (MediaKind.film, nil as (any DetailsPayload)?, [String](), true),
        (MediaKind.film, FilmDetails(runtimeMinutes: 155) as (any DetailsPayload)?, ["Denis Villeneuve"], false),
        (MediaKind.film, FilmDetails() as (any DetailsPayload)?, ["Denis Villeneuve"], true),
        (MediaKind.series, SeriesDetails() as (any DetailsPayload)?, [String](), true),
        (MediaKind.series, SeriesDetails(seasonCount: 2) as (any DetailsPayload)?, [String](), false),
        (MediaKind.book, BookDetails() as (any DetailsPayload)?, [String](), false),
    ])
    func onlyScreenItemsMissingTheirDetailsNeedEnrichment(kind: MediaKind, details: (any DetailsPayload)?, creators: [String], expected: Bool) throws {
        let (container, item, _) = try makeItem(kind: kind, creators: creators, details: details)
        #expect(EnrichUseCase.needsEnrichment(item) == expected)
        withExtendedLifetime(container) {}
    }
}

final class StubDetailsProvider: DetailsProvider, @unchecked Sendable {
    private let result: Result<MediaEnrichment?, Error>
    private(set) var keys: [String] = []

    init(result: Result<MediaEnrichment?, Error>) { self.result = result }

    func details(forKey key: String) async throws -> MediaEnrichment? {
        keys.append(key)
        guard key.hasPrefix("tmdb:") else { return nil }
        return try result.get()
    }
}
