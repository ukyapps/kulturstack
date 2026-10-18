---
type: plan
tranche: Bibliothèque (T5 du PRD, avancée — décision founder du 17/10)
statut: en cours — PR 38 (schéma V4) écrite
créé: 2026-10-17
---

# Plan — Ma bibliothèque

**Objectif** : à la fin, une œuvre peut être **dans ta bibliothèque** sans que tu l'aies consommée, et consommée sans être dans ta bibliothèque. Un bouton visible sur la fiche, un onglet pour les voir toutes.

**Ce qui déclenche cette tranche** : la founder, le 17/10 — « les disques, je les écoute pas, je les ai dans ma bibliothèque. d'ailleurs sur les livres, rajoute une option sur j'ai dans ma bibliothèque ».

C'est une **correction de prémisse**, pas une demande de confort : la tranche Disques venait d'être construite sur « un disque se logge comme un film ». Décisions : **ADR-017**, qui met en œuvre l'**ADR-010** écrit le 20/09.

## Ce qui est tranché, et par qui

| Question | Réponse | Qui |
|---|---|---|
| Où se voit la bibliothèque ? | **Un cinquième onglet** — Journal · Envie · En cours · Bibliothèque · Recherche | **founder**, contre ma reco du segment dans Envie |
| Possédé et consommé, un seul objet ? | **Non, deux relations indépendantes** — `LogEntry` et `OwnedCopy` | ADR-010 (20/09) |
| Quels types se possèdent ? | Films, séries, livres, disques, jeux. **Pas** podcasts, concerts, pièces, expos | moi, à confirmer à l'usage |
| Le format (vinyle, CD, poche) ? | **Pas demandé à l'écran** pour l'instant. Le champ existe, il reste vide | moi, d'après « j'ai dans ma bibliothèque » |

## Ce que ça implique pour le modèle

**Un `SchemaV4` et une migration.** `OwnedCopy` est un nouveau modèle, plus un lien optionnel depuis `MediaItem` : étage **lightweight**, aucune ligne existante réécrite.

C'est la **première migration depuis le 27/09**. Elle se vérifie sur l'iPhone avant fusion, procédure du 24/09 : sauvegarde du store, comparaison ligne à ligne avant / après. Mode d'emploi dans `docs/journal/2026-09-24-lancement-tranche-2.md`.

## Périmètre

**Dedans** : le modèle, le bouton « Dans ma bibliothèque » sur la fiche, le cinquième onglet avec ses trois rendus, le seed DEBUG, les compteurs.

**Dehors, même « vite fait »** :
- **Le format et l'édition** (vinyle / CD / poche, pressage) : le modèle les porte, l'écran ne les demande pas. À ouvrir quand elle le réclame — et là, Discogs redevient la bonne source (ADR-016).
- Le **scan de code-barres** et l'**import de collection Discogs** : la suite de la T5, pas cette tranche.
- **Prêter / emprunter**, l'état d'un exemplaire, sa valeur : rien de tout ça n'a été demandé.
- Mélanger possession et logs dans le Journal : ce sont deux relations, elles gardent deux écrans.

## Règles du plan

Les mêmes qu'en T1, T2, Podcasts et Disques :
- 1 PR = 1 branche = 1 jour max = **quelque chose de visible à l'écran** à la fin.
- Tests d'abord, strings FR + EN dans la même PR, captures vide / rempli dans la description.
- **PR sur `main`, jamais empilée** (leçon de la #44).
- **Relire ce plan contre le diff à la fin de la PR**, pas seulement au début (leçon du 03/10).

---

## PR 38 — Schéma V4 : `OwnedCopy` `feat/schema-v4-bibliotheque`

**Livre** : le modèle, ses règles, son étage de migration. Aucune interface, sauf le badge DEBUG qui affiche « Base V4 ».

- `OwnedCopy { id, format?, editionRef?, acquiredAt?, notes?, createdAt, item }` et `MediaItem.ownedCopies` en cascade.
- `MediaItem.isOwned` : au moins un exemplaire. Un seul suffit à répondre « je l'ai ».
- `MediaKind.canBeOwned` : le modèle **refuse** un podcast ou un concert plutôt que de l'accepter en silence.
- Une œuvre peut porter **plusieurs exemplaires** — le vinyle et le CD sont deux lignes, l'œuvre reste une.
- Tests : **T-01 troisième étage** — un store V3 **peuplé** (podcast, épisode coché par son `guid`, logs notés) rouvert avec le plan V4 ; tout intact, bibliothèque vide, et **rien n'est devenu « possédé » par accident**. Plus l'indépendance des deux relations dans les trois sens, les types refusés, la cascade de suppression.

**Démo** : le badge DEBUG affiche « Base V4 ». Peu spectaculaire, assumé — comme les PRs 12 et 30.

> **Ne pas fusionner avant d'avoir vérifié la migration sur son iPhone.**

## PR 39 — « Dans ma bibliothèque » `feat/bibliotheque`

**Livre** : le bouton sur la fiche, et le cinquième onglet.

- Un **bouton visible** sur la fiche, à côté de « Logger » et « Envie » — jamais un geste caché, c'est la règle depuis le 22/09. Il bascule : on peut se tromper et se dédire.
- Absent des fiches qui ne peuvent pas se posséder (`canBeOwned`).
- L'onglet **Bibliothèque**, une ligne par œuvre, avec son `EmptyState` conçu en même temps que l'écran.
- **Trois rendus distincts** : bibliothèque vide (rien possédé) ≠ erreur de chargement ≠ filtre sans résultat, comparés image contre image.
- Strings FR + EN. Retour haptique sur le bouton, comme tous les autres depuis la #70.
- Tests : basculer, se dédire, idempotence (deux appuis ne font pas deux exemplaires), un podcast n'a pas le bouton, l'onglet liste ce qui est possédé et rien d'autre.

## PR 40 — Le seed DEBUG et les compteurs `chore/bibliotheque-seed`

**Livre** : le seed crée des œuvres possédées — dont une possédée **sans** être consommée, et une consommée **sans** être possédée. C'est le seul moyen de voir les trois cas sans rien saisir.

## Ce qu'on vérifie avant de dire « shippé »

- [ ] **La base de la founder survit à la migration V4** — testée sur son iPhone, avec ses vrais logs et ses épisodes cochés.
- [ ] T-01 vert dans sa version V3 → V4 **avec des données**.
- [ ] Rien n'est devenu « possédé » tout seul à la migration.
- [ ] Trois rendus distincts sur l'onglet Bibliothèque, comparés image contre image.
- [ ] Le bouton n'apparaît pas sur un podcast.
- [ ] Coverage ≥ 70 % Domain et Data, ≥ 50 % Features.
- [ ] Aucune string en dur, FR + EN dans la même PR.
- [ ] Captures vide **et** rempli dans chaque PR.
- [x] Aucun secret : cette tranche n'en introduit aucun.

## Ce que cette tranche ne résout pas

**Elle ne dit pas dans quel format tu l'as.** Pour « mon pressage de 1977 », il faut l'édition — donc Discogs, donc un token, donc une autre tranche.

**Elle ne range rien à ta place.** Chaque œuvre entre dans la bibliothèque à la main, une par une. L'import d'une collection Discogs existante est écrit dans le PRD et reste à faire.
