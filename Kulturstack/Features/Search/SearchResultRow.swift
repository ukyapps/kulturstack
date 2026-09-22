import SwiftUI

struct SearchResultRow: View {
    let model: SearchResultRowModel
    var onLog: (() -> Void)? = nil
    var onWish: (() -> Void)? = nil

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
            if let onWish {
                Button(action: onWish) {
                    Image(systemName: "heart")
                        .font(.title3)
                        .foregroundStyle(Color.accent)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(String(localized: "search.row.wish"))
            }
            if let onLog {
                Button(action: onLog) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accent)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(String(localized: "search.row.log"))
                .sensoryFeedback(.success, trigger: model.lastLoggedAt)
            }
        }
    }
}
