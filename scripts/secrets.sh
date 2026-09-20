#!/usr/bin/env bash
# Génère Config/Secrets.xcconfig (gitignoré) depuis l'environnement, sinon le Trousseau macOS.
# Voir docs/tdd/06-secrets.md. Ne jamais committer le fichier produit.
set -euo pipefail

SERVICE="kulturstack"
OUT="$(cd "$(dirname "$0")/.." && pwd)/Config/Secrets.xcconfig"
SECRETS=(TMDB_READ_TOKEN)

get_secret() {
  local name="$1"
  if [ -n "${!name:-}" ]; then
    printf '%s' "${!name}"
    return 0
  fi
  security find-generic-password -w -s "$SERVICE" -a "$name" 2>/dev/null || return 1
}

{
  echo "// Généré par scripts/secrets.sh — NE PAS COMMITTER, NE PAS ÉDITER"
  for name in "${SECRETS[@]}"; do
    if value="$(get_secret "$name")"; then
      echo "$name = $value"
    else
      echo "$name ="
      echo "⚠️  $name manquant. La recherche TMDB échouera à l'exécution." >&2
      echo "   Ajouter : security add-generic-password -s $SERVICE -a $name -w" >&2
    fi
  done
} > "$OUT"

chmod 600 "$OUT"
echo "Secrets → $OUT"
