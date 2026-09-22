import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Label(String(localized: "search.offline"), systemImage: "wifi.slash")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s)
            .background(Color.surfaceSecondary)
            .accessibilityElement(children: .combine)
    }
}

#Preview {
    OfflineBanner()
}
