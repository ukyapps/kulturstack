#!/usr/bin/env bash
# Sauvegarde la base SwiftData de Kulturstack depuis l'iPhone branché.
#
# Pensé pour tourner tout seul (launchd, toutes les 30 minutes) : si aucun iPhone n'est
# connecté, le script se tait et rend 0. Il ne modifie jamais l'appareil.
#
# Né du 18/10 : l'app avait disparu de l'iPhone avec sa base, et la dernière sauvegarde
# datait de trois semaines. Dix jours de logs perdus.
set -euo pipefail

BUNDLE="com.ukyapps.kulturstack"
# Pas dans ~/Documents : macOS (TCC) interdit à un agent launchd d'y lire et d'y écrire,
# et la sauvegarde automatique échouait en « Operation not permitted ». Application Support
# n'est pas protégé, donc le même dossier sert à la main et en automatique.
DEST_ROOT="${KULTURSTACK_SAUVEGARDES:-$HOME/Library/Application Support/Kulturstack/sauvegardes}"
GARDER=30
JOURNAL="$DEST_ROOT/journal.log"

dire() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" | tee -a "$JOURNAL" >&2; }

mkdir -p "$DEST_ROOT"

APPAREIL=$(xcrun devicectl list devices 2>/dev/null \
  | grep -E '[[:space:]]connected' \
  | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | head -1 || true)
if [ -z "$APPAREIL" ]; then
  exit 0   # aucun iPhone branché : ce n'est pas une erreur, c'est le cas courant.
fi

HORODATAGE=$(date '+%Y-%m-%d-%H%M')
CIBLE="$DEST_ROOT/$HORODATAGE"
mkdir -p "$CIBLE"

if ! xcrun devicectl device copy from --device "$APPAREIL" \
      --domain-type appDataContainer --domain-identifier "$BUNDLE" \
      --source "Library/Application Support" --destination "$CIBLE" >/dev/null 2>&1; then
  rmdir "$CIBLE" 2>/dev/null || true
  dire "ÉCHEC : impossible de lire le conteneur. L'app est-elle installée et lancée au moins une fois ?"
  exit 1
fi

STORE="$CIBLE/Kulturstack.store"
if [ ! -f "$STORE" ]; then
  mv "$CIBLE" "$CIBLE-SANS-BASE"
  dire "ÉCHEC : aucun fichier Kulturstack.store. Lancer l'app une fois, puis réessayer."
  exit 1
fi

compter() { sqlite3 "$STORE" "SELECT COUNT(*) FROM $1;" 2>/dev/null || echo 0; }
OEUVRES=$(compter ZMEDIAITEM)
LOGS=$(compter ZLOGENTRY)
EPISODES=$(compter ZEPISODE)
COCHES=$(sqlite3 "$STORE" "SELECT COUNT(*) FROM ZLOGENTRY WHERE ZEPISODE IS NOT NULL;" 2>/dev/null || echo 0)

{
  echo "date: $HORODATAGE"
  echo "oeuvres: $OEUVRES"
  echo "logs: $LOGS"
  echo "episodes: $EPISODES"
  echo "episodes_coches: $COCHES"
} > "$CIBLE/manifeste.txt"

# Une base vide se garde — elle documente l'incident — mais elle n'est jamais « la dernière
# bonne sauvegarde », et elle ne doit pas passer inaperçue. C'est exactement ce qui est
# arrivé le 18/10 : un store de 139 Ko, bien formé, et zéro ligne dedans.
if [ "$OEUVRES" -eq 0 ] && [ "$LOGS" -eq 0 ]; then
  mv "$CIBLE" "$CIBLE-VIDE"
  dire "ALERTE : la base de l'iPhone est VIDE (0 œuvre, 0 log). Sauvegarde marquée -VIDE, le lien derniere n'a pas bougé."
  exit 2
fi

ln -sfn "$HORODATAGE" "$DEST_ROOT/derniere"
dire "OK $OEUVRES œuvres · $LOGS logs · $EPISODES épisodes ($COCHES cochés) → $HORODATAGE"

# On ne garde que les N dernières sauvegardes valides ; les -VIDE et -SANS-BASE restent,
# elles sont rares et elles racontent un incident.
cd "$DEST_ROOT"
ls -1d 20*-[0-9][0-9][0-9][0-9] 2>/dev/null | sort -r | tail -n +$((GARDER + 1)) | while read -r vieille; do
  rm -rf "$vieille"
done
