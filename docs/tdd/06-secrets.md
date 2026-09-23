---
type: tdd
statut: accepté
créé: 2026-09-20
---

# 06 — Gestion des secrets

Standard founder (2026-07-10) : **jamais** de secret dans le chat, un `.env`, un fichier versionné, un plist launchd. Source de vérité = **Trousseau macOS**, service `kulturstack`, account = nom en style variable d'env.

## Tranche 1 : un seul secret, à faible valeur (ADR-001)

| Secret | Nature | Où il vit |
|---|---|---|
| `TMDB_READ_TOKEN` | jeton de lecture TMDB v4 (ou clé v3) — gratuit, non facturé, révocable | Trousseau → `Secrets.xcconfig` (gitignoré) → `Info.plist` → binaire |
| OpenLibrary | pas de clé | — |

Le jeton **est extractable du binaire**. C'est accepté et documenté (ADR-001). Rayon d'explosion : quelqu'un fait des recherches TMDB avec notre quota. Réponse : rotation.

## Le pipeline

```
Trousseau macOS
   security add-generic-password -s kulturstack -a TMDB_READ_TOKEN -w     # une fois, saisie interactive
        │
        ▼  make secrets  (scripts/secrets.sh)
Config/Secrets.xcconfig          ← gitignoré, régénéré à chaque fois
   TMDB_READ_TOKEN = eyJ…
        │
        ▼  project.yml : configFiles → Secrets.xcconfig ; Info.plist : TMDBReadToken = $(TMDB_READ_TOKEN)
Binaire
        │
        ▼  Secrets.swift
   Bundle.main.infoDictionary["TMDBReadToken"]
```

### Piège connu : le collage dans l'invite masquée coupe à 128 caractères

Le jeton TMDB fait ~240 caractères. Si on le colle à l'invite `password data for new item:`, macOS ne garde que les 128 premiers → TMDB répond 401. Vérifié le 21/09/2026. La bonne commande lit le presse-papiers directement :

```bash
# 1. copier le jeton sur themoviedb.org/settings/api (bouton copier ou triple-clic)
security add-generic-password -s kulturstack -a TMDB_READ_TOKEN -w "$(pbpaste)"
# 2. vérifier sans l'afficher
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $(security find-generic-password -s kulturstack -a TMDB_READ_TOKEN -w)" https://api.themoviedb.org/3/configuration   # attendu : 200
# 3. écraser le presse-papiers
```

Pour remplacer un jeton existant : `security delete-generic-password -s kulturstack -a TMDB_READ_TOKEN` d'abord.

### `scripts/secrets.sh` — règles

- Lit **la variable d'environnement d'abord** (`$TMDB_READ_TOKEN`), sinon le trousseau. → CI et override sans toucher au trousseau.
- Si rien : échoue avec le message exact
  `TMDB_READ_TOKEN manquant. Ajouter : security add-generic-password -s kulturstack -a TMDB_READ_TOKEN -w`
- `make generate` et `make build` dépendent de `make secrets`.
- `.gitignore` : `Config/Secrets.xcconfig`. Un hook pre-commit refuse tout fichier contenant `TMDB_READ_TOKEN =` avec une valeur.

### `Secrets.swift`

```swift
protocol SecretsProviding: Sendable { func value(for key: SecretKey) throws -> String }
enum SecretKey: String { case tmdbReadToken = "TMDBReadToken" }
struct BundleSecrets: SecretsProviding { … lit Info.plist ; vide ou absent → SecretsError.missing(key, hint) }
```

Injecté par initializer dans `TMDBProvider`. Les tests utilisent `MockSecrets` — **jamais** `BundleSecrets`, sinon ils trouvent la vraie clé de la machine (T-13).

### CI

Les tests n'appellent pas le réseau : la CI passe `TMDB_READ_TOKEN=ci-placeholder` en env. Aucun secret TMDB dans les secrets GitHub en T1.

## Quand ça change

| Tranche | Secret | Décision |
|---|---|---|
| 4 | Discogs (clé optionnelle, non secrète) | même pipeline que TMDB, ou sans clé (25 req/min suffisent au début) |
| 6 | IGDB `client_secret`, Setlist.fm | **proxy Supabase obligatoire** ; les clés vivent dans les secrets de l'edge function ; l'app n'a qu'une URL + un jeton d'app anonyme. TMDB migre derrière le proxy au même moment. |
| 7 | Anthropic | proxy, avec compteur de coût par appareil et quota |

Un secret qui a transité en clair (chat, log, commit) est **à faire tourner** immédiatement.

## Valeurs locales qui ne sont pas des secrets

`DEVELOPMENT_TEAM` (identifiant de l'équipe de signature Apple) passe par le **même mécanisme** que les secrets : Trousseau → `scripts/secrets.sh` → `Config/Secrets.xcconfig` (gitignoré). Ce n'est pas un secret — il apparaît dans tout profil de provisionnement — mais c'est un **identifiant personnel**, et le dépôt est public. Le `.xcodeproj` étant généré, rien n'en sort.

```bash
security add-generic-password -s kulturstack -a DEVELOPMENT_TEAM -w <TEAM_ID>
```

Seules les compilations pour un iPhone réel en ont besoin : ni le simulateur, ni la CI. Sans lui, `make build` et `make test` marchent ; `make device` échoue à la signature.
