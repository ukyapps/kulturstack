import Foundation
import SwiftData

extension KulturstackSchemaV4 {
    // « Je la possède » — l'autre relation à l'œuvre, indépendante des logs (ADR-010). Un
    // livre peut être dans la bibliothèque sans avoir été lu, et lu sans être possédé.
    @Model
    final class OwnedCopy {
        @Attribute(.unique) var id: UUID
        // Le format reste vide tant que rien ne le demande à l'écran : « je l'ai » se dit
        // sans préciser si c'est un vinyle ou un CD. ADR-010 en garde le vocabulaire.
        var format: String?
        var editionRef: String?
        var acquiredAt: Date?
        var notes: String?
        var createdAt: Date
        var item: MediaItem?

        private init(item: MediaItem, format: String?, editionRef: String?, acquiredAt: Date?, notes: String?) {
            self.id = UUID()
            self.format = format
            self.editionRef = editionRef
            self.acquiredAt = acquiredAt
            self.notes = notes
            self.createdAt = .now
            self.item = item
        }

        static func make(item: MediaItem, format: String? = nil, editionRef: String? = nil,
                         acquiredAt: Date? = nil, notes: String? = nil) throws -> OwnedCopy {
            guard item.kind.canBeOwned else { throw DomainError.ownershipNotAllowed(for: item.kind) }
            return OwnedCopy(item: item, format: format, editionRef: editionRef,
                             acquiredAt: acquiredAt, notes: notes)
        }
    }
}
