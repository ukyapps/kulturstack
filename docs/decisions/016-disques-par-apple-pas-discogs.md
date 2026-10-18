# ADR-016 — Les disques se cherchent chez Apple, pas chez Discogs

- Statut : **accepted**, **prémisse amendée le 17/10** (voir ci-dessous)
- Date : 2026-10-17
- Contexte : tranche Disques (T4b du PRD). Même source et même tuyau que l'[ADR-013](013-sources-des-podcasts.md) pour les podcasts.

## Contexte

Quatre types d'œuvres sur neuf se cherchaient : films, séries, livres, podcasts. La founder, le 17/10 : « il manque encore pas mal de flux de données ». Les disques sont le premier des cinq types sans source.

Le PRD annonçait **Discogs** depuis le début — c'est la référence du disque, et la T5 (possessions) en a besoin pour les pressages. La question posée ici n'est pas « quelle est la meilleure base de disques » mais **« avec quoi logge-t-on “j'ai écouté cet album” »**.

## Ce qui a été mesuré le 17/10

Sur les vraies API, avant d'écrire une ligne.

| Question | Apple (`itunes.apple.com/search`) | Discogs |
|---|---|---|
| Faut-il une clé ? | **Non** | Non pour chercher |
| Trouve-t-il l'album ? | **24 sur 25** | oui, 131 éditions pour un seul album |
| Rend-il la pochette ? | **oui, 600 × 600 px** | **non — 0 sur 15 résultats** |
| Date, artiste, genre, nombre de pistes ? | oui | oui, plus le label, le format et le code-barres |
| Les pistes et leurs durées ? | **oui** — `lookup?entity=song`, 14 pistes datées pour *Random Access Memories* | oui |
| Quota | non documenté, ~20 req/min observé | **25 req/min** en anonyme (en-tête `x-discogs-ratelimit`) |

**L'échantillon Apple** : 25 albums choisis pour couvrir ce qui pouvait casser — international, francophone, jazz, classique, electro, indie. Résultat par catégorie : international 5/5, jazz 3/3, classique 3/3, electro 3/3, indie 3/3, indie francophone 1/1, **francophone 6/7**.

**Le seul raté : Stromae.** *Racine carrée* et *Multitude* sont absents du catalogue Apple France — vérifié de trois façons (titre + artiste, titre seul, artiste seul : « Stromae » ne rend que des singles et *Cheese*). Ce n'est pas un défaut de recherche, c'est un **trou de licence** dans le catalogue. Aucune règle de code ne le répare.

> C'est un échantillon **varié**, pas aléatoire : il n'existe pas de catalogue de référence d'où tirer au sort, contrairement aux 514 podcasts Radio France de l'[ADR-014](014-flux-radio-france-par-leur-page.md). Le chiffre de 24/25 décrit donc ce que couvrent ces catégories, pas un taux de couverture du catalogue mondial.

**Les pochettes de Discogs demandent un compte.** Mesuré sur trois requêtes et quinze résultats : `cover_image` et `thumb` sont des chaînes vides en anonyme. Une app où chaque ligne de Journal montre une jaquette ne peut pas se payer ça, et y remédier voudrait dire un secret de plus et cinq minutes de la founder — pour une couverture que l'autre source donne déjà.

## Décision

1. **Apple pour écouter.** Un `AppleAlbumProvider` cherche les disques, sans clé, sans compte, sans secret. C'est la **même API publique** que `ApplePodcastProvider` interroge depuis la T4a : le `HTTPClient`, la gestion d'erreur par section et le mécanisme de `retry` sont déjà là.
2. **La pochette se réécrit.** Apple ne rend que `artworkUrl100` sur un disque (pas d'`artworkUrl600` comme sur un podcast) ; l'adresse se réécrit en `600x600bb.jpg`. **Vérifié le 17/10** : HTTP 200, 42 Ko, 600 × 600 px réels. Une adresse qui ne suit pas le gabarit est gardée telle quelle.
3. **La clé externe nomme le type** : `itunes:album:<collectionId>`, comme TMDB distingue `tmdb:movie:` de `tmdb:tv:`. Les podcasts gardent `itunes:<id>` — les préfixer maintenant demanderait de réécrire les clés déjà dans la base de la founder, pour un risque de collision qui n'existe pas (les identifiants d'Apple sont uniques dans tout son catalogue).
4. **Discogs reste écrit, pour la T5.** Son catalogue d'éditions — pressages, formats, labels, codes-barres — est irremplaçable pour « je **possède** ce vinyle », et là un token se justifie : on cherche une édition précise, pas une œuvre. Apple ne donne pas le label (son champ `copyright` le contient parfois, en prose, et l'en extraire serait de la devinette).
5. **Pas de pistes cochables.** Un disque s'écoute d'un bloc : `MediaKind.album.hasDuration` est `false` depuis la T1, donc ses statuts sont « envie » et « terminé », sans « en cours ». Les pistes, si elles viennent, seront une liste à lire, pas une liste à cocher — et dans une PR à part.

## Conséquences

- **Aucun secret, aucune inscription, aucune minute de la founder** — comme l'ADR-014, et contrairement à l'ADR-015.
- **Aucun changement de schéma** : `MediaKind.album` et `SearchFamily.music` existent depuis la T1, les libellés FR / EN (`family.music` → « Disques » / « Albums », `kind.album`) aussi. Pas de `SchemaV4`, pas de migration, rien à sauvegarder avant d'installer.
- **La section « Disques » apparaît toute seule** dans la recherche : `SearchUseCase` déduit ses familles des providers déclarés.
- **Stromae manquera**, et c'est documenté plutôt que caché. Si la founder tombe sur d'autres trous de licence, le recours est Discogs ou MusicBrainz en second — exactement la forme de l'ADR-015 pour Radio France, à n'ouvrir que si l'usage le demande.
- Le quota d'Apple n'est pas documenté : une mesure trop rapide a renvoyé des réponses vides le 17/10 et a failli passer pour une absence de résultats. La recherche de l'app est pilotée au doigt, elle n'y touchera pas — mais **toute mesure en lot doit espacer ses appels**.

## Écartées

- **Discogs en source principale** : pas de pochette sans compte (mesuré), et un catalogue d'éditions là où on veut une œuvre.
- **MusicBrainz** : gratuit et sans clé, mais sans pochette lui non plus (il faut un second appel à Cover Art Archive), et sa recherche rend des groupes de sortie à désambiguïser. Reste le bon recours si Apple se ferme.
- **Apple Music API** (la vraie, `api.music.apple.com`) : demande un compte développeur payant et un token signé. L'API publique suffit.

---

## Amendement du 17/10 — la prémisse était fausse

Une heure après la fusion de la PR 37, la founder :

> « les disques, je les écoute pas, je les ai dans ma bibliothèque. »

Cet ADR a comparé les sources pour répondre à **« avec quoi logge-t-on *j'ai écouté cet album* »**. La vraie question était **« avec quoi dit-on *j'ai ce disque* »**. Ce qui reste vrai, et ce qui ne l'est plus :

| | |
|---|---|
| **Tient toujours** | Le choix d'Apple comme source : 24/25 avec pochette, sans clé. On ne peut pas dire « je l'ai » d'une œuvre qu'on ne sait pas trouver — la recherche, la fiche et la dédup de la PR 37 sont la fondation de la bibliothèque. |
| **Tient toujours** | Le point 5 — pas de pistes cochables. Il se trouve que c'est encore plus vrai qu'écrit : elle n'écoute pas le disque dans l'app du tout. |
| **Amendé** | « Apple pour **écouter** » devient « Apple pour **trouver** ». L'action mise en avant sur une fiche de disque se décide à l'usage, pas ici. |
| **Avancé** | Discogs était rangé « pour la T5, quand on voudra le format et l'édition ». La T5 a commencé le jour même (**ADR-017**). Le format n'est toujours pas demandé à l'écran, donc Discogs attend encore — mais il attend moins longtemps que prévu. |

> **La leçon n'est pas « il fallait mieux mesurer ».** Les chiffres étaient bons et le sont restés. Ce qui manquait n'était pas dans les API : c'était de lui demander **ce qu'elle fait d'un disque** avant de choisir avec quoi le journaliser. Une mesure répond bien à la question qu'on lui pose.
