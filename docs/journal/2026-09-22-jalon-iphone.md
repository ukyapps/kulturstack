---
type: journal
dates: 2026-09-22 (début d'après-midi)
statut: Tranche 1 complète (14/14 PRs fusionnées) — jalon « sur l'iPhone » commencé, pas terminé
---

# Session 14 — Fin de la Tranche 1, jalon iPhone (interrompu)

## Où on en est

- **Tranche 1 complète** : les 15 PRs GitHub (#1 → #15) sont fusionnées, 195 tests verts, couverture Domain 96 % / Data 97 % / Features 87 %.
- **Checklist « avant de dire shippé »** (`docs/plans/tranche-1.md`) : tout est vert **sauf** les deux points qui demandent l'iPhone — « premier lancement = base vide sur chaque écran » et « installé sur l'iPhone de la founder ».

## Décisions founder

1. **Pas de TestFlight tout de suite.** La founder veut d'abord vérifier sur son iPhone « que tout fonctionne, que c'est comme je l'ai imaginé ». Clarifié : TestFlight n'est pas une publication (canal privé), et les catégories manquantes (disques, podcasts, jeux, concerts, théâtre, expos) sont voulues — T4, T6, T7 (ADR-011). Rien ne se publie sans son action.
2. **Installation par câble, sans le compte développeur** (identifiant Apple gratuit, « Personal Team », app valable 7 jours). Elle a un compte Apple Developer payant, gardé pour plus tard.

## Ce qui a été fait

- Checklist vérifiée : aucune string en dur, `Secrets.xcconfig` absent du repo, hook pre-commit actif, `PrivacyInfo.xcprivacy` présent, attribution TMDB visible, T-01 vert, seed idempotent (T-14), panne OpenLibrary (T-07), review locale sur chaque PR.
- Xcode ouvert avec le projet. **L'iPhone (« iPhone de Fanny ») est détecté par le Mac**, en cours d'appairage.
- **Pas encore fait** : ajouter un identifiant Apple dans Xcode → Settings → Accounts (la liste est vide au moment de clore), donc pas de signature configurée (`0 valid identities`), pas de `DEVELOPMENT_TEAM` dans `project.yml`, pas d'installation.

## À faire — prochaine session (reprendre ici)

1. **Xcode → Settings → Accounts → + → Apple ID** avec l'identifiant iCloud de la founder (gratuit). Vérifier qu'une ligne « Personal Team » apparaît.
2. Claude : mettre `DEVELOPMENT_TEAM` + `CODE_SIGN_STYLE: Automatic` dans `project.yml`, `make generate`.
3. iPhone branché, déverrouillé, « Faire confiance à cet ordinateur » ; activer **Mode développeur** (Réglages iOS → Confidentialité et sécurité → Mode développeur) si iOS le demande.
4. Dans Xcode : choisir « iPhone de Fanny » comme destination, ▶︎ Run. Première fois : sur l'iPhone, Réglages → Général → VPN et gestion de l'appareil → faire confiance au profil.
5. **Premier vrai lancement sur base vide** : vérifier l'`EmptyState` de chaque écran (Journal, Envie, Recherche), puis logger un vrai film.
6. La founder utilise l'app quelques jours ; on reprend avec ses retours réels avant d'écrire `docs/plans/tranche-2.md` (épisodes).

## À faire — founder

- [ ] Réserver `kulturstack.com` + `kulturstack.app`.
- [ ] Noter, en utilisant l'app, ce qui coince et ce qui manque (dans `retours-utilisateurs.md` à la prochaine session).

## Bilan de la journée du 22/09

Six PRs (#10 → #15), de 8h50 à 12h05 puis reprise : fiche, tap = fiche + « + » et ♡, détails TMDB, journal par période groupé par jour, onglet Envie, réglages. Trois bugs attrapés par la founder à la démo (chips en edge, envie qui restait listée, bandeau), sept décisions produit prises à l'écran et consignées. Le red flag « session > 4 h » a été nommé deux fois ; la founder a choisi de continuer, puis de clore proprement.
