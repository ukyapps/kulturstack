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
                if let progress = model.progress {
                    ProgressBar(fraction: progress.fraction)
                }
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
        // Le tap se sent autant qu'il se voit : la ligne bouge peu, la main doit savoir.
        .sensoryFeedback(.success, trigger: model.progress?.position)
    }

    // Une série a une suite à cocher ; un livre, ou une série arrivée au bout, se termine.
    // Un podcast, lui, ne se termine pas : il publiera encore la semaine prochaine, et sa
    // ligne n'offre rien quand tout ce que le flux contient a été écouté.
    @ViewBuilder private var action: some View {
        if let next = model.next {
            Button(action: onAdvance) {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.surface)
                    .frame(width: 40, height: 40)
                    .background(Color.accent, in: Circle())
            }
            .buttonStyle(.press)
            .accessibilityLabel(next.label)
            .accessibilityHint(String(localized: "inprogress.advance.hint"))
        } else if model.kind.hasAnEnd {
            Button(String(localized: "inprogress.finish"), action: onFinish)
                .buttonStyle(.bordered)
                .font(.subheadline.weight(.semibold))
        }
    }
}
