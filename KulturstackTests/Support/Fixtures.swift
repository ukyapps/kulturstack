import Foundation
import Testing

enum Fixtures {
    static func data(_ name: String) throws -> Data {
        let url = try #require(Bundle(for: Marker.self).url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private final class Marker {}
}
