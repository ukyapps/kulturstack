import Foundation
import Testing
@testable import Kulturstack

struct OpenLibraryProviderTests {
    private let userAgent = "Kulturstack/0.1.0 (+https://github.com/ukyapps/kulturstack)"

    private func makeProvider(client: StubHTTPClient, language: String = "fre") -> OpenLibraryProvider {
        OpenLibraryProvider(client: client, userAgent: userAgent, language: language)
    }

    private func murakami(_ client: StubHTTPClient) async throws -> [MediaCandidate] {
        try await makeProvider(client: client).search("murakami")
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
        #expect(query["q"] == "dune messiah language:fre")
        #expect(query["limit"] == "20")
        #expect(query["fields"]?.contains("cover_i") == true)
    }

    @Test func httpFailurePropagates() async {
        let client = StubHTTPClient(error: HTTPError.status(503))

        await #expect(throws: HTTPError.status(503)) {
            try await makeProvider(client: client).search("dune")
        }
    }

    // MARK: - Les livres en français d'abord (retour du 27/09)

    // « Si je tape murakami kafka, je tombe pas du tout sur Kafka sur le rivage. Je vois surtout
    // un livre avec le titre en japonais. » OpenLibrary rend le titre de l'œuvre **originale** ;
    // celui de l'édition française est dans la sous-requête `editions`.
    @Test func aWorkIsNamedAfterItsFrenchEdition() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-murakami-fr"))

        let candidates = try await murakami(client)
        let kafka = try #require(candidates.first { $0.id == "ol:work:OL2625431W" })

        #expect(kafka.title == "Kafka sur le Rivage")
        #expect(candidates.map(\.title).contains("Danse, danse, danse"))
        #expect(candidates.allSatisfy { !$0.title.isEmpty })
    }

    @Test func theCoverIsTheFrenchOneWhenThereIsOne() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-murakami-fr"))

        let kafka = try #require(try await murakami(client).first { $0.id == "ol:work:OL2625431W" })

        #expect(kafka.coverURL == URL(string: "https://covers.openlibrary.org/b/id/8125849-M.jpg"))
    }

    // Le nom de l'auteur est rendu en japonais par la source ; sa variante latine existe à côté.
    @Test func anAuthorWrittenInAnotherScriptFallsBackOnItsLatinName() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-murakami-fr"))

        let kafka = try #require(try await murakami(client).first { $0.id == "ol:work:OL2625431W" })

        #expect(kafka.creators.first == "Haruki Murakami")
    }

    @Test func aLatinAuthorNameIsLeftAlone() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-dune"))

        let dune = try #require(try await makeProvider(client: client).search("dune").first)

        #expect(dune.creators == ["Frank Herbert"])
    }

    @Test func theSearchAsksForTheLanguageOfTheApp() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-murakami-fr"))

        _ = try await murakami(client)
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(query["q"] == "murakami language:fre")
        #expect(query["fields"]?.contains("editions.title") == true)
        #expect(client.calls.count == 1)
    }

    @Test func anEnglishAppAsksForEnglishEditions() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("openlibrary-search-dune"))

        _ = try await makeProvider(client: client, language: "eng").search("dune")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))

        #expect(components.queryItems?.first { $0.name == "q" }?.value == "dune language:eng")
    }

    // Un livre sans édition française ne doit pas disparaître : vérifié sur l'API réelle,
    // « refactoring martin fowler language:fre » ne renvoie rien du tout.
    @Test func aBookWithoutAFrenchEditionIsSearchedAgainWithoutTheFilter() async throws {
        let client = StubHTTPClient(sequence: [
            .success(Data(#"{"numFound":0,"docs":[]}"#.utf8)),
            .success(try Fixtures.data("openlibrary-search-dune")),
        ])

        let candidates = try await makeProvider(client: client).search("dune")

        #expect(candidates.count == 20)
        #expect(client.calls.count == 2)
        let second = try #require(URLComponents(url: client.calls[1].url, resolvingAgainstBaseURL: false))
        #expect(second.queryItems?.first { $0.name == "q" }?.value == "dune")
    }

    @Test func aSearchWithResultsDoesNotAskTwice() async throws {
        let client = StubHTTPClient(sequence: [.success(try Fixtures.data("openlibrary-search-murakami-fr")),
                                               .failure(HTTPError.status(500))])

        #expect(try await murakami(client).isEmpty == false)
        #expect(client.calls.count == 1)
    }

    @Test func declaresBooksOnly() {
        let provider = makeProvider(client: StubHTTPClient(data: Data()))
        #expect(provider.id == "openlibrary")
        #expect(provider.supportedKinds == [.book])
    }
}
