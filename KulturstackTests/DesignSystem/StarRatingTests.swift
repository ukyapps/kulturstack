import Testing
@testable import Kulturstack

struct StarRatingTests {
    @Test(arguments: [
        (1, 0, true), (2, 1, false), (5, 2, true), (7, 3, true), (8, 4, false), (10, 5, false),
    ])
    func ratingOutOfTenBecomesHalfStars(rating: Int, full: Int, half: Bool) {
        let stars = StarRating.Stars(rating: rating)
        #expect(stars.full == full)
        #expect(stars.half == half)
        #expect(stars.empty == 5 - full - (half ? 1 : 0))
    }
}
