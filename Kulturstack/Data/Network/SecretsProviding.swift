import Foundation

protocol SecretsProviding: Sendable {
    func value(for key: SecretKey) throws -> String
}

enum SecretKey: String, Sendable, CaseIterable {
    case tmdbReadToken = "TMDBReadToken"
    // Podcast Index signe chaque requête avec les deux : SHA-1 de la clé, du secret et de l'heure.
    case podcastIndexKey = "PodcastIndexKey"
    case podcastIndexSecret = "PodcastIndexSecret"

    var keychainAccount: String {
        switch self {
        case .tmdbReadToken: "TMDB_READ_TOKEN"
        case .podcastIndexKey: "PODCASTINDEX_KEY"
        case .podcastIndexSecret: "PODCASTINDEX_SECRET"
        }
    }
}

enum SecretsError: Error, Equatable, LocalizedError {
    case missing(SecretKey)

    var errorDescription: String? {
        switch self {
        case .missing(let key):
            "\(key.keychainAccount) manquant. Ajouter : security add-generic-password -s kulturstack -a \(key.keychainAccount) -w"
        }
    }
}
