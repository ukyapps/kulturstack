import Foundation
import Testing
@testable import Kulturstack

struct SecretsTests {
    @Test func missingSecretErrorTellsHowToAddIt() {
        let secrets = BundleSecrets(info: [:])
        #expect(throws: SecretsError.missing(.tmdbReadToken)) {
            try secrets.value(for: .tmdbReadToken)
        }
        let message = SecretsError.missing(.tmdbReadToken).localizedDescription
        #expect(message.contains("security add-generic-password -s kulturstack -a TMDB_READ_TOKEN -w"))
    }

    @Test(arguments: ["", "   ", "$(TMDB_READ_TOKEN)"])
    func blankOrUnresolvedValueCountsAsMissing(raw: String) {
        let secrets = BundleSecrets(info: ["TMDBReadToken": raw])
        #expect(throws: SecretsError.missing(.tmdbReadToken)) {
            try secrets.value(for: .tmdbReadToken)
        }
    }

    @Test func presentValueIsReturnedTrimmed() throws {
        let secrets = BundleSecrets(info: ["TMDBReadToken": " eyJabc "])
        #expect(try secrets.value(for: .tmdbReadToken) == "eyJabc")
    }

    @Test func bundleWithoutTheKeyReportsItMissing() {
        let secrets = BundleSecrets(bundle: Bundle(for: Marker.self))
        #expect(throws: SecretsError.missing(.tmdbReadToken)) {
            try secrets.value(for: .tmdbReadToken)
        }
    }

    private final class Marker {}

    @Test func mockSecretsBehavesLikeTheRealOne() throws {
        #expect(throws: SecretsError.missing(.tmdbReadToken)) {
            try MockSecrets().value(for: .tmdbReadToken)
        }
        #expect(try MockSecrets(values: [.tmdbReadToken: "x"]).value(for: .tmdbReadToken) == "x")
    }
}
