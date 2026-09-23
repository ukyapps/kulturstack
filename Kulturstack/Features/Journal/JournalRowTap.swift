import Foundation

// Ce qu'un tap sur une ligne du Journal ou de l'Envie ouvre : la fiche de l'œuvre.
// Un log orphelin (sa fiche a disparu) n'a rien à ouvrir : il retombe sur la modification.
enum JournalRowTap: Equatable {
    case showItem(UUID)
    case edit(UUID)

    var hint: String {
        switch self {
        case .showItem: String(localized: "journal.row.hint")
        case .edit: String(localized: "journal.row.hint.edit")
        }
    }
}
