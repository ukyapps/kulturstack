import Foundation
import Testing

enum Fixtures {
    static func data(_ name: String, extension ext: String = "json") throws -> Data {
        let url = try #require(Bundle(for: Marker.self).url(forResource: name, withExtension: ext))
        return try Data(contentsOf: url)
    }

    private final class Marker {}
}
