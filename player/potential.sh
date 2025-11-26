#!/bin/bash

# --- Configuration ---
DB="FC26"
cmd="mysql -uroot -proot -D $DB"
MIN_POTENTIAL=90  # Seuil minimal du potentiel
MIN_OVERALL=80    #seuil minimal du overall
echo "🔎 Recherche de tous les joueurs avec un potentiel ≥ $MIN_POTENTIAL..."

$cmd  -e "
SELECT
    CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
    p.overallrating AS overall,
    p.potential,
    t.teamname,
    p.preferredposition1
FROM players p
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
LEFT JOIN teams t ON tpl.teamid = t.teamid
WHERE p.potential >= $MIN_POTENTIAL
AND p.overallrating <= $MIN_OVERALL AND t.teamid NOT IN (
974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048
      )
ORDER BY p.potential DESC, p.overallrating DESC;
"

echo "🏁 Terminé — affichage des joueurs avec potentiel ≥ $MIN_POTENTIAL."
