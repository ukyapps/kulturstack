import Foundation

// Le fichier que la founder peut sortir de l'app en deux taps, sans Mac et sans câble.
//
// Né du 25/10 : la sauvegarde automatique du Mac marchait, mais elle n'avait rien à
// sauvegarder depuis sept jours — le téléphone n'avait pas été branché une seule fois. Une
// sauvegarde qui demande un geste qu'on ne fait pas n'est pas une sauvegarde.
//
// Le format porte un numéro de version : c'est lui qui permettra de le relire plus tard, y
// compris quand le schéma aura changé.
struct KulturstackExport: Codable, Equatable {
    static let currentFormatVersion = 1

    let formatVersion: Int
    let exportedAt: Date
    let app: String
    let items: [Item]

    struct Item: Codable, Equatable {
        let id: UUID
        let kind: String
        let title: String
        let originalTitle: String?
        let year: Int?
        let creators: [String]
        let summary: String?
        let coverURL: URL?
        // La poche de détails telle quelle : la relire ne demande pas de connaître son type.
        let detailsJSON: String?
        let externalKeys: [String]
        let logs: [Log]
        let seasons: [Season]
        let ownedCopies: [OwnedCopy]
    }

    struct Log: Codable, Equatable {
        let id: UUID
        let date: Date
        let status: String
        let rating: Int?
        let note: String?
        let source: String
        // Un log d'épisode désigne son épisode par sa clé, jamais par sa position : les flux
        // de podcasts se tronquent, et une position se décalerait sous les coches.
        let episodeKey: String?
    }

    struct Season: Codable, Equatable {
        let key: String
        let number: Int
        let title: String?
        let episodes: [Episode]
    }

    struct Episode: Codable, Equatable {
        let key: String
        let number: Int
        let title: String?
        let airDate: Date?
        let runtimeMinutes: Int?
        let externalID: String?
    }

    struct OwnedCopy: Codable, Equatable {
        let id: UUID
        let format: String?
        let editionRef: String?
        let acquiredAt: Date?
        let notes: String?
        let createdAt: Date
    }
}

extension JSONEncoder {
    // ISO 8601 et clés triées : un fichier qu'on peut relire à l'œil dans six mois, et dont
    // deux exports identiques donnent deux fichiers identiques.
    static var kulturstackExport: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

extension JSONDecoder {
    static var kulturstackExport: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
