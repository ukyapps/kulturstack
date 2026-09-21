import Foundation

protocol SecretsProviding: Sendable {
    func value(for key: SecretKey) throws -> String
}

enum SecretKey: String, Sendable, CaseIterable {
    case tmdbReadToken = "TMDBReadToken"

    var keychainAccount: String {
        switch self {
        case .tmdbReadToken: "TMDB_READ_TOKEN"
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
