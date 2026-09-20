# ADR-001 — Clé TMDB embarquée dans l'app en Tranche 1, proxy repoussé

- Statut : **accepted**
- Date : 2026-09-20
- Décideuse : founder, sur reco Claude

## Contexte

Le cadrage annonce une Tranche 1 « zéro backend ». La règle founder interdit tout secret dans un fichier versionné. Or une clé TMDB dans un binaire iOS est extractable, quoi qu'on fasse. Il faut choisir entre embarquer la clé (et accepter l'extraction) ou monter un proxy dès T1 (et perdre le « zéro backend »).

## Options

1. **Clé embarquée** via `Secrets.xcconfig` gitignoré généré depuis le Trousseau, injectée dans `Info.plist`.
2. **Proxy Supabase dès T1** : l'app ne connaît pas la clé.
3. Obfuscation de la clé dans le binaire — écartée : illusion de sécurité, complexité gratuite.

## Décision

**Option 1.** La clé TMDB est acceptée comme un **identifiant à faible valeur** : gratuite, non facturée, révocable. Pire cas = abus de quota → rotation. OpenLibrary n'a pas de clé. T1 n'embarque donc qu'un seul secret, le moins dangereux du projet.

La règle « jamais dans un fichier versionné » est respectée : la clé n'existe que dans le Trousseau, un xcconfig gitignoré, et le binaire.

## Conséquences

- T1 reste sans serveur : pas de latence supplémentaire, rien à héberger, l'app fonctionne même si un futur proxy tombe.
- Le proxy devient **obligatoire en Tranche 6** (IGDB `client_secret`, Setlist.fm) et pour l'IA (T7). TMDB migre derrière ce proxy à ce moment-là.
- Réévaluer avant si TMDB change ses conditions ou si un abus est constaté.
- Voir `docs/tdd/06-secrets.md`.
