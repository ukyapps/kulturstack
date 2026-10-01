import Foundation

// La date du dernier rafraîchissement : une seule date, qui ne vaut rien si elle se perd.
// Elle n'a pas sa place dans la base — la perdre coûte un appel réseau, pas une donnée.
@MainActor
struct UserDefaultsRefreshHistory: RefreshHistory {
    static let key = "seasons.lastRefresh"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func lastRefresh() -> Date? { defaults.object(forKey: Self.key) as? Date }

    func record(_ date: Date) { defaults.set(date, forKey: Self.key) }
}
