#!/bin/bash
set -euo pipefail

# -----------------------------
# Script d'import TPL optimisé
# -----------------------------

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA1518 -N -s"
CSV_TPL="/mnt/c/github/fifa/player/import/teamplayerlinks.csv"
TMP_CSV="/tmp/tmp_tpl_export.csv"
AUTH_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374,1,2,3,4,5,7,9,10,11,12,13,18,19,88,89,106,109,144,1799,1917"
FREE_AGENT=111592

EXCLUDE_CONDITION="t.teamname LIKE '%All star%' OR \
t.teamname LIKE '%Adidas%' OR t.teamname LIKE '%Nike%' OR \
t.teamname LIKE '% xi%' OR t.teamname LIKE '%allstar%' OR \
ltl.leagueid = 78"

echo "🚀 Import TPL optimisé — suppression massive instantanée"

# -----------------------------
# 1️⃣ Import CSV dans tmp_tpl
# -----------------------------
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

# -----------------------------
# 2️⃣ Fonction pour créer un index s’il n’existe pas
# -----------------------------
create_index_if_missing() {
    local table="$1"
    local index="$2"
    local columns="$3"
    exists=$($MYSQL_CMD -e "
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE table_schema='FIFA1518' AND table_name='$table' AND index_name='$index'
        LIMIT 1;")
    if [[ -z "$exists" ]]; then
        echo "→ Création index $index sur $table($columns)"
        $MYSQL_CMD -e "ALTER TABLE $table ADD INDEX $index ($columns);"
    else
        echo "→ Index $index déjà existant sur $table"
    fi
}

# -----------------------------
# 3️⃣ Création des index temporaires si absents
# -----------------------------
create_index_if_missing "tmp_tpl" "idx_playerid" "playerid"
create_index_if_missing "teamplayerlinks" "idx_playerid2" "playerid"
create_index_if_missing "teamplayerlinks" "idx_teamid2" "teamid"

echo "⚡ Vérification/Création des index terminée"

# -----------------------------
# 4️⃣ Suppression massive des joueurs existants
# -----------------------------
$MYSQL_CMD -e "
DELETE tpl
FROM teamplayerlinks tpl
JOIN tmp_tpl csv ON csv.playerid = tpl.playerid
JOIN teams t ON tpl.teamid = t.teamid
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE NOT ($EXCLUDE_CONDITION);
"

echo "🗑️ Joueurs présents dans le CSV supprimés des clubs normaux"

# -----------------------------
# 5️⃣ Mise à jour des AUTH_TEAMS → agent libre
# -----------------------------
$MYSQL_CMD -e "
UPDATE teamplayerlinks
SET position = 29,
    teamid = $FREE_AGENT
WHERE teamid IN ($AUTH_TEAMS);
"

echo "🔄 Joueurs AUTH_TEAMS déplacés vers agent libre"

# -----------------------------
# 6️⃣ Mise à jour des positions dans tmp_tpl
# -----------------------------
$MYSQL_CMD -e "
UPDATE tmp_tpl
SET position = 29
WHERE teamid NOT IN ($AUTH_TEAMS);
"

echo "🔧 Positions mises à jour dans tmp_tpl"

# -----------------------------
# 7️⃣ Export tmp_tpl en CSV pour réimport final
# -----------------------------
$MYSQL_CMD -e "SELECT * FROM tmp_tpl" | tr '\t' ';' > "$TMP_CSV"
echo "📤 Export tmp_tpl vers $TMP_CSV"

# -----------------------------
# 8️⃣ Chargement final dans teamplayerlinks
# -----------------------------
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$TMP_CSV'
INTO TABLE teamplayerlinks
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n';
"

echo "✅ Import final terminé avec succès — version optimisée avec vérification des index"
