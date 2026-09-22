import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct ItemDetailModelTests {
    private func container() throws -> ModelContainer { try ModelContainerFactory.inMemory() }

    @Test func filmHeadlineHasKindRuntimeAndDirector() throws {
        let container = try container()
        let item = MediaItem(kind: .film, title: "Dune", year: 2021, creators: ["Denis Villeneuve"], summary: "Paul…")
        try item.setDetails(FilmDetails(runtimeMinutes: 155, genres: ["Science-fiction", "Aventure"]))
        container.mainContext.insert(item)

        let model = ItemDetailModel(item: item)

        #expect(model.title == "Dune")
        #expect(model.year == 2021)
        #expect(model.headline.contains(MediaKind.film.label))
        #expect(model.headline.contains("2h35"))
        #expect(model.headline.contains("Denis Villeneuve"))
        #expect(model.facts == ["Science-fiction, Aventure"])
        #expect(model.summary == "Paul…")
    }

    @Test func filmWithoutDetailsHasAShortHeadlineAndNoFacts() throws {
        let container = try container()
        let item = MediaItem(kind: .film, title: "Dune", year: 2021)
        container.mainContext.insert(item)

        let model = ItemDetailModel(item: item)

        #expect(model.headline == MediaKind.film.label)
        #expect(model.facts.isEmpty)
        #expect(model.summary == nil)
    }

    @Test func seriesFactsCountSeasonsAndEpisodes() throws {
        let container = try container()
        let item = MediaItem(kind: .series, title: "Severance", year: 2022)
        try item.setDetails(SeriesDetails(seasonCount: 2, episodeCount: 19))
        container.mainContext.insert(item)

        let facts = ItemDetailModel(item: item).facts

        #expect(facts.count == 1)
        #expect(facts[0].contains("2"))
        #expect(facts[0].contains("19"))
    }

    @Test func bookFactsHavePagesPublisherAndSubjects() throws {
        let container = try container()
        let item = MediaItem(kind: .book, title: "Dune", year: 1965, creators: ["Frank Herbert"])
        try item.setDetails(BookDetails(pageCount: 604, publisher: "Chilton", subjects: ["Science fiction", "Deserts", "Politics", "Extra"]))
        container.mainContext.insert(item)

        let model = ItemDetailModel(item: item)

        #expect(model.headline.contains("Frank Herbert"))
        #expect(model.facts.count == 3)
        #expect(model.facts[0].contains("604"))
        #expect(model.facts[1] == "Chilton")
        #expect(model.facts[2] == "Science fiction, Deserts, Politics")
    }

    @Test func logsAreNewestFirstAsValueSnapshots() throws {
        let container = try container()
        let item = MediaItem(kind: .film, title: "Dune")
        container.mainContext.insert(item)
        let old = try LogEntry.make(item: item, status: .done, date: .now.addingTimeInterval(-86_400 * 10), rating: 6)
        let recent = try LogEntry.make(item: item, status: .done, date: .now, rating: 9)
        container.mainContext.insert(old)
        container.mainContext.insert(recent)

        let logs = ItemDetailModel(item: item).logs

        #expect(logs.map(\.id) == [recent.id, old.id])
        #expect(logs.map(\.rating) == [9, 6])
        #expect(logs.map(\.status) == [.done, .done])
    }

    @Test func aCandidateGivesAPreviewWithoutLogs() {
        let candidate = MediaCandidate(
            id: "tmdb:movie:438631", kind: .film, title: "Dune", originalTitle: "Dune", year: 2021,
            creators: ["Denis Villeneuve"], coverURL: URL(string: "https://img/dune.jpg"), summary: "Paul…",
            externalKeys: ["tmdb:movie:438631"], details: FilmDetails(runtimeMinutes: 155, genres: ["SF"]), providerID: "tmdb")

        let model = ItemDetailModel(candidate: candidate)

        #expect(model.title == "Dune")
        #expect(model.year == 2021)
        #expect(model.headline.contains("2h35"))
        #expect(model.headline.contains("Denis Villeneuve"))
        #expect(model.facts == ["SF"])
        #expect(model.summary == "Paul…")
        #expect(model.coverURL == candidate.coverURL)
        #expect(model.logs.isEmpty)
        #expect(model.source == "TMDB")
    }

    @Test func anOpenLibraryCandidateNamesItsSource() {
        let candidate = MockProvider.candidate("ol:work:1", kind: .book, title: "Dune")
        let fromOL = MediaCandidate(id: candidate.id, kind: .book, title: "Dune", originalTitle: nil, year: nil, creators: [],
                                    coverURL: nil, summary: nil, externalKeys: [candidate.id], details: BookDetails(), providerID: "openlibrary")
        #expect(ItemDetailModel(candidate: fromOL).source == "OpenLibrary")
    }

    @Test(arguments: [
        (["tmdb"], "TMDB"), (["ol", "isbn13"], "OpenLibrary"), (["tmdb", "imdb"], "TMDB, IMDb"), ([], nil),
    ])
    func sourceNamesTheProviders(providers: [String], expected: String?) throws {
        let container = try container()
        let item = MediaItem(kind: .film, title: "Dune")
        container.mainContext.insert(item)
        for provider in providers {
            container.mainContext.insert(ExternalRef(provider: provider, value: "x", item: item))
        }

        #expect(ItemDetailModel(item: item).source == expected)
    }
}
