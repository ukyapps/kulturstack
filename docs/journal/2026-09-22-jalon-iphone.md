---
type: journal
dates: 2026-09-22 (début d'après-midi)
statut: Tranche 1 complète (14/14 PRs fusionnées) — app installée sur l'iPhone de la founder le 23/09
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

## Suite, le 23/09 — l'app tourne sur l'iPhone

Étapes réellement faites : identifiant Apple **personnel** (gratuit) ajouté dans Xcode → certificat « Apple Development » créé → mode développeur activé sur l'iPhone → build signé → `devicectl device install` → l'app s'ouvre après « Se fier » au profil (Réglages → Général → VPN et gestion de l'appareil).

Pièges rencontrés :
1. Xcode Settings introuvable : la barre de menus montre l'app active, il faut d'abord mettre Xcode au premier plan (ou ⌘,).
2. Première tentative de signature : « You already have a current Development certificate or a pending certificate request », puis « Your team has no devices ». Les deux se résolvent en relançant une fois l'iPhone connecté et déverrouillé.
3. `xcodebuild -destination id=...` attend l'**identifiant matériel** (`00008150-…`), pas l'UUID de `devicectl` (`F6A9436F-…`). D'où `generic/platform=iOS` pour compiler et l'UUID devicectl pour installer.
4. Le nom de l'équipe personnelle (« Jean Claude Hasson (Personal Team) ») ne correspond pas au nom du compte : Apple fige le nom d'une Personal Team à sa création et ne la renomme jamais. **Purement interne** — invisible dans l'app. Le nom public viendra du compte développeur payant, à vérifier avant l'App Store.

`make device` compile et installe sur l'iPhone branché en une commande. `DEVELOPMENT_TEAM` vit dans `Config/Secrets.xcconfig` (gitignoré), pas dans le dépôt public.

## À faire — prochaine session (reprendre ici)

1. Recueillir les retours d'usage réel de la founder (écrans vides vus sur l'iPhone, premier vrai log) → `docs/product/retours-utilisateurs.md`.
2. Réinstaller avec `make device` quand les 7 jours de la signature personnelle expirent.
3. Ensuite seulement : `docs/plans/tranche-2.md` (épisodes), ou TestFlight avec le compte développeur payant si la founder veut d'autres testeuses.

## À faire — founder

- [ ] Réserver `kulturstack.com` + `kulturstack.app`.
- [ ] Noter, en utilisant l'app, ce qui coince et ce qui manque (dans `retours-utilisateurs.md` à la prochaine session).
- [ ] (avant l'App Store) vérifier le nom affiché du compte développeur payant.

## Bilan de la journée du 22/09

Six PRs (#10 → #15), de 8h50 à 12h05 puis reprise : fiche, tap = fiche + « + » et ♡, détails TMDB, journal par période groupé par jour, onglet Envie, réglages. Trois bugs attrapés par la founder à la démo (chips en edge, envie qui restait listée, bandeau), sept décisions produit prises à l'écran et consignées. Le red flag « session > 4 h » a été nommé deux fois ; la founder a choisi de continuer, puis de clore proprement.
