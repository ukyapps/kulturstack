import Foundation

// Quand le dernier rafraîchissement des saisons a eu lieu. Le Domain ne sait pas où c'est
// rangé — il sait seulement qu'il ne faut pas recommencer à chaque ouverture de l'app.
@MainActor
protocol RefreshHistory {
    func lastRefresh() -> Date?
    func record(_ date: Date)
}
