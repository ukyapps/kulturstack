import SwiftUI

struct StarRatingPicker: View {
    @Binding var rating: Int?

    static func toggled(_ value: Int, current: Int?) -> Int? {
        current == value ? nil : value
    }

    static func value(star: Int, half: Int) -> Int {
        star * 2 + half
    }

    var body: some View {
        let stars = StarRating.Stars(rating: rating ?? 0)
        HStack(spacing: Spacing.xs) {
            ForEach(0..<5, id: \.self) { star in
                Image(systemName: symbol(for: star, in: stars))
                    .overlay {
                        HStack(spacing: 0) {
                            ForEach(1...2, id: \.self) { half in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture { select(Self.value(star: star, half: half)) }
                            }
                        }
                    }
            }
        }
        .font(.title2)
        .foregroundStyle(Color.accent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "log.edit.rating"))
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            let current = rating ?? 0
            switch direction {
            case .increment: rating = min(current + 1, LogRules.ratingRange.upperBound)
            case .decrement: rating = current <= 1 ? nil : current - 1
            @unknown default: break
            }
        }
    }

    private func select(_ value: Int) {
        rating = Self.toggled(value, current: rating)
    }

    private func symbol(for star: Int, in stars: StarRating.Stars) -> String {
        if star < stars.full { return "star.fill" }
        if star == stars.full, stars.half { return "star.leadinghalf.filled" }
        return "star"
    }

    private var accessibilityValue: String {
        guard let rating else { return String(localized: "log.edit.rating.none") }
        return String(localized: "rating.accessibility \((Double(rating) / 2).formatted())")
    }
}

#Preview {
    @Previewable @State var rating: Int? = 7
    StarRatingPicker(rating: $rating)
}
