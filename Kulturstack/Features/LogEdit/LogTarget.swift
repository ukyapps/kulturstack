import Foundation

// Ce qu'un nouveau log vise : une fiche déjà en base, ou un résultat de recherche
// pas encore enregistré — dans ce cas rien n'est écrit tant qu'on n'a pas enregistré.
enum LogTarget: Hashable, Identifiable {
    case item(UUID)
    case candidate(MediaCandidate)

    var id: String {
        switch self {
        case .item(let itemID): itemID.uuidString
        case .candidate(let candidate): candidate.id
        }
    }
}
