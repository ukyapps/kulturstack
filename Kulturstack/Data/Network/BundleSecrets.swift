import Foundation

struct BundleSecrets: SecretsProviding {
    private let info: [String: String]

    init(bundle: Bundle = .main) {
        info = bundle.infoDictionary?.compactMapValues { $0 as? String } ?? [:]
    }

    init(info: [String: String]) {
        self.info = info
    }

    func value(for key: SecretKey) throws -> String {
        let value = (info[key.rawValue] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else { throw SecretsError.missing(key) }
        return value
    }
}
