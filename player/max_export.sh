#!/bin/bash
# --- max_export.sh ---
# Export ciblé : top clubs + PL + joueurs 85+ ou potentiel élevé + joueurs forcés

DB_NAME="FIFA16"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"
OUTPUT_FILE="players_export.csv"
OUTPUT_NAMES="players_names_teams.csv"

echo "🔍 Export des joueurs filtrés (clubs majeurs, PL, 85+, écart >=15, exceptions manuelles)..."

# --- Étape 1 : Récupération des colonnes pour l'en-tête ---
columns=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D "$DB_NAME" -Bse "SHOW COLUMNS FROM players;" | paste -sd";" -)
echo "$columns" > "$OUTPUT_FILE"

# --- Étape 2 : Export complet filtré ---
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D "$DB_NAME" --batch --skip-column-names -e "
SELECT DISTINCT p.*
FROM players p
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
JOIN teamplayerlinks tpl ON tpl.playerid = p.playerid
JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE (
        tpl.teamid IN (21, 22, 32, 34, 44, 45, 46, 47, 48, 52, 65, 66, 73, 240, 241, 243, 461, 483, 110374)
     OR ltl.leagueid = 13
     OR p.overallrating >= 85
     OR p.potential >= 85
     OR (p.potential - p.overallrating) >= 15
     OR pn_last.name IN ('barthez') -- ✅ ajout manuel
)
AND tpl.teamid NOT IN (
974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190,111205
)
ORDER BY p.overallrating DESC;
" | sed 's/\t/;/g' >> "$OUTPUT_FILE"

echo "📥 Export filtré enregistré dans : $OUTPUT_FILE"

# --- Étape 3 : Export CSV léger firstname;lastname;teamid;playerid ---
echo "firstname;lastname;teamid;playerid" > "$OUTPUT_NAMES"

mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D "$DB_NAME" --batch --skip-column-names -e "
SELECT DISTINCT
    pn_first.name AS firstname,
    pn_last.name AS lastname,
    tpl.teamid,
    p.playerid
FROM players p
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE (
        tpl.teamid IN (21, 22, 32, 34, 44, 45, 46, 47, 48, 52, 65, 66, 73, 240, 241, 243, 461, 483, 110374)
     OR ltl.leagueid = 13
     OR p.overallrating >= 85
     OR p.potential >= 85
     OR (p.potential - p.overallrating) >= 15
     OR pn_last.name IN ('barthez')
)
AND tpl.teamid NOT IN (
974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190,111205
)
ORDER BY p.overallrating DESC;
" | sed 's/\t/;/g' >> "$OUTPUT_NAMES"

echo "💾 CSV léger exporté dans : $OUTPUT_NAMES"
echo "✅ Export filtré terminé."
