#!/bin/bash

# --------------------------
# Script d'import TPL complet (suppression playerid un par un)
# --------------------------

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA1518 -N -s"
CSV_TPL="/mnt/c/github/fifa/player/import/teamplayerlinks.csv"
CSV_V2="/tmp/tpl.csv"
AUTH_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374,1,2,5,7,8,9,10,11,13,14,18,19,106,110,144,1796,1799,1808,1925,1943"
FREE_AGENT=111592

# Conditions pour ignorer les équipes spéciales
EXCLUDE_CONDITION="t.teamname LIKE '%All star%' OR t.teamname LIKE '%Adidas%' OR t.teamname LIKE '%Nike%' OR t.teamname LIKE '% xi%' OR t.teamname LIKE '%allstar%' OR ltl.leagueid = 78"

echo "🚀 Suppression des joueurs des clubs normaux (pas spéciaux ni sélections)..."

# 1️⃣ Import CSV complet dans tmp_tpl pour avoir la liste des playerid
$MYSQL_CMD -e "
DROP TABLE IF EXISTS tmp_tpl;
CREATE TABLE tmp_tpl LIKE teamplayerlinks;

LOAD DATA LOCAL INFILE '$CSV_TPL'
INTO TABLE tmp_tpl
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

# 2️⃣ Supprimer chaque playerid un par un dans teamplayerlinks, en protégeant les équipes spéciales
$MYSQL_CMD -e "SELECT playerid FROM tmp_tpl;" | while read -r playerid; do
    [[ -z "$playerid" ]] && continue
    echo "→ Suppression playerid=$playerid présent dans le csv"
    $MYSQL_CMD -e "
    DELETE tpl
    FROM teamplayerlinks tpl
    JOIN teams t ON tpl.teamid = t.teamid
    LEFT JOIN league_team_links ltl ON tpl.teamid = ltl.teamid
    WHERE tpl.playerid=$playerid
      AND NOT ($EXCLUDE_CONDITION);
    "
done

echo "✅ Joueurs supprimés des présent dans le csv"

# 3️⃣ Mise à jour des AUTH_TEAMS → position = 29 (agent libre)
$MYSQL_CMD -e "
UPDATE teamplayerlinks
SET position = 29,
    teamid = $FREE_AGENT
WHERE teamid IN ($AUTH_TEAMS);
"

echo "✅ Joueurs des AUTH_TEAMS mis à jour."

# 4️⃣ Mise à jour : position = 29 pour les joueurs de tmp_tpl dont teamid n'est pas dans AUTH_TEAMS
$MYSQL_CMD -e "
UPDATE tmp_tpl
SET position = 29
WHERE teamid NOT IN ($AUTH_TEAMS);
"

echo "✅ Positions mises à jour dans tmp_tpl."

# 5️⃣ Export temporaire en CSV pour vérification ou backup
TMP_CSV="/tmp/tmp_tpl_export.csv"
$MYSQL_CMD -e "select * from tmp_tpl" | tr '\t' ';' > $TMP_CSV

# 6️⃣ Chargement final dans teamplayerlinks
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$TMP_CSV'
INTO TABLE teamplayerlinks
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\n';
"

echo "✅ Import final terminé."
