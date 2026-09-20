# ADR-008 — Nom : Kulturstack

- Statut : **accepted**
- Date : 2026-09-20 (sprint naming des 2026-09-19/20)

## Contexte

« TVTIMEbis » était un placeholder. Direction retenue après itérations : un nom qui parle de **l'objet** (la pile de culture), dans la famille Letterboxd / Discogs / Goodreads / TV Time. Finalistes : Backlog (abandonné : ≥ 4 apps concurrentes portent ce nom, dont deux trackers multi-média), Culture Time, Culture Stack, Kulturstack, Kulturklub.

## Décision

**Kulturstack.** Vérifié le 2026-09-19 : `kulturstack.com` / `.app` / `.io` / `.fr` sans DNS (libres), aucune app sur l'App Store, aucune occurrence notable sur le web.

Kulturklub écarté : mot allemand générique (dizaines d'associations), `.com` et `.de` pris, et promet une communauté alors que le produit est un journal perso. Gardé en réserve comme nom possible de la feature sociale (T7, « le Klub »).

## Conséquences

- Bundle id `com.ukyapps.kulturstack`, repo `ukyapps/kulturstack`, service Trousseau `kulturstack`.
- À faire par la founder : réserver `kulturstack.com` + `.app` ; recherche INPI (5 min) avant publication.
