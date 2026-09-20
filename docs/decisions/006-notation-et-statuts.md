# ADR-006 — Demi-étoiles sur 5 stockées 1…10 ; statuts déclarés par type ; bibliothèque à part

- Statut : **accepted**
- Date : 2026-09-20

## Décision

**Notation** : 0,5 à 5 ★ par demi, stockée `rating: Int?` ∈ 1…10. Optionnelle. Conversions d'import sans perte : Trakt/IMDb `/10` → identique ; Goodreads `/5` → ×2 ; Letterboxd `0.5–5` → ×2.

**Statuts** : `wishlist` (envie), `inProgress` (en cours), `done` (terminé), `dropped` (abandonné). Chaque `MediaKind` déclare `allowedStatuses` :

| Type | envie | en cours | terminé | abandonné |
|---|---|---|---|---|
| film, disque, concert, théâtre, expo | ✓ | — | ✓ | — |
| série, livre, podcast, jeu | ✓ | ✓ | ✓ | ✓ |

Règle : « en cours » / « abandonné » n'existent que pour ce qui a une **durée qu'on traverse**. L'UI ne propose jamais un statut interdit ; le domaine le refuse (T-02).

Le statut vit sur `LogEntry`, pas sur la fiche : « envie » puis « vu » = deux logs ; un film revu = deux logs `done`.

**« Je l'ai dans ma bibliothèque »** n'est **pas** un statut : il se combine avec n'importe lequel (vinyle sous blister = possédé + envie ; DVD revu = possédé + terminé). C'est une entité à part, `OwnedCopy` (ADR-010). À l'écran, il apparaîtra au même niveau que les statuts dans les filtres.

**T1 livre** : `done` (1 tap, défaut) et `wishlist`. `inProgress` / `dropped` arrivent en T2 avec les épisodes.
