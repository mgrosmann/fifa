#!/bin/bash

DB_NAME="FIFA16"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"
OUTPUT_FILE="players_export.csv"
OUTPUT_NAMES="info_export.csv"

# Liste des ID d'équipes à exclure (sélections nationales + All Star)
EXCLUDED_TEAMS="974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190"



read -p "🔎 Nom du joueur à exporter : " search_name

players=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
SELECT p.playerid,
       CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
       IFNULL(pn_common.name,'') AS commonname,
       IFNULL(t.teamname,'Libre') AS current_team,
       p.overallrating
FROM players p
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN playernames pn_common ON p.commonnameid = pn_common.nameid
LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
LEFT JOIN teams t ON tpl.teamid = t.teamid
WHERE (CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%$search_name%'
   OR pn_common.name LIKE '%$search_name%')
  AND (t.teamid IS NULL OR t.teamid NOT IN ($EXCLUDED_TEAMS));
")

if [[ -z "$players" ]]; then
    echo "❌ Aucun joueur trouvé pour '$search_name'."
    exit 1
fi

num_players=$(echo "$players" | wc -l)

if [[ $num_players -eq 1 ]]; then
    selected_player="$players"
else
    echo "👥 Plusieurs joueurs trouvés :"
    echo "$players" | awk -F'\t' '{printf "%s - ID: %s - %s (%s) - Club: %s - Overall: %s\n", NR, $1, $2, $3, $4, $5}'
    read -p "➡️  Entrez le numéro du joueur à exporter : " player_selection
    selected_player=$(echo "$players" | sed -n "${player_selection}p")
fi

playerid=$(echo "$selected_player" | awk '{print $1}')
fullname=$(echo "$selected_player" | awk -F'\t' '{print $2}')
commonname=$(echo "$selected_player" | awk -F'\t' '{print $3}')

echo "📦 Export de $fullname ($playerid)..."

# Récupération des colonnes
columns=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -Bse "SHOW COLUMNS FROM players;" | awk '{print $1}' | paste -sd";" -)

# Si le fichier n’existe pas, créer l’entête
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "$columns" > "$OUTPUT_FILE"
fi

# Export du joueur
mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME --batch --skip-column-names -e "
    SELECT * FROM players WHERE playerid=$playerid;
" | sed 's/\t/;/g' >> "$OUTPUT_FILE"

# Récupération des firstname, lastname et teamid
names_and_teams=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
SELECT pn_first.name AS firstname,
       pn_last.name AS lastname,
       IFNULL(t.teamid,0) AS teamid,
       p.playerid
FROM players p
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
LEFT JOIN teams t ON tpl.teamid = t.teamid
WHERE p.playerid=$playerid
  AND (t.teamid IS NULL OR t.teamid NOT IN ($EXCLUDED_TEAMS));
")

# Création de l'en-tête si nécessaire
if [[ ! -f "$OUTPUT_NAMES" ]]; then
    echo "firstname;lastname;teamid;playerid" > "$OUTPUT_NAMES"
fi

# Ajout au CSV
echo "$names_and_teams" | sed 's/\t/;/g' >> "$OUTPUT_NAMES"

echo "💾 Noms et équipes exportés dans : $OUTPUT_NAMES"

echo "✅ Joueur exporté : $fullname (ID $playerid)"
echo "💾 Ajouté dans : $OUTPUT_FILE"
