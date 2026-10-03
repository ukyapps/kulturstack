import Foundation
import Testing
@testable import Kulturstack

// Mesuré le 03/10 sur les 24 premiers résultats que rendent « france inter » et « france
// culture » chez Apple : aucun n'a de flux, 23 se retrouvent par leur page sur radiofrance.fr,
// dont 21 du premier coup. La fixture HTML est la page réelle de « Le code a changé », réduite
// à son en-tête.
struct RadioFrancePageTests {
    // MARK: - La station

    @Test func aRadioFranceStationGivesThePathOfItsPage() {
        let urls = RadioFrancePage.urls(title: "Le code a changé", publisher: "France Inter")

        #expect(urls.first?.absoluteString == "https://www.radiofrance.fr/franceinter/podcasts/le-code-a-change")
    }

    @Test func eachKnownStationHasItsOwnPath() {
        let paths = [("France Culture", "franceculture"), ("franceinfo", "franceinfo"),
                     ("France Musique", "francemusique"), ("FIP", "fip"), ("Mouv'", "mouv")]

        for (publisher, expected) in paths {
            let first = RadioFrancePage.urls(title: "Test", publisher: publisher).first
            #expect(first?.path() == "/\(expected)/podcasts/test", "\(publisher)")
        }
    }

    // Un producteur indépendant publie son flux chez Apple : il n'a aucune page à visiter ici,
    // et la source doit se taire plutôt que charger une page au hasard.
    @Test func aPublisherOutsideRadioFranceHasNoPage() {
        #expect(RadioFrancePage.urls(title: "Transfert", publisher: "Slate.fr").isEmpty)
        #expect(RadioFrancePage.urls(title: "Transfert", publisher: nil).isEmpty)
        #expect(RadioFrancePage.urls(title: "Transfert", publisher: "").isEmpty)
    }

    // Le piège mesuré le 03/10 : « Rádio FIP » est un autre podcast, qui a son flux chez Apple.
    // Reconnaître la station par un début de nom l'enverrait sur les pages de FIP.
    @Test func aPublisherThatMerelyContainsAStationNameIsNotThatStation() {
        #expect(RadioFrancePage.urls(title: "Bossa", publisher: "Rádio FIP").isEmpty)
        #expect(RadioFrancePage.urls(title: "Bossa", publisher: "Les amis de France Inter").isEmpty)
    }

    // « Mouv' » et « Mouv » désignent la même station ; les accents ne changent rien.
    @Test func theStationIsRecognisedWithoutItsPunctuation() {
        #expect(RadioFrancePage.urls(title: "Test", publisher: "Mouv").first?.path() == "/mouv/podcasts/test")
        #expect(RadioFrancePage.urls(title: "Test", publisher: "FRANCE INTER").first?.path() == "/franceinter/podcasts/test")
    }

    // MARK: - L'adresse de la page

    @Test func theTitleBecomesASlug() {
        let cases = [("Grand bien vous fasse !", "grand-bien-vous-fasse"),
                     ("LSD, la série documentaire", "lsd-la-serie-documentaire"),
                     ("franceinfo Asie / Amérique", "franceinfo-asie-amerique"),
                     ("8h30 franceinfo", "8h30-franceinfo"),
                     ("Femmes d'exception", "femmes-d-exception"),
                     ("Affaires étrangères", "affaires-etrangeres")]

        for (title, expected) in cases {
            #expect(RadioFrancePage.urls(title: title, publisher: "France Inter").first?.path()
                    == "/franceinter/podcasts/\(expected)", "\(title)")
        }
    }

    // « Les Matins de France Culture » chez Apple, « les-matins » sur radiofrance.fr : le nom
    // de la station est dans le titre du podcast, pas dans l'adresse de sa page.
    @Test func theStationNameIsDroppedFromTheTitle() {
        let paths = RadioFrancePage.urls(title: "Les Matins de France Culture", publisher: "France Culture").map { $0.path() }

        #expect(paths.first == "/franceculture/podcasts/les-matins-de-france-culture")
        #expect(paths.contains("/franceculture/podcasts/les-matins"))
    }

    // « Les Grandes Traversées » chez Apple, « grandes-traversees » sur radiofrance.fr.
    @Test func theArticleIsDroppedAsASecondTry() {
        let paths = RadioFrancePage.urls(title: "Les Grandes Traversées", publisher: "France Culture").map { $0.path() }

        #expect(paths.first == "/franceculture/podcasts/les-grandes-traversees")
        #expect(paths.dropFirst().first == "/franceculture/podcasts/grandes-traversees")
    }

    // Chaque essai est une page de 450 Ko : trois suffisent — 21 des 23 podcasts retrouvés
    // l'ont été du premier coup, aucun n'a demandé un quatrième essai.
    @Test func thereAreNeverMoreThanThreeTries() {
        let urls = RadioFrancePage.urls(title: "Les Matins de France Culture", publisher: "France Culture")

        #expect(urls.count <= RadioFrancePage.maxAttempts)
        #expect(RadioFrancePage.maxAttempts == 3)
    }

    @Test func theSameAddressIsNeverTriedTwice() {
        let urls = RadioFrancePage.urls(title: "Affaires sensibles", publisher: "France Inter")

        #expect(urls.count == Set(urls).count)
        #expect(urls.count == 1)
    }

    // Un titre qui ne laisse aucune lettre ne donne pas une adresse de page vide.
    @Test func aTitleWithoutLettersGivesNoPage() {
        #expect(RadioFrancePage.urls(title: "…", publisher: "France Inter").isEmpty)
        #expect(RadioFrancePage.urls(title: "", publisher: "France Inter").isEmpty)
    }

    // MARK: - Le flux déclaré par la page

    // C'est la balise que lit n'importe quel lecteur de podcasts, et Radio France la publie :
    // c'est tout ce dont on a besoin.
    @Test func theFeedIsReadFromThePage() throws {
        let page = try Fixtures.data("radiofrance-le-code-a-change", extension: "html")

        let feed = RadioFrancePage.feedURL(inPage: page)

        #expect(feed?.absoluteString
                == "https://radiofrance-podcast.net/podcast09/podcast_3957c833-0b28-4314-8427-2a1d1e103381.xml")
    }

    @Test func aPageWithoutAFeedGivesNothing() {
        let page = Data("<html><head><title>Rien</title></head><body>Rien</body></html>".utf8)

        #expect(RadioFrancePage.feedURL(inPage: page) == nil)
    }

    // Une page déclare plusieurs liens « alternate » : la version mobile, les traductions.
    // Seul celui qui annonce un flux RSS compte.
    @Test func onlyAnRSSAlternateCounts() {
        let page = Data("""
        <html><head>
        <link rel="alternate" hreflang="en" href="https://www.radiofrance.fr/en/podcasts/x"/>
        <link rel="alternate" href="https://example.org/atom" type="application/atom+xml"/>
        <link rel="stylesheet" href="https://example.org/feed.rss"/>
        <link rel="alternate" href="https://radiofrance-podcast.net/podcast09/podcast_abc.xml" type="application/rss+xml"/>
        </head></html>
        """.utf8)

        #expect(RadioFrancePage.feedURL(inPage: page)?.absoluteString
                == "https://radiofrance-podcast.net/podcast09/podcast_abc.xml")
    }

    @Test func aPageThatIsNotHTMLGivesNothing() {
        #expect(RadioFrancePage.feedURL(inPage: Data()) == nil)
        #expect(RadioFrancePage.feedURL(inPage: Data([0xFF, 0xFE, 0x00])) == nil)
    }
}
