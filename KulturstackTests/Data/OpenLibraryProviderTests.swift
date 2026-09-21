import Foundation
import Testing
@testable import Kulturstack

struct OpenLibraryProviderTests {
    private let userAgent = "Kulturstack/0.1.0 (+https://github.com/ukyapps/kulturstack)"

    private func makeProvider(client: StubHTTPClient) -> OpenLibraryProvider {
        OpenLibraryProvider(client: client, userAgent: userAgent)
    }

    @Test func parsesFixtureIntoBookCandidatesWithWorkAndISBNKeys() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-dune"))

        let candidates = try await makeProvider(client: client).search("dune")

        #expect(candidates.count == 20)
        #expect(candidates.allSatisfy { $0.kind == .book && $0.providerID == "openlibrary" })
        let dune = try #require(candidates.first)
        #expect(dune.id == "ol:work:OL893414W")
        #expect(dune.title == "Dune")
        #expect(dune.creators == ["Frank Herbert"])
        #expect(dune.year == 1965)
        #expect(dune.coverURL == URL(string: "https://covers.openlibrary.org/b/id/11481354-M.jpg"))
        #expect(dune.externalKeys.first == "ol:work:OL893414W")
        let isbns = dune.externalKeys.dropFirst()
        #expect(!isbns.isEmpty)
        #expect(isbns.allSatisfy { $0.hasPrefix("isbn13:") && $0.count == "isbn13:".count + 13 })
        #expect(isbns.count <= OpenLibraryProvider.maxISBNKeys)
    }

    @Test func fillsBookDetails() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-dune"))

        let dune = try #require(try await makeProvider(client: client).search("dune").first)
        let details = try #require(dune.details as? BookDetails)

        #expect(details.pageCount == 607)
        #expect(details.firstPublishYear == 1965)
        #expect(details.publisher != nil)
        #expect(!details.subjects.isEmpty)
        #expect(details.subjects.count <= 10)
    }

    @Test func sendsTheUserAgentAndTheExpectedQuery() async throws {
        let client = StubHTTPClient(data: Data(#"{"numFound":0,"docs":[]}"#.utf8))

        let candidates = try await makeProvider(client: client).search("dune messiah")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(candidates.isEmpty)
        #expect(call.headers["User-Agent"] == userAgent)
        #expect(components.host == "openlibrary.org")
        #expect(components.path == "/search.json")
        #expect(query["q"] == "dune messiah")
        #expect(query["limit"] == "20")
        #expect(query["fields"]?.contains("cover_i") == true)
    }

    @Test func httpFailurePropagates() async {
        let client = StubHTTPClient(error: HTTPError.status(503))

        await #expect(throws: HTTPError.status(503)) {
            try await makeProvider(client: client).search("dune")
        }
    }

    @Test func declaresBooksOnly() {
        let provider = makeProvider(client: StubHTTPClient(data: Data()))
        #expect(provider.id == "openlibrary")
        #expect(provider.supportedKinds == [.book])
    }
}
