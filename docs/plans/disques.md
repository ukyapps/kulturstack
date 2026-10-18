---
type: plan
tranche: Disques (T4b du PRD)
statut: **livrée** (PR 37, #77) — prémisse corrigée par la founder le 17/10, voir ci-dessous
créé: 2026-10-17
---

# Plan — Disques

> ⚠️ **Prémisse corrigée le 17/10, après la fusion de la PR 37.** La founder : « les disques, je les écoute pas, je les ai dans ma bibliothèque. » Ce plan a été écrit pour *journaliser* un disque ; elle veut le *posséder*. La PR 37 reste la fondation — on ne dit pas « je l'ai » d'une œuvre qu'on ne sait pas trouver — mais la suite est dans `bibliotheque.md`, pas ici. **La PR 38 de ce plan (seed DEBUG) est abandonnée** : le seed des disques arrivera avec celui de la bibliothèque.

**Objectif** : à la fin, un disque se cherche, se logge et se relit dans le Journal comme un film. Pochette, artiste, année, nombre de pistes, genre. Rien à cocher : un album s'écoute d'un bloc.

**Ce qui déclenche cette tranche** : la founder, le 17/10 — « il manque encore pas mal de flux de données », puis « on fait les disques avec Apple » après la mesure des trois sources.

## Ce qui a été mesuré avant d'écrire ce plan

Trois types sans source ont été mesurés le 17/10 sur les vraies API — disques, jeux, concerts. Le détail et les chiffres sont dans l'**ADR-016** ; le résumé :

| Type | Source retenue | Coût | Couverture mesurée |
|---|---|---|---|
| **Disques** | **Apple** (`itunes.apple.com/search`) | **aucun** | **24/25**, pochette 600 px, pistes et durées disponibles |
| Jeux | IGDB | 2 secrets (Twitch) | Steam sans clé : 9/14, et **0/4 sur les exclusivités Nintendo** |
| Concerts | — | — | MusicBrainz : 6/15 réels, **0 artiste francophone de taille moyenne** |

**Le seul disque raté : Stromae** — *Racine carrée* et *Multitude* sont absents du catalogue Apple France, vérifié de trois façons. Trou de licence, pas défaut de recherche.

**Discogs est écarté comme source principale et gardé pour la T5** : ses pochettes demandent un compte (0 sur 15 résultats en anonyme), et son catalogue décrit des **éditions** là où on veut une **œuvre**. Pour « je possède ce pressage », il redeviendra le bon choix.

## Ce que ça implique pour le modèle

**Rien.** `MediaKind.album` existe depuis la T1, `SearchFamily.music` aussi, et leurs libellés FR / EN sont déjà dans `Localizable.xcstrings` (« Disques » / « Albums »). `album.hasDuration` est `false`, donc ses statuts sont **envie** et **terminé**, sans « en cours » — ce qui décrit bien un disque.

**Pas de `SchemaV4`, pas de migration, rien à sauvegarder avant d'installer.** C'est la première tranche depuis la T2 à ne toucher à aucun `@Model`.

## Périmètre

**Dedans** : chercher un disque, sa fiche (pochette, artiste, année, pistes, genre), le logger en un geste ou depuis sa fiche, le ♡ de l'Envie, le Journal et ses compteurs, le seed DEBUG.

**Dehors, même « vite fait »** :
- **Les pistes cochables.** Un disque s'écoute d'un bloc ; une liste de pistes à cocher, c'est le modèle des épisodes appliqué à quelque chose qui n'en a pas besoin. Si les pistes viennent, ce sera une **liste à lire** sur la fiche, dans une PR à part — et seulement si l'usage la réclame.
- **L'onglet « En cours »** : un disque n'a pas de statut « en cours » (voir ci-dessus), il n'y entre donc jamais.
- **Le label et le format** (vinyle, CD, pressage) : Apple ne les donne pas proprement. C'est le travail de Discogs, en T5.
- Les **jeux** et les **concerts** : mesurés, pas livrés. Les jeux demandent deux secrets, les concerts n'ont pas de source utilisable.
- La **lecture** : Kulturstack journalise, il ne joue rien.

## Règles du plan

Les mêmes qu'en T1, T2 et Podcasts :
- 1 PR = 1 branche = 1 jour max = **quelque chose de visible à l'écran** à la fin.
- Tests d'abord (rouge → vert), strings FR + EN dans la même PR, captures vide / rempli dans la description.
- Merge quand `test` est vert **et** que la review locale est PASS dans la PR.
- **Relire ce plan contre le diff à la fin de chaque PR**, pas seulement au début (leçon du 03/10 : la carte « Prochain épisode » et l'ordre des podcasts étaient écrits noir sur blanc, et livrés à l'envers).

**Estimation** : 2 PRs, 1 à 2 jours. Rien ne se ferme à une date.

---

## PR 37 — Chercher un disque chez Apple `feat/apple-albums`

**Livre** : une section « Disques » dans la recherche, alimentée par Apple, et la fiche qui va avec.

- `AppleAlbumProvider: MetadataProvider` — `itunes.apple.com/search?media=music&entity=album&country=<pays de l'app>`. **Pas de clé, pas de compte, pas de secret.**
- Clé de dédup `itunes:album:<collectionId>`, comme `tmdb:movie:` / `tmdb:tv:`. Les podcasts gardent `itunes:<id>` : les réécrire toucherait la base de la founder pour rien.
- `AlbumDetails` : nombre de pistes, genre. Pas de label — Apple ne le donne pas autrement qu'en prose dans son champ `copyright`, et l'en extraire serait de la devinette.
- **La pochette se réécrit** de `100x100bb` en `600x600bb` : Apple ne rend pas d'`artworkUrl600` sur un disque. Vérifié le 17/10 — 600 × 600 px réels, 42 Ko. Une adresse hors gabarit est gardée telle quelle.
- La section apparaît **sans code d'écran** : `SearchUseCase` déduit ses familles des providers déclarés.
- Tests : fixture réelle de 5 résultats, qui porte ses propres pièges — une compilation « Multi-interprètes » et **un autre artiste qui a sorti un disque du même titre** (c'est le test qui prouve qu'un titre ne fait pas une identité). Plus : pochette hors gabarit, disque sans pochette, date illisible, résultat sans nom, panne HTTP, requête envoyée, pays.

**Démo** : « random access memories » rend le disque de Daft Punk avec sa pochette ; le `+` le logge ; sa fiche affiche « Disque · Daft Punk », « 14 pistes · Pop ».

## PR 38 — Le seed DEBUG et les compteurs `chore/albums-seed`

**Livre** : le seed DEBUG crée un disque loggé, les compteurs du Journal montrent « Disques · n ».

- Un album avec sa pochette, son année et ses pistes, loggé avec une note — de quoi voir une ligne de Journal et une fiche remplie hors ligne.
- Les compteurs ne devraient **demander aucun code** : ils listent les types qui portent un log (c'est ce qui s'est passé pour les podcasts en PR 35).
- À vérifier en faisant les captures, c'est là que la PR 35 avait trouvé son bug : la fiche d'un podcast ne lisait les saisons que depuis la source, jamais depuis la base.

## Ce qu'on vérifie avant de dire « shippé »

- [x] Aucun changement de schéma — donc aucune migration à vérifier sur l'appareil.
- [ ] Trois rendus distincts sur la section Disques : **vide** (aucun résultat) ≠ **erreur** (réseau coupé, « Réessayer ») ≠ **edge** (filtre de type sans résultat), comparés image contre image.
- [ ] Un disque se logge en un geste depuis la recherche, et depuis sa fiche avec le formulaire.
- [ ] Le `+` sur un disque déjà loggé demande confirmation (mécanisme de la #22).
- [ ] Coverage ≥ 70 % Domain et Data, ≥ 50 % Features.
- [ ] Aucune string en dur, FR + EN dans la même PR.
- [ ] Captures vide **et** rempli dans chaque PR.
- [x] Aucun secret : cette tranche n'en introduit aucun.
- [ ] Sur l'iPhone : chercher un disque qu'elle écoute vraiment, et vérifier que la pochette est nette (c'est tout l'enjeu de la réécriture en 600 px).

## Ce que cette tranche ne résout pas

**Stromae.** Et tout autre trou de licence du catalogue Apple France. Le recours écrit est une seconde source — Discogs ou MusicBrainz — interrogée seulement quand Apple ne rend rien, exactement la forme de l'ADR-015 pour Radio France. À ouvrir si l'usage le demande, pas avant : un trou mesuré à 1 sur 25 ne justifie pas un deuxième tuyau.

**Le format et la possession.** « J'ai ce vinyle » n'est pas « j'ai écouté cet album » : c'est `OwnedCopy`, en T5, avec Discogs.
