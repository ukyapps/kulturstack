import SwiftUI

// « On voit à peine que j'ai cliqué… si je misclick je m'en rends pas compte » (founder, 27/09).
// Un bouton qui agit sur les données répond sous le doigt : il s'enfonce, puis revient.
struct PressFeedback: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressFeedback {
    static var press: PressFeedback { PressFeedback() }
}

// La barre de progression d'une œuvre en cours. Elle se remplit avec animation : c'est elle
// qui confirme le tap quand la ligne, elle, ne bouge presque pas.
struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.surfaceSecondary)
                Capsule()
                    .fill(Color.accent)
                    .frame(width: max(0, min(1, fraction)) * geometry.size.width)
            }
        }
        .frame(height: 4)
        .animation(.easeOut(duration: 0.35), value: fraction)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Spacing.l) {
        ProgressBar(fraction: 0.4)
        ProgressBar(fraction: 1)
        Button("Coché") {}.buttonStyle(.press)
    }
    .padding()
}
