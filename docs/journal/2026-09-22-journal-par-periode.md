---
type: journal
dates: 2026-09-22 (fin de matinée)
statut: PR 9 ouverte (#13), review locale PASS
---

# Session 11 — Journal par période et par type (PR 9)

## Ce qui a été fait

- PR #12 (détails TMDB) fusionnée.
- **PR 9** sur `feat/journal-filters` :
  - `Period` (Domain/Models) : `week · month · year · all`, `range(containing:calendar:)` avec **semaine du lundi** quelle que soit la locale, bornes `[début, fin)` en heure locale.
  - `StatsUseCase` (Domain/UseCases) : `count` (**T-16** : des logs, pas des fiches — un film revu compte 2), `filter` (période × type, plus récent d'abord), `groupByDay` (Aujourd'hui, Hier, puis « mercredi 15 septembre », avec l'année si différente).
  - `JournalViewModel` : `period` (défaut **Semaine**, comme le design), `selectedKind`, `presentation` = loading · empty · failed · **edge(period, kind)** · loaded(`JournalContent` = sections + total) ; `kindCounts` (chips, un par type déjà loggé, compteur dans la période, 0 compris) ; `showAll()`. `now` et `calendar` injectables pour les tests.
  - `JournalView` : segments avec « Semaine · 54 » sur l'actif, chips horizontales avec compteurs, sections par jour (`SectionHeader`), edge « Rien à afficher — Pas de livres cette semaine. » + « Voir tout » (chips conservés).
  - 17 clés FR / EN, 14 tests (172). Domain 95 %, Features 90 %.
- Vérifié par la founder : « Semaine · 54 », Films · 38, Séries · 16, Livres · 0, section Aujourd'hui ; Semaine + Livres → edge.

## Ce que la démo a révélé

- **Bug attrapé par la founder** : en edge, je masquais les chips → impossible de changer de type autrement que par « Voir tout ». Corrigé : `kindCounts` est indépendant de la présentation, les chips restent. Test ajouté.

## Choix faits

- Filtrage **en mémoire** après `fetchAll()` (pas de `#Predicate` par période) : quelques centaines de logs au plus en T1, et ça rend `StatsUseCase` pur et testable avec un calendrier fixe (Europe/Paris). À revoir si l'import T3 amène des milliers de logs.
- Les envies (`wishlist`) comptent dans les compteurs pour l'instant : elles sont dans la liste. La PR 10 (chip Envie) tranchera.
- Genre en français : « Pas de **livres** cette semaine » (pluriel via `pluralLabel.lowercased()`) pour éviter « Aucun / Aucune ».
- « Tout » n'a pas de phrase de période : « Rien dans ton journal. » (n'arrive qu'avec un type filtré à 0 partout, ce qui est impossible puisqu'un chip n'existe que pour un type déjà loggé — le message est là par sécurité).

## À faire — founder

- [ ] Fusionner la PR #13 quand `test` est vert.
- [ ] Réserver `kulturstack.com` + `kulturstack.app`.

## À faire — prochaine session Claude

1. PR 10 : Envie (`docs/plans/tranche-1.md`, design §3.5) — appui long / ♡ sur un résultat, chip « Envie » du Journal avec son `EmptyState`, « Je l'ai vu » → log terminé, l'envie reste. Décider si les envies sortent des compteurs.
