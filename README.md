# Kulturstack

Journal de consommation culturelle multi-média, sans friction, local-first, iOS.

> Cherche → 1 tap → loggé. Date par défaut = maintenant, éditable. Films, séries, livres, disques, podcasts, jeux, concerts, théâtre, expos. Et ce que tu possèdes.

## État

- **2026-09-20** — cadrage terminé, 11 ADRs, plan Tranche 1. PR 0 (bootstrap) et PR 1 (schéma V1) fusionnées : le projet compile, 21 tests, CI tests sur GitHub, `main` protégée. Review Claude en CI abandonnée le même jour (ADR-012) au profit d'une review locale. Prochaine étape : PR 2 du plan (journal vide + seed).

## Carte des documents

| Où | Quoi |
|---|---|
| `CLAUDE.md` | Conventions du repo — à lire en premier, à chaque session |
| `docs/etat-du-projet.md` | La photo du projet à date : features livrées, architecture réelle, tests, infra |
| `docs/product/prd.md` | Le produit : problème, principes, périmètre par tranche, exigences |
| `docs/product/design.md` | L'expérience : navigation, écrans, états, design system |
| `docs/product/retours-utilisateurs.md` | Ce que la founder a dit, et ce qu'on en a fait |
| `docs/tdd/` | Cadrage technique : architecture, modèle, protocoles, sources, tests, secrets, RGPD |
| `docs/decisions/` | Une décision = un ADR (format MADR) |
| `docs/plans/tranche-1.md` | Le plan de la Tranche 1 (livrée), en PRs d'une journée |
| `docs/plans/tranche-2.md` | Le plan de la Tranche 2 — Épisodes (proposé, pas commencé) |
| `docs/journal/` | Journal de bord : une page par session, à lire pour reprendre |

## Identité

| | |
|---|---|
| Nom | Kulturstack |
| Bundle id | `com.ukyapps.kulturstack` |
| Repo GitHub | [ukyapps/kulturstack](https://github.com/ukyapps/kulturstack), public |
| Service Trousseau | `kulturstack` |
| iOS minimum | 18.0, iPhone uniquement |
| Langues | français (référence) + anglais |
| Domaines (libres au 2026-09-19, à réserver) | kulturstack.com · .app · .io · .fr |
