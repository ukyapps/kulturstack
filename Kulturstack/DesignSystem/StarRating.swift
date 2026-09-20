import SwiftUI

struct StarRating: View {
    struct Stars: Equatable {
        let full: Int
        let half: Bool
        var empty: Int { 5 - full - (half ? 1 : 0) }

        init(rating: Int) {
            let clamped = min(max(rating, 0), 10)
            full = clamped / 2
            half = clamped % 2 == 1
        }
    }

    let rating: Int

    var body: some View {
        let stars = Stars(rating: rating)
        HStack(spacing: 1) {
            ForEach(0..<stars.full, id: \.self) { _ in Image(systemName: "star.fill") }
            if stars.half { Image(systemName: "star.leadinghalf.filled") }
            ForEach(0..<stars.empty, id: \.self) { _ in Image(systemName: "star") }
        }
        .font(.caption2)
        .foregroundStyle(Color.accent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "rating.accessibility \((Double(rating) / 2).formatted())"))
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(1...10, id: \.self) { StarRating(rating: $0) }
    }
}
