# ADR-009 — Import Trakt par le ZIP JSON d'export, pas par OAuth

- Statut : **accepted**
- Date : 2026-09-20

## Contexte

Le cadrage de juillet prévoyait Trakt en OAuth (« seul import live propre »). Depuis début août 2026, créer une application API Trakt exige un compte VIP (4,99 $/mois) côté développeur ; des apps existantes ont été supprimées sans préavis ; Trakt ne présente pas la mesure comme temporaire. En parallèle, l'export de données (`Settings → Data → Export now`) reste **gratuit** et produit un ZIP de JSON : historique, notes, watchlist, listes, avec les IDs TMDB et IMDb.

## Décision

En T3, Trakt est importé **comme les autres sources : par fichier**. Un `TraktJSONImporter` conforme à `HistoryImporter` lit le ZIP. Pas de VIP, pas de backend, pas de dépendance à des T&Cs qui bougent.

L'OAuth (sync live) reste possible plus tard, en option, si la founder décide de payer le VIP.

## Conséquences

- Un peu plus de friction sur l'import (export manuel) — pas sur le cœur du produit.
- Les IDs TMDB/IMDb de l'export rendent la dédup (ADR-004) triviale.
- Format à re-vérifier au démarrage de T3.
