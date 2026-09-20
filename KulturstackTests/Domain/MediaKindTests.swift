import Testing
@testable import Kulturstack

struct MediaKindTests {
    @Test(arguments: [MediaKind.film, .album, .concert, .theatre, .exhibition])
    func kindsWithoutDurationOnlyAllowWishlistAndDone(kind: MediaKind) {
        #expect(kind.allowedStatuses == [.wishlist, .done])
        #expect(!kind.hasDuration)
    }

    @Test(arguments: [MediaKind.series, .book, .podcast, .game])
    func kindsWithDurationAllowAllStatuses(kind: MediaKind) {
        #expect(kind.allowedStatuses == [.wishlist, .inProgress, .done, .dropped])
        #expect(kind.hasDuration)
    }

    @Test func onlySeriesAndPodcastsHaveEpisodes() {
        let withEpisodes = MediaKind.allCases.filter(\.hasEpisodes)
        #expect(Set(withEpisodes) == [.series, .podcast])
    }

    @Test func everyKindBelongsToASearchFamily() {
        for kind in MediaKind.allCases {
            #expect(kind.searchFamily.kinds.contains(kind))
        }
    }
}
