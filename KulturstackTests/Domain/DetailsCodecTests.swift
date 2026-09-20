import Foundation
import Testing
@testable import Kulturstack

struct DetailsCodecTests {
    @Test func filmDetailsRoundTrip() throws {
        let original = FilmDetails(runtimeMinutes: 155, genres: ["Science-fiction"], directors: ["Denis Villeneuve"])
        let data = try DetailsCodec.encode(original)
        let decoded = try DetailsCodec.decode(kind: .film, from: data) as? FilmDetails
        #expect(decoded == original)
    }

    @Test func missingFieldsFallBackToDefaults() throws {
        let partial = Data(#"{"runtimeMinutes":120}"#.utf8)
        let decoded = try DetailsCodec.decode(kind: .film, from: partial) as? FilmDetails
        #expect(decoded?.runtimeMinutes == 120)
        #expect(decoded?.genres == [])
        #expect(decoded?.directors == [])
    }

    @Test func emptyPayloadDecodesToDefaults() throws {
        let decoded = try DetailsCodec.decode(kind: .book, from: Data("{}".utf8)) as? BookDetails
        #expect(decoded == BookDetails())
    }

    @Test func decodeUsesTheTypeMatchingTheKind() throws {
        let data = try DetailsCodec.encode(SeriesDetails(seasonCount: 3))
        #expect(try DetailsCodec.decode(kind: .series, from: data) is SeriesDetails)
        #expect(try DetailsCodec.decode(kind: .book, from: data) is BookDetails)
    }

    @Test @MainActor func mediaItemExposesTypedDetails() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = MediaItem(kind: .book, title: "Dune")
        container.mainContext.insert(item)

        try item.setDetails(BookDetails(pageCount: 688, publisher: "Robert Laffont"))
        let details = item.details as? BookDetails

        #expect(details?.pageCount == 688)
        #expect(item.detailsVersion == DetailsCodec.currentVersion)
    }
}
