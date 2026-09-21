import Foundation
import Testing
@testable import Kulturstack

@Suite(.serialized)
struct URLSessionHTTPClientTests {
    private let url = URL(string: "https://example.test/path?q=1")!

    @Test func sendsHeadersAndAppliesTheTimeout() async throws {
        StubURLProtocol.install { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer abc")
            #expect(request.timeoutInterval == 8)
            #expect(request.httpMethod == "GET")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("ok".utf8))
        }
        let client = URLSessionHTTPClient(session: StubURLProtocol.makeSession())

        let data = try await client.get(url, headers: ["Authorization": "Bearer abc"])

        #expect(String(decoding: data, as: UTF8.self) == "ok")
    }

    @Test func nonSuccessStatusIsAnError() async {
        StubURLProtocol.install { request in
            (HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data())
        }
        let client = URLSessionHTTPClient(session: StubURLProtocol.makeSession())

        await #expect(throws: HTTPError.status(401)) {
            try await client.get(url, headers: [:])
        }
    }

    @Test func transportFailurePropagates() async {
        StubURLProtocol.install { _ in throw URLError(.notConnectedToInternet) }
        let client = URLSessionHTTPClient(session: StubURLProtocol.makeSession())

        await #expect(throws: (any Error).self) {
            try await client.get(url, headers: [:])
        }
    }
}
