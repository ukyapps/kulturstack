---
type: journal
dates: 2026-09-22 (matin)
statut: PR 8b ouverte (#11), review locale PASS
---

# Session 9 — Fiche depuis la Recherche (PR 8b)

## Décisions produit (founder, à l'écran)

1. **Tap sur un résultat = fiche de l'œuvre**, même pas encore en base (aperçu avec « Logger »).
2. **Un « + » au bout de chaque ligne logge en un geste** — idée de la founder pendant la démo : « on pourrait pas mettre le petit + de logger à la fin de chaque ligne ? que ce soit plus rapide ». C'est le compromis qui garde le log en un tap tout en ouvrant la fiche au tap. Le bandeau « loggé ✓ · Modifier » revient sur le + (« ça me met plus la petite barre orange… qu'on avait avant »).

## Ce qui a été fait

- PR #10 (fiche) fusionnée.
- **PR 8b** sur `feat/search-detail` :
  - `ItemDetailViewModel.Subject` = `.stored(UUID)` | `.candidate(MediaCandidate)`. Un candidat déjà en base (une clé partagée) devient sa fiche réelle ; sinon aperçu (`ItemDetailModel(candidate:)`, aucun log, source = provider). `log()` : `logNow(candidate)` la première fois, puis `logAgain`. Bouton « Logger » sans log, « Logger à nouveau » ensuite ; retour haptique.
  - Recherche : ligne = `NavigationLink(value: candidate)` → fiche ; accessoire = pastille « Vu le … » + bouton **+** (`.borderless` pour ne pas déclencher la navigation) ; bandeau 4 s avec « Modifier » ; les pastilles se rafraîchissent sur `ModelContext.didSave` (log fait depuis la fiche).
  - Message du vide initial mis à jour : « Tape sur un résultat pour voir sa fiche, ou sur son + pour le logger tout de suite. »
  - 5 tests (147). Domain 95 %, Features 87 %.
- Vérifié par la founder : Oppenheimer (jamais loggé) → fiche « aperçu » avec « Logger » ; + sur Dune et Dune : Prophecy → pastilles + bandeau ; fiche depuis la ligne → log dans « Tes logs ».

## Choix faits

- Pas d'alerte pour un échec du + : bandeau rouge, comme avant.
- Pas de double tap (pas un geste iOS, retarde chaque tap). Écrit dans `retours-utilisateurs.md`.
- `Toast` reste dans le design system (réutilisé par le +).

## À faire — founder

- [ ] Fusionner la PR #11 quand `test` est vert.
- [ ] Réserver `kulturstack.com` + `kulturstack.app`.

## À faire — prochaine session Claude

1. Petite PR « détails TMDB » : `movie/{id}` / `tv/{id}` au premier log pour réalisateur, durée, genres, saisons (la fiche d'un film est vide sans ça).
2. PR 9 : Journal par période / type, compteurs, groupé par jour (`docs/plans/tranche-1.md`, design §3.1).
