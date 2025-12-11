#!/bin/bash
set -euo pipefail

# ---------------------------------------
# ⚡ Import TPL — Version DEBUG (tables persistantes)
# ---------------------------------------

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC16 -N -s"
CSV_TPL="/mnt/c/github/fifa/player/import/teamplayerlinks.csv"
TMP_CSV="/tmp/tmp_tpl_export.csv"

AUTH_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374,1,2,3,4,5,7,9,10,11,12,13,18,19,88,89,106,109,144,1790,1917"
FREE_AGENT=111592

EXCLUDE_CONDITION="t.teamname LIKE '%All star%' OR 
t.teamname LIKE '%Adidas%' OR 
t.teamname LIKE '%Nike%' OR 
t.teamname LIKE '% xi%' OR 
t.teamname LIKE '%allstar%' OR 
ltl.leagueid = 78"

echo "🚀 Import TPL Ultra Optimisé — MODE DEBUG"

# ---------------------------------------
# 1️⃣ Charger CSV dans tmp_tpl (TABLE PERSISTANTE)
# ---------------------------------------
$MYSQL_CMD -e "
DROP TABLE IF EXISTS tmp_tpl;
CREATE TABLE tmp_tpl LIKE teamplayerlinks;
"

echo "📥 tmp_tpl créée (PERSISTANTE)"

$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_TPL'
INTO TABLE tmp_tpl
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

echo "📥 tmp_tpl chargée depuis CSV"

# ---------------------------------------
# 2️⃣ Index persistants
# ---------------------------------------
create_index() {
    local table="$1" index="$2" columns="$3"
    exists=$($MYSQL_CMD -e "
        SELECT 1 FROM information_schema.STATISTICS
        WHERE table_schema='DFC16'
        AND table_name='$table'
        AND index_name='$index'
        LIMIT 1;
    ")
    [[ -z "$exists" ]] && {
        echo "→ Création index $index sur $table($columns)"
        $MYSQL_CMD -e "ALTER TABLE $table ADD INDEX $index ($columns);"
    }
}

create_index "tmp_tpl" "idx_playerid" "playerid"
create_index "teamplayerlinks" "idx_playerid2" "playerid"
create_index "teamplayerlinks" "idx_teamid2" "teamid"

echo "⚡ Index vérifiés (persistants)"

# ---------------------------------------
# 3️⃣ Table persistante pour les deletes
# ---------------------------------------
echo "🔍 Sélection des joueurs à purger…"

$MYSQL_CMD -e "
DROP TABLE IF EXISTS tmp_pid_to_delete;
CREATE TABLE tmp_pid_to_delete (playerid INT PRIMARY KEY);
"

$MYSQL_CMD -e "
INSERT INTO tmp_pid_to_delete (playerid)
SELECT DISTINCT tpl.playerid
FROM teamplayerlinks tpl
JOIN tmp_tpl csv USING (playerid)
JOIN teams t ON tpl.teamid = t.teamid
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE NOT ($EXCLUDE_CONDITION);
"

count=$($MYSQL_CMD -e "SELECT COUNT(*) FROM tmp_pid_to_delete;")
echo "➡️  $count joueurs à supprimer"

# ---------------------------------------
# 4️⃣ Suppression rapide
# ---------------------------------------
echo "🗑️ Suppression…"

$MYSQL_CMD -e "
DELETE FROM teamplayerlinks
WHERE playerid IN (SELECT playerid FROM tmp_pid_to_delete);
"

echo "✔ Suppression terminée"

# ---------------------------------------
# 5️⃣ Déplacement AUTH_TEAMS → agent libre
# ---------------------------------------
$MYSQL_CMD -e "
UPDATE teamplayerlinks
SET position = 29,
    teamid = $FREE_AGENT
WHERE teamid IN ($AUTH_TEAMS);
"

echo "🔄 AUTH_TEAMS → agent libre"

# ---------------------------------------
# 6️⃣ Update positions dans tmp_tpl
# ---------------------------------------
$MYSQL_CMD -e "
UPDATE tmp_tpl
SET position = 29
WHERE teamid NOT IN ($AUTH_TEAMS);
"

echo "🔧 Positions mises à jour"

# ---------------------------------------
# 7️⃣ Export CSV final depuis tmp_tpl
# ---------------------------------------
$MYSQL_CMD -e "SELECT * FROM tmp_tpl" | tr '\t' ';' > "$TMP_CSV"

echo "📤 Exporté : $TMP_CSV"

# ---------------------------------------
# 8️⃣ Import dans teamplayerlinks
# ---------------------------------------
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$TMP_CSV'
INTO TABLE teamplayerlinks
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n';
"

echo "🎉 Import TPL Ultra Optimisé — MODE DEBUG — Terminé"

