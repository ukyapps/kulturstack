@testable import Kulturstack

struct MockSecrets: SecretsProviding {
    var values: [SecretKey: String] = [:]

    func value(for key: SecretKey) throws -> String {
        guard let value = values[key], !value.isEmpty else { throw SecretsError.missing(key) }
        return value
    }
}
