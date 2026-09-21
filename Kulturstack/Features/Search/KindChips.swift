import SwiftUI

struct KindChips: View {
    let kinds: [MediaKind]
    @Binding var selection: MediaKind?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                Chip(title: String(localized: "chip.all"), isSelected: selection == nil) { selection = nil }
                ForEach(kinds, id: \.self) { kind in
                    Chip(title: kind.pluralLabel, isSelected: selection == kind) {
                        selection = selection == kind ? nil : kind
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
        }
    }
}
