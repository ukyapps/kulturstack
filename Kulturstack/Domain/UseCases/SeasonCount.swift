import Foundation

// Combien de saisons une série compte, tel que la source le dit — rangé dans la fiche pour
// que les écrans qui ne vont pas sur le réseau (« En cours ») puissent le lire.
//
// Deux endroits l'écrivent : la fiche, qui recharge la liste à chaque ouverture, et le
// rafraîchissement du lancement. Une seule définition pour les deux, sinon elles finiraient
// par compter différemment.
enum SeasonCount {
    // Les spéciaux ne comptent pas : la saison 0 est le tiroir aux bonus, pas une saison.
    static func from(_ seasons: [SeasonSummary]) -> Int? {
        let count = seasons.filter { !$0.isSpecials }.count
        return count > 0 ? count : nil
    }

    // Rend vrai quand la fiche a appris quelque chose. Un compte nul n'est jamais écrit :
    // une source en panne ne doit pas effacer ce qu'on savait déjà.
    @discardableResult
    static func remember(_ count: Int, on item: MediaItem) throws -> Bool {
        guard item.kind == .series, count > 0 else { return false }
        var details = (item.details as? SeriesDetails) ?? SeriesDetails()
        guard details.seasonCount != count else { return false }
        details.seasonCount = count
        try item.setDetails(details)
        return true
    }
}
