import SwiftUI

struct InProgressRow: View {
    let model: InProgressRowModel
    let onAdvance: () -> Void
    let onFinish: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            CoverThumbnail(url: model.coverURL, placeholderSymbol: model.kind.symbol)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                Text(model.detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                if let next = model.next {
                    Text(next.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
            }
            Spacer(minLength: 0)
            action
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }

    // Une série a une suite à cocher ; un livre, ou une série arrivée au bout, se termine.
    @ViewBuilder private var action: some View {
        if let next = model.next {
            Button(action: onAdvance) {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(next.label)
            .accessibilityHint(String(localized: "inprogress.advance.hint"))
        } else {
            Button(String(localized: "inprogress.finish"), action: onFinish)
                .buttonStyle(.bordered)
                .font(.subheadline.weight(.semibold))
        }
    }
}
