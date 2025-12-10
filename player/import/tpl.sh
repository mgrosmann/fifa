#!/bin/bash

# ---------------------------------------------------------
# Script d'import TPL complet — Version optimisée sans boucle
# ---------------------------------------------------------

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA1518 -N -s"
CSV_TPL="/mnt/c/github/fifa/player/import/teamplayerlinks.csv"
AUTH_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374,1,2,3,4,5,7,9,10,11,12,13,18,19,88,89,106,109,144,1799,1917"
FREE_AGENT=111592

# Conditions pour ignorer les équipes spéciales
EXCLUDE_CONDITION="t.teamname LIKE '%All star%' OR \
t.teamname LIKE '%Adidas%' OR t.teamname LIKE '%Nike%' OR \
t.teamname LIKE '% xi%' OR t.teamname LIKE '%allstar%' OR \
ltl.leagueid = 78"

echo "🚀 Import TPL optimisé — suppression massive instantanée"

# 1️⃣ Import CSV complet dans tmp_tpl
$MYSQL_CMD -e "
DROP TABLE IF EXISTS tmp_tpl;
CREATE TABLE tmp_tpl LIKE teamplayerlinks;

LOAD DATA LOCAL INFILE '$CSV_TPL'
INTO TABLE tmp_tpl
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

echo "📥 tmp_tpl chargé depuis le CSV"

# 2️⃣ Ajout d'index temporaires pour accélérer les DELETE & JOIN
$MYSQL_CMD -e "
ALTER TABLE tmp_tpl ADD INDEX idx_playerid (playerid);
ALTER TABLE teamplayerlinks ADD INDEX idx_playerid2 (playerid);
ALTER TABLE teamplayerlinks ADD INDEX idx_teamid2 (teamid);
"

echo "⚡ Index temporaires créés"

# 3️⃣ Suppression MASSIVE en une seule requête (plus de boucle lente)
$MYSQL_CMD -e "
DELETE tpl
FROM teamplayerlinks tpl
JOIN tmp_tpl csv ON csv.playerid = tpl.playerid
JOIN teams t ON tpl.teamid = t.teamid
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE NOT ($EXCLUDE_CONDITION);
"

echo "🗑️ Joueurs présents dans le CSV supprimés des clubs normaux"

# 4️⃣ Mise à jour des AUTH_TEAMS → agent libre (free agent)
$MYSQL_CMD -e "
UPDATE teamplayerlinks
SET position = 29,
    teamid = $FREE_AGENT
WHERE teamid IN ($AUTH_TEAMS);
"

echo "🔄 Joueurs AUTH_TEAMS déplacés vers agent libre"

# 5️⃣ Mise à jour des positions dans tmp_tpl
$MYSQL_CMD -e "
UPDATE tmp_tpl
SET position = 29
WHERE teamid NOT IN ($AUTH_TEAMS);
"

echo "🔧 Positions mises à jour dans tmp_tpl"

# 6️⃣ Export tmp_tpl en CSV pour réimport final
TMP_CSV="/tmp/tmp_tpl_export.csv"
$MYSQL_CMD -e "SELECT * FROM tmp_tpl" | tr '\t' ';' > "$TMP_CSV"

echo "📤 Export tmp_tpl vers $TMP_CSV"

# 7️⃣ Chargement final dans teamplayerlinks
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$TMP_CSV'
INTO TABLE teamplayerlinks
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n';
"

echo "✅ Import final terminé avec succès — version optimisée"
