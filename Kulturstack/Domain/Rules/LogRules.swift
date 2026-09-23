enum LogRules {
    static let ratingRange = 1...10

    static func validate(status: LogStatus, for kind: MediaKind) throws {
        guard kind.allowedStatuses.contains(status) else {
            throw DomainError.statusNotAllowed(status, for: kind)
        }
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
