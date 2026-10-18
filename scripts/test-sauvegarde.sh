#!/usr/bin/env bash
# Teste scripts/sauvegarder-base.sh sans iPhone, en simulant `xcrun`.
# Les trois cas qui comptent sont les cas d'échec : c'est leur silence qui a coûté dix jours
# de logs le 18/10.
set -uo pipefail

RACINE="$(cd "$(dirname "$0")/.." && pwd)"
BAC=$(mktemp -d)
trap 'rm -rf "$BAC"' EXIT
VERTS=0; ROUGES=0

verifier() { # description, attendu, obtenu
  if [ "$2" = "$3" ]; then printf '  ✅ %s\n' "$1"; VERTS=$((VERTS+1))
  else printf '  ❌ %s — attendu « %s », obtenu « %s »\n' "$1" "$2" "$3"; ROUGES=$((ROUGES+1)); fi
}

faire_store() { # chemin, nombre d'œuvres
  sqlite3 "$1" "CREATE TABLE ZMEDIAITEM(Z_PK INTEGER); CREATE TABLE ZLOGENTRY(Z_PK INTEGER, ZEPISODE INTEGER); CREATE TABLE ZEPISODE(Z_PK INTEGER);"
  # `seq 1 0` rend « 1 0 » sur macOS, pas rien : sans ce garde, la base « vide » du test
  # contenait deux lignes et le cas qu'on veut prouver n'était jamais joué.
  local n=0
  while [ "$n" -lt "$2" ]; do
    n=$((n+1))
    sqlite3 "$1" "INSERT INTO ZMEDIAITEM VALUES($n); INSERT INTO ZLOGENTRY VALUES($n, $n); INSERT INTO ZEPISODE VALUES($n);"
  done
}

faire_xcrun() { # dossier, mode (aucun|vide|peuple|illisible)
  mkdir -p "$1"
  cat > "$1/xcrun" <<EOF
#!/usr/bin/env bash
MODE="$2"
if [ "\$1" = "devicectl" ] && [ "\$2" = "list" ]; then
  [ "\$MODE" = "aucun" ] && { echo "iPhone  host  AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE  available (paired)  iPhone"; exit 0; }
  echo "iPhone  host  AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE  connected  iPhone"; exit 0
fi
if [ "\$1" = "devicectl" ] && [ "\$2" = "device" ] && [ "\$3" = "copy" ]; then
  [ "\$MODE" = "illisible" ] && exit 1
  DEST=""; for ((i=1;i<=\$#;i++)); do [ "\${!i}" = "--destination" ] && { j=\$((i+1)); DEST="\${!j}"; }; done
  mkdir -p "\$DEST"
  [ "\$MODE" = "sansbase" ] && exit 0
  cp "$BAC/modele-\$MODE.store" "\$DEST/Kulturstack.store"
  exit 0
fi
exit 0
EOF
  chmod +x "$1/xcrun"
}

faire_store "$BAC/modele-vide.store" 0
faire_store "$BAC/modele-peuple.store" 7

lancer() { # mode → imprime "code|dossiers"
  local mode="$1"
  local bin="$BAC/bin-$mode"
  local dest="$BAC/sauv-$mode"
  faire_xcrun "$bin" "$mode"
  rm -rf "$dest"
  KULTURSTACK_SAUVEGARDES="$dest" PATH="$bin:$PATH" bash "$RACINE/scripts/sauvegarder-base.sh" >/dev/null 2>&1
  echo "$?"
}

echo "Sauvegarde automatique — cas d'échec"

code=$(lancer aucun)
verifier "aucun iPhone branché : se tait et rend 0" "0" "$code"
verifier "aucun iPhone branché : ne crée aucune sauvegarde" "0" "$(ls -1d "$BAC"/sauv-aucun/20* 2>/dev/null | wc -l | tr -d ' ')"

code=$(lancer vide)
verifier "base VIDE : rend 2, pas 0" "2" "$code"
verifier "base VIDE : le dossier est marqué -VIDE" "1" "$(ls -1d "$BAC"/sauv-vide/*-VIDE 2>/dev/null | wc -l | tr -d ' ')"
verifier "base VIDE : aucun lien « derniere » ne pointe dessus" "0" "$([ -e "$BAC/sauv-vide/derniere" ] && echo 1 || echo 0)"

code=$(lancer illisible)
verifier "conteneur illisible : rend 1, pas 0" "1" "$code"

code=$(lancer sansbase)
verifier "aucun fichier .store : rend 1" "1" "$code"
verifier "aucun fichier .store : dossier marqué -SANS-BASE" "1" "$(ls -1d "$BAC"/sauv-sansbase/*-SANS-BASE 2>/dev/null | wc -l | tr -d ' ')"

code=$(lancer peuple)
verifier "base peuplée : rend 0" "0" "$code"
verifier "base peuplée : « derniere » existe" "1" "$([ -e "$BAC/sauv-peuple/derniere" ] && echo 1 || echo 0)"
verifier "base peuplée : le manifeste compte 7 œuvres" "oeuvres: 7" "$(grep '^oeuvres:' "$BAC/sauv-peuple/derniere/manifeste.txt" 2>/dev/null)"
verifier "base peuplée : le manifeste compte 7 cochés" "episodes_coches: 7" "$(grep '^episodes_coches:' "$BAC/sauv-peuple/derniere/manifeste.txt" 2>/dev/null)"

printf '\n%d verts, %d rouges\n' "$VERTS" "$ROUGES"
[ "$ROUGES" -eq 0 ]
