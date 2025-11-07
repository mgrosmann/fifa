#!/bin/bash
# --- max_export.sh ---
# Export de tous les joueurs des 7 grands championnats

DB_NAME="FIFA16"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"
OUTPUT_FILE="players_export.csv"
OUTPUT_NAMES="players_names_teams.csv"

# Les 7 grands championnats
LEAGUE_IDS="13,16,19,31,10,53,308"

echo "🔍 Export des joueurs des 7 grands championnats..."

# --- Étape 1 : Export complet des joueurs ---
# Récupération des colonnes
columns=$(mysql -u$USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -Bse "SHOW COLUMNS FROM players;" | paste -sd";" -)

# Création du fichier CSV si n'existe pas
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "$columns" > "$OUTPUT_FILE"
fi

# Export en batch avec JOIN pour filtrer les équipes des championnats
mysql -u$USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME --batch --skip-column-names -e "
SELECT DISTINCT p.*
FROM players p
JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.leagueid IN ($LEAGUE_IDS);
" | sed 's/\t/;/g' >> "$OUTPUT_FILE"

echo "📥 Export complet des joueurs enregistré dans : $OUTPUT_FILE"

# --- Étape 2 : Export firstname;lastname;teamid;playerid ---
# Création du CSV léger
if [[ ! -f "$OUTPUT_NAMES" ]]; then
    echo "firstname;lastname;teamid;playerid" > "$OUTPUT_NAMES"
fi

mysql -u$USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME --batch --skip-column-names -e "
SELECT DISTINCT
       pn_first.name AS firstname,
       pn_last.name AS lastname,
       t.teamid,
       p.playerid
FROM players p
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.leagueid IN ($LEAGUE_IDS);
" | sed 's/\t/;/g' >> "$OUTPUT_NAMES"

echo "💾 CSV léger (firstname;lastname;teamid;playerid) exporté dans : $OUTPUT_NAMES"

echo "✅ Export terminé pour tous les joueurs des 7 grands championnats."