import SwiftUI

struct CoverThumbnail: View {
    let url: URL?
    let placeholderSymbol: String
    var width: CGFloat = 44

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: Radius.s))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Color.surfaceSecondary
            Image(systemName: placeholderSymbol)
                .font(.system(size: width * 0.4))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

#Preview {
    HStack {
        CoverThumbnail(url: nil, placeholderSymbol: "film")
        CoverThumbnail(url: nil, placeholderSymbol: "book.closed", width: 80)
    }
}
