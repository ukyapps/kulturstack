# ADR-012 — Review par Claude en local, pas en CI

- Statut : **accepted**
- Date : 2026-09-20
- Remplace : la « 3e étape » du cadrage (workflow `claude-review.yml` + secret + check `review` obligatoire)

## Contexte

Le cadrage imposait une review automatique de chaque PR par Claude dans GitHub Actions (fiche /5, gate fail-closed). Mise en place en PR 0, elle n'a jamais produit une seule fiche :

- l'action exige que son workflow soit identique sur `main` → PR 0 fusionnée par bypass admin, et **toute modification future du workflow aurait exigé le même bypass** ;
- l'app GitHub « Claude » à installer, un jeton OAuth à créer et poser dans les secrets (un premier jeton a fuité dans le chat et a dû être révoqué) ;
- même avec un jeton neuf, Claude échouait en 1,8 s sans consommer de token, et **l'action masque le message d'erreur** ; le voir aurait demandé une nouvelle modification du workflow, donc un nouveau bypass.

Deux heures de session founder consommées par la plomberie, zéro valeur livrée. Décision founder : « c'est un bourbier pour le projet ».

## Décision

1. **Retirer** `claude-review.yml`, le secret `CLAUDE_CODE_OAUTH_TOKEN` (supprimé), et le check `review` du ruleset `main`.
2. **Garder** `tests.yml` : aucun secret, vert, ~5 min, et c'est le vrai filet puisque la founder ne relit pas le Swift. Le ruleset `main` exige le check `test`.
3. **La review se fait en local**, par Claude, avant chaque push, avec la même grille (CLAUDE.md § Review locale). La fiche est collée dans la description de la PR. Un FAIL ne se pousse pas.
4. La founder fusionne dans le navigateur, sans bypass.

## Conséquences

- On perd l'indépendance d'un second regard « à froid » sur le diff. On la compense par la grille explicite, le diff relu en entier (`git diff main...HEAD`), et les tests en CI.
- On gagne : zéro secret sur GitHub, zéro bypass, zéro workflow à maintenir, et des PRs qui se fusionnent en un clic.
- Réévaluer si le projet accueille un jour une deuxième personne, ou si l'action devient utilisable sans bypass (workflow figé + `show_full_output`).
- L'app GitHub « Claude » installée sur le repo peut être désinstallée par la founder (github.com/settings/installations) — sans effet sur le reste.
