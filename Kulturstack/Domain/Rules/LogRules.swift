enum LogRules {
    static let ratingRange = 1...10

    static func validate(status: LogStatus, for kind: MediaKind) throws {
        guard kind.allowedStatuses.contains(status) else {
            throw DomainError.statusNotAllowed(status, for: kind)
        }
    }

    // Un log d'épisode porte l'œuvre de cet épisode, jamais une autre.
    static func validate(episode: Episode?, for item: MediaItem) throws {
        guard let episode else { return }
        guard episode.season?.item?.id == item.id else { throw DomainError.episodeNotOfThisItem }
    }

    static func validate(rating: Int?) throws {
        guard let rating else { return }
        guard ratingRange.contains(rating) else { throw DomainError.ratingOutOfRange(rating) }
    }

    // Un commentaire d'espaces n'est pas un commentaire.
    static func note(_ raw: String?) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
