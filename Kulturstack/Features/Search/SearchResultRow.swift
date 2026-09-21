import SwiftUI

struct SearchResultRow: View {
    let model: SearchResultRowModel

    var body: some View {
        MediaRow(coverURL: model.coverURL, placeholderSymbol: model.kind.symbol,
                 title: model.title, subtitle: model.subtitle)
    }
}
