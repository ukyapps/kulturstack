import SwiftUI

struct SearchResultRow: View {
    let model: SearchResultRowModel

    var body: some View {
        MediaRow(coverURL: model.coverURL, placeholderSymbol: model.kind.symbol,
                 title: model.title, subtitle: model.subtitle) {
            if let logged = model.loggedLabel {
                Text(logged)
                    .font(.caption)
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 2)
                    .background(Color.surfaceSecondary, in: Capsule())
            }
        }
    }
}
