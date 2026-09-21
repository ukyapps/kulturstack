---
type: journal
dates: 2026-09-21 (nuit, fin)
statut: PR 6 ouverte (#8), review locale PASS
---

# Session 6 — Le log en 1 tap (PR 6)

## Décision produit

**Tap = loggé immédiatement**, bandeau « loggé ✓ » 4 s (founder, 21/09). Inscrit dans `docs/product/design.md` §6.

## Ce qui a été fait

- PR #7 (écran Recherche) fusionnée.
- **PR 6** sur `feat/one-tap-log` :
  - `MediaRepository` (protocole) + `SwiftDataMediaRepository` : `findItem(withAnyKey:)` par `#Predicate` sur `ExternalRef.key`, `add(item, refs:)`, `add(refs, to:)`, `add(log)`.
  - `DedupUseCase.existingItem(for:)` : une fiche partageant au moins une clé externe (ADR-004).
  - `LogUseCase.logNow(candidate, status:)` : valide le statut, retrouve ou crée la fiche (champs communs + poche encodée + `ExternalRef` pour chaque clé), ajoute les clés que la fiche ne connaissait pas, crée le log `done` / `manual` / maintenant.
  - `SearchViewModel.log(candidate)` avec `logNow` injecté (closure), toast 4 s, toast rouge en cas d'échec. Chaque ligne de résultat est un bouton.
  - `Toast` dans le design system. Le Journal se recharge sur `ModelContext.didSave`.
  - **`LogRepository` déplacé de `Data/` vers `Domain/Repositories/`** : les use cases de `Domain/` ne peuvent pas importer `Data/`. Écart au TDD 01 documenté dans l'état du projet.
  - 3 clés FR / EN, 8 tests (97). Domain 95 %.
- Vérifié à la main : tap → bandeau → Journal à jour. Re-taps → **1 fiche, 7 logs** (badge DEBUG) : la dédup marche, et un re-tap est un revisionnage, comme voulu.

## Ce que la démo a révélé

La founder a tapé 7 fois sur Dune. Vérifié dans la base du simulateur (`sqlite3` sur `Kulturstack.store`) : 7 `createdAt` espacés de 1 à 12 s → 7 taps, pas un bug. Mais rien sur la ligne ne dit « déjà loggé » — le design §3.2 prévoit « Vu le 12 mars » sur la ligne. **À faire en PR 8** (avec la fiche, qui a besoin de la même requête « logs de cette œuvre »).

## Choix faits

- Le bandeau n'a **pas** de bouton « Modifier » tant que la feuille d'édition n'existe pas (PR 7) : pas de bouton mort.
- Appui long = Envie : reporté à la PR 10 (Envie), `logNow(status: .wishlist)` est déjà testé.
- `logNow` est injecté dans `SearchViewModel` comme closure `(MediaCandidate) throws -> Void`, pas comme protocole : une seule fonction, ça suffit ; un protocole viendra si un second usage apparaît.
- Rechargement du Journal par `NotificationCenter` (`ModelContext.didSave`) : simple, couvre aussi les futurs écrans qui écrivent. Non testé unitairement (vue), vérifié à la main.

## Pièges

1. **Encore** un container SwiftData libéré dans un test (`let (_, useCase) = try makeUseCase()`) → crash. Troisième fois. Règle : dans les tests, le `ModelContainer` est toujours dans une variable nommée, jamais `_`.
2. `logUseCase.logNow` passé directement comme closure : la signature avec paramètres par défaut ne se convertit pas en `(MediaCandidate) throws -> Void` → wrapper `{ try logUseCase.logNow($0) }`.

## À faire — founder

- [ ] Fusionner la PR #8 quand `test` est vert.
- [ ] Réserver `kulturstack.com` + `kulturstack.app`.

## À faire — prochaine session Claude

1. Lire `docs/etat-du-projet.md`.
2. PR 7 : modifier un log (`docs/plans/tranche-1.md`, design §3.4). Brancher « Modifier » sur le bandeau et l'appui long du Journal.
