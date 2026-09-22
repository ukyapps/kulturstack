import Foundation

// Ce qu'une vue garde d'une œuvre pour ouvrir sa fiche : son id, jamais le @Model.
struct ItemReference: Identifiable, Hashable {
    let id: UUID
}
