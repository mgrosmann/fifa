#!/bin/bash
DB="FIFA14"
DB_NAME1="FIFA15"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
cmd1=="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB_NAME1"

# --- Étape 1 : extraction des playerid depuis FIFA16
echo "📤 Extraction des playerid depuis $DB..."
$cmd --batch --skip-column-names -e "
SELECT DISTINCT
    p.playerid, pn_first.name AS firstname, pn_last.name AS lastname
FROM players p
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE (
        tpl.teamid IN (21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374)
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
);
" | sed 's/\t/,/g' | tr -d '\r' > fifa16_ids.txt

if [[ ! -s fifa16_ids.txt ]]; then
  echo "❌ Aucun playerid trouvé dans FIFA16."
  exit 1
fi

# --- Étape 2 : création de la liste de playerid pour SQL
ids=$(cut -d',' -f1 fifa16_ids.txt | paste -sd, -)

echo "📥 Vérification des playerid dans $DB_NAME1 avec tolérance prénom/nom..."

# --- Étape 3 : playerid existants dans FIFA14 mais identité différente
$cmd1 --batch --skip-column-names -e "
SELECT f14.playerid, f14_first.name AS firstname_fifa14, f14_last.name AS lastname_fifa14
FROM players f14
JOIN playernames f14_first ON f14.firstnameid = f14_first.nameid
JOIN playernames f14_last ON f14.lastnameid = f14_last.nameid
WHERE f14.playerid IN ($ids)
  AND (f14_first.name NOT LIKE CONCAT('%', f14_first.name, '%')
       OR f14_last.name NOT LIKE CONCAT('%', f14_last.name, '%'));
" | sed 's/\t/,/g' > used_in_fifa14.txt

# --- Étape 4 : calcul des playerid libres
cut -d',' -f1 used_in_fifa14.txt | sort -u > used_ids.txt
cut -d',' -f1 fifa16_ids.txt | sort -u > all_ids.txt

comm -23 all_ids.txt used_ids.txt > free_in_fifa14.txt

# --- Étape 5 : résumé
echo "✅ Vérification terminée :"
echo "   - Joueurs déjà présents mais identité différente : $(wc -l < used_ids.txt)"
echo "   - Joueurs libres : $(wc -l < free_in_fifa14.txt)"
echo ""
echo "📂 Résultats :"
echo "   - used_in_fifa14.txt"
echo "   - free_in_fifa14.txt"
