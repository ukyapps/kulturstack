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

    // Un disque décodait en `GenericDetails` jusqu'au 17/10 : sa fiche n'affichait donc ni
    // pistes ni genre, alors que le provider les remplissait. Trouvé par le test de la fiche.
    @Test func anAlbumDecodesToAlbumDetails() throws {
        let data = try DetailsCodec.encode(AlbumDetails(trackCount: 14, genre: "Pop"))
        let decoded = try DetailsCodec.decode(kind: .album, from: data) as? AlbumDetails

        #expect(decoded == AlbumDetails(trackCount: 14, genre: "Pop"))
    }

    // Les types sans source — jeu, concert, théâtre, expo — restent sur la poche générique.
    @Test func kindsWithoutASourceStayGeneric() throws {
        let data = try DetailsCodec.encode(GenericDetails(venue: "Olympia"))

        #expect(try DetailsCodec.decode(kind: .concert, from: data) is GenericDetails)
        #expect(try DetailsCodec.decode(kind: .game, from: data) is GenericDetails)
    }

    // Une poche écrite avant que les disques aient leur type ne fait pas tomber la fiche :
    // tous les champs d'`AlbumDetails` sont optionnels.
    @Test func anOlderGenericPayloadDoesNotBreakAnAlbum() throws {
        let old = try DetailsCodec.encode(GenericDetails(venue: "Olympia", city: "Paris"))

        let decoded = try DetailsCodec.decode(kind: .album, from: old) as? AlbumDetails

        #expect(decoded == AlbumDetails())
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
