import Testing
@testable import Kulturstack

struct StarRatingPickerTests {
    @Test func tappingAHalfSetsTheRating() {
        #expect(StarRatingPicker.toggled(7, current: nil) == 7)
        #expect(StarRatingPicker.toggled(10, current: 3) == 10)
    }

    @Test func tappingTheCurrentValueClearsTheRating() {
        #expect(StarRatingPicker.toggled(7, current: 7) == nil)
    }

    @Test(arguments: [(1, 0, 1), (2, 0, 2), (3, 1, 1), (10, 4, 2)])
    func eachStarKnowsItsTwoHalves(value: Int, star: Int, half: Int) {
        #expect(StarRatingPicker.value(star: star, half: half) == value)
    }
}
