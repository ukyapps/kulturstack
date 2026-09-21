import Foundation

// Ce qu'une vue garde d'un log pour ouvrir sa feuille : son id, jamais le @Model.
struct LogReference: Identifiable, Equatable {
    let id: UUID
}
