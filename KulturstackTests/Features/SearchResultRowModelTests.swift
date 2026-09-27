import Foundation
import Testing
@testable import Kulturstack

struct SearchResultRowModelTests {
    @Test(arguments: [MediaKind.film, .series, .book, .album, .podcast, .game, .concert, .theatre, .exhibition])
    func everyKindHasALoggedLabelWithTheDate(kind: MediaKind) {
        let candidate = MockProvider.candidate("x:1", kind: kind, title: "Titre")
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let row = SearchResultRowModel(candidate: candidate, lastLoggedAt: date)

        let label = row.loggedLabel ?? ""
        #expect(!label.isEmpty)
        #expect(label.contains(date.formatted(.dateTime.day().month())))
    }

    @Test func noDateMeansNoLabel() {
        let row = SearchResultRowModel(candidate: MockProvider.candidate("x:1"), lastLoggedAt: nil)
        #expect(row.loggedLabel == nil)
    }

    // « Quand je veux log une série, ça me met la série comme un film au lieu de direct
    // m'afficher les épisodes » (27/09) : ce qui a des épisodes mène à ses épisodes.
    @Test(arguments: [MediaKind.series, .podcast])
    func aWorkWithEpisodesLeadsToThem(kind: MediaKind) {
        #expect(SearchResultRowModel(candidate: MockProvider.candidate("x:1", kind: kind)).leadsToEpisodes)
    }

    @Test(arguments: [MediaKind.film, .book, .album, .game, .concert, .theatre, .exhibition])
    func aWorkWatchedInOneGoIsLoggedInOneTap(kind: MediaKind) {
        #expect(SearchResultRowModel(candidate: MockProvider.candidate("x:1", kind: kind)).leadsToEpisodes == false)
    }
}
