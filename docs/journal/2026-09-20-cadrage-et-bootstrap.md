---
type: journal
dates: 2026-09-19 → 2026-09-20
statut: PR 0 et PR 1 fusionnées ; review CI abandonnée (ADR-012) ; PR docs/chore ouverte
---

# Session 1 — Naming, cadrage, bootstrap, schéma V1

## Les personnes

- **Founder** : compte GitHub `ukyapps`. Pas développeuse iOS — ne relit pas le Swift, s'appuie sur les tests + la review CI. Travaille en français. Retour de burn-out, recherche d'emploi en parallèle, deuxième produit iOS en cours (Mealkin, **auquel elle n'a pas accès depuis cette machine** — ne pas chercher à le cloner).
- **Façon de travailler qui marche** : une question à la fois, en langage simple, avec une reco argumentée et un tableau court. Expliquer les mots (PR, clé, proxy, jeton) la première fois. Guider les manipulations Terminal étape par étape.
- **Ce qui ne marche pas** : 8 questions techniques d'un coup → « là j'y comprends plus rien ».

## Le produit

Journal de consommation culturelle multi-média **sans friction**, local-first, iOS. Cherche → 1 tap → loggé, daté maintenant, éditable. Référence UX : TV Time (bon) contre Trakt (frictionnel). Remplace Trakt / Goodreads / notes manuelles / Discogs.

**9 types de contenu** : films, séries, livres, **disques**, **podcasts** (ajoutés le 20/09), jeux, concerts, théâtre, expos.

**+ « Ma bibliothèque »** (ajouté le 20/09) : ce qu'on *possède* (vinyle, CD, cassette, DVD, poche…). Une deuxième relation à l'œuvre, indépendante du log — **pas un statut**, parce qu'elle se combine avec tous les statuts. À l'ajout : deux cases « je l'ai vu / lu / écouté » (cochée par défaut) et « je le possède » (un tap de plus). Au scan de code-barres, c'est « je le possède » qui sera coché par défaut.

**Écrans voulus par la founder** : « où j'en suis » (en cours), « ce que j'ai consommé cette semaine / ce mois / cette année », « par type de contenu ». Tous filtrent sur des champs communs (statut, date, type) → confirme le modèle générique.

## Le nom : Kulturstack

Parcours : listes « fun », « littéral », « profil culturel » → toutes rejetées (« à côté de la plaque »). Le déclic : la founder aime Letterboxd, Arte, Deezer, TV Time, Discogs, Goodreads → des noms qui parlent de **l'objet** (le média), pas de l'utilisateur ni de l'acte. Puis Backlog + Culture Time + Culture Stack.

- **Backlog** : abandonné — ≥ 4 apps concurrentes (backlog.site, usebacklog.app, BacklogBox, Backloggd), backlog.com = Nulab.
- **Culture Time** : jouable (seule une radio reggae « Tony Culture Time » porte le nom), `.io` libre, `.com` en vente chez Afternic.
- **Culture Stack** : jouable mais `.com` = site B2B actif.
- **Kulturstack** : retenu. `.com` `.app` `.io` `.fr` libres au 19/09, zéro app sur l'App Store, zéro occurrence web. **Domaines pas encore réservés.**
- **Kulturklub** : hésitation finale, écarté (mot allemand générique, dizaines d'assos, `.com` / `.de` pris, promet une communauté alors que le produit est un journal perso). Gardé comme nom possible de la feature sociale (« le Klub »).

Bundle id `com.ukyapps.kulturstack` (le `studio.ancolie` du cadrage venait de Mealkin). Service Trousseau `kulturstack`.

## Sources de données — vérifiées les 19-20/09

Détail dans `docs/tdd/04-sources-de-donnees.md`. Ce qui a changé par rapport au cadrage de juillet :

- **Trakt API payante** depuis août 2026 (VIP 4,99 $/mois côté développeur, apps existantes supprimées) → import par le **ZIP JSON d'export** (gratuit, Settings → Data), pas OAuth. ADR-009.
- **Setlist.fm** fonctionne (la founder n'y accédait pas : protection anti-bot Cloudflare — essayer en 4G). Clé initiale « pour tests », upgrade à demander avant T6.
- **Théâtre** : la liste Eurêkoi (SACD, Avant-Scène, Mascarille…) = bases de *textes*, pas de *représentations*. Ce qui compte : Les Archives du spectacle (179 000 spectacles, pas d'API connue, à contacter — **la founder ne veut pas de mail pour l'instant**), OpenAgenda (API gratuite, clé non secrète), theatre-contemporain.net (API ouverte mais fusionné avec ARTCENA en 2026, devenir inconnu). L'Officiel des spectacles / BilletReduc : aucune API, hors périmètre.
- **Expos** : OpenAgenda, Que faire à Paris, Muséofile (liste des Musées de France pour l'autocomplétion du lieu). Paris Musées API = œuvres, pas expos.
- **Disques** : Discogs (API sans clé, 25 req/min ; export CSV ou API de la collection). **Podcasts** : Apple Podcasts (iTunes Search, sans clé) + RSS pour les épisodes ; pas d'import d'historique possible.

## Les 8 questions du cadrage → 11 ADRs

| # | Décision | ADR |
|---|---|---|
| ① | Clé TMDB embarquée (xcconfig gitignoré généré depuis le Trousseau), risque accepté ; proxy Supabase en T6 | 001 |
| ② | Un seul `MediaItem` + poche `detailsData` Codable par type ; Season / Episode = vrais modèles (T2) | 002 |
| ③ | `VersionedSchema` + `SchemaMigrationPlan` dès la PR 1 + test T-01 | 003 |
| ④ | `ExternalRef` à clé unique `provider:value`, dédup par intersection, fiche au niveau de l'œuvre (work / master), file « à confirmer » | 004 |
| ⑤ | Une barre, providers en parallèle, sections par type à états indépendants, filtres après la saisie | 005 |
| ⑥ | Demi-étoiles / 5 stockées 1…10 ; statuts déclarés par type ; bibliothèque à part | 006 |
| ⑦ | iOS 18.0, iPhone only, FR + EN dès la PR 1 | 007 |
| ⑧ | Kulturstack | 008 |
| — | Trakt par export JSON | 009 |
| — | `OwnedCopy` (T5) | 010 |
| — | Ordre des tranches : 1 log · 2 épisodes · 3 import · 4 disques + podcasts · 5 collection · 6 jeux + concerts (proxy) · 7 théâtre / expos + IA · 8 social | 011 |

Estimation honnête donnée à la founder : **T1 = 4-6 semaines part-time**, pas 2-4.

## Ce qui a été fait

### Cadrage (20/09 matin)
`README.md`, `CLAUDE.md`, `docs/tdd/01…07`, `docs/decisions/001…011`, `docs/plans/tranche-1.md` (12 PRs d'une journée).

### PR 0 — bootstrap (#1, fusionnée)
- Outils : Xcode 26.3, Swift 6.2, XcodeGen 2.46 (installé via brew), simulateur iPhone 17 Pro (iOS 26.2). Identité git = `ukyapps` + email noreply GitHub.
- `project.yml`, `Makefile` (`generate` / `build` / `test` / `coverage` / `hooks`), `scripts/secrets.sh`, hook pre-commit anti-secret, `RootView` + `EmptyState` + tokens, `Localizable.xcstrings` FR / EN, `PrivacyInfo.xcprivacy`, 2 tests Swift Testing.
- CI : `tests.yml` (macos-26, Xcode_26.3, ~5 min, **vert**) et `claude-review.yml` (claude-code-action@v1, fail-closed, cap 12 000 lignes, commentaire sticky, gate bash).
- Repo public `ukyapps/kulturstack`, `main` par défaut, ruleset `protect-main` : PR obligatoire, checks `review` + `test` requis, **aucun bypass**.
- Secret `CLAUDE_CODE_OAUTH_TOKEN` posé ; app GitHub « Claude » installée sur le repo.

### PR 1 — schéma V1 (#2, ouverte)
- `MediaKind`, `LogStatus`, `LogRules`, `DomainError`, `MediaItem`, `ExternalRef`, `LogEntry.make`, poches `Film / Series / Book / GenericDetails`, `DetailsCodec`, `KulturstackSchemaV1`, `KulturstackMigrationPlan`, `ModelContainerFactory`, badge DEBUG « Base V1 · 0 fiches · 0 logs » vérifié à l'écran.
- 21 tests verts (T-01, T-02, T-03, T-06, T-15 + unicité `ExternalRef`, statuts par type, round-trip des poches…), Domain 81-100 %.
- Check `test` **vert**. Check `review` **rouge** — voir « État ».

## Les pièges rencontrés (à ne pas retomber dedans)

1. **`! commande`** ne fonctionne pas dans l'interface de la founder → lui faire ouvrir l'app Terminal.
2. **`gh auth login`** : le Terminal restait en attente sur « Press Enter » ; puis GitHub demandait de se connecter avant d'afficher la page du code → aller sur github.com/login/device.
3. **Le premier jeton Claude a été collé dans le chat** → révoqué par la founder, un second créé. Règle rappelée : le jeton ne va **que** à l'invite `gh secret set`, jamais dans le chat.
4. **L'action Claude exige que `claude-review.yml` soit identique à celui de `main`** → toute PR qui modifie ce fichier ne peut pas passer la review. PR 0 fusionnée par **bypass admin temporaire** (documenté sur la PR, bypass retiré aussitôt). **Toute future modification du workflow devra suivre le même chemin** (bypass ponctuel, tracé, retiré).
5. **`gh pr merge --admin` est bloqué** par le classifier de Claude Code → la founder fusionne dans le navigateur (et c'est mieux ainsi : c'est elle qui contourne sa règle).
6. **L'app GitHub « Claude » doit être installée** sur le repo (github.com/apps/claude), sinon 401 « not installed ».
7. **Fausse piste** : j'ai cru que `--model claude-opus-5` était refusé en CI ; testé en local, `claude-opus-5` et `opus` marchent tous les deux → changement annulé (revert), workflow de nouveau identique à `main`.
8. Git ne versionne pas un dossier vide → `secrets.sh` fait `mkdir -p Config`.

## Fin de session (20/09, après-midi)

- Jeton neuf → **même échec** (1,8 s, 0 token). L'action masque le message d'erreur ; le voir aurait exigé une modification du workflow, donc un nouveau bypass. Décision founder : **« abandonner le process de CI/CD sur GitHub, je n'ai pas les secrets et c'est un bourbier »** → ADR-012 : workflow de review supprimé, secret supprimé, check `review` retiré du ruleset, **tests CI conservés** (aucun secret, verts), review faite par Claude en local avant chaque push avec la grille de CLAUDE.md.
- PR #2 fusionnable sans bypass (seul `test` est requis) — fusionnée par la founder dans le navigateur.
- Écrit : `docs/product/prd.md`, `docs/product/design.md`, `docs/product/retours-utilisateurs.md`, `docs/etat-du-projet.md`, ADR-012, ce journal. Liens ajoutés dans README et CLAUDE.md. Le tout dans la PR `chore/retirer-review-ci`.

## À faire — founder

- [ ] (optionnel) Désinstaller l'app GitHub « Claude » : github.com/settings/installations
- [ ] Réserver `kulturstack.com` + `kulturstack.app`
- [ ] Clé TMDB → Trousseau : `security add-generic-password -s kulturstack -a TMDB_READ_TOKEN -w` (nécessaire avant la PR 3)
- [ ] Recherche INPI (5 min) avant publication sur le store

## À faire — prochaine session Claude

1. Lire `docs/etat-du-projet.md`.
2. PR 2 du plan : Journal vide + seed DEBUG (`docs/plans/tranche-1.md`). Review locale avant le push.
