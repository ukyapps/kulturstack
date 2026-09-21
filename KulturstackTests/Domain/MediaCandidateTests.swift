import Foundation
import Testing
@testable import Kulturstack

struct MediaCandidateTests {
    @Test func identityIsTheExternalKey() {
        let a = make(id: "tmdb:movie:1", title: "Dune")
        let sameKey = make(id: "tmdb:movie:1", title: "Dune (édition)")
        let other = make(id: "tmdb:movie:2", title: "Dune")

        #expect(a == sameKey)
        #expect(a != other)
        #expect(Set([a, sameKey, other]).count == 2)
    }

    private func make(id: String, title: String) -> MediaCandidate {
        MediaCandidate(id: id, kind: .film, title: title, originalTitle: nil, year: nil, creators: [],
                       coverURL: nil, summary: nil, externalKeys: [id], details: FilmDetails(), providerID: "tmdb")
    }
}
