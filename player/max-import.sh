#!/bin/bash
# --- import_massive_simple.sh (version finale avec update systématique) ---
# Import massif + update systématique + gestion des agents libres
# Compatible export.sh (mêmes filtres clubs / ligues)
# UTF-8, logs détaillés, LEFT JOIN sur PL

DB="FIFA14"
MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="5000"
cmd="mysql --local-infile=1 -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT -D $DB -A -N -e"

PLAYERS_CSV="players.csv"
NAMES_TEAMS_CSV="players_names_teams.csv"
TEAMPLAYERLINKS_CSV="teamplayerlinks.csv"

LOG_FILE="import_massive_simple.log"
echo "===== Import démarré $(date) =====" > "$LOG_FILE"

# --- Vérification des fichiers ---
for f in "$PLAYERS_CSV" "$NAMES_TEAMS_CSV" "$TEAMPLAYERLINKS_CSV"; do
    if [[ ! -f "$f" ]]; then
        echo "❌ Fichier manquant : $f" | tee -a "$LOG_FILE"
        exit 1
    fi
done

# --- Import massif players ---
echo "📥 Import / update players..." | tee -a "$LOG_FILE"
$cmd "
SET NAMES utf8mb4;
LOAD DATA LOCAL INFILE '$PLAYERS_CSV'
REPLACE INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"
echo "✅ Players importés / mis à jour." | tee -a "$LOG_FILE"

# --- Import temporaire CSV léger ---
echo "🔁 Import temporaire CSV léger..." | tee -a "$LOG_FILE"
$cmd "
SET NAMES utf8mb4;
DROP TEMPORARY TABLE IF EXISTS tmp_names;
CREATE TEMPORARY TABLE tmp_names (
    firstname VARCHAR(255),
    lastname VARCHAR(255),
    teamid INT,
    playerid INT,
    general INT
);
LOAD DATA LOCAL INFILE '$NAMES_TEAMS_CSV'
INTO TABLE tmp_names
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"

# --- Mise à jour systématique des prénoms / noms ---
echo "🔁 Mise à jour firstname / lastname pour tous les playerid..." | tee -a "$LOG_FILE"
$cmd "
SET NAMES utf8mb4;

-- 1️⃣ Insertion des nouveaux prénoms manquants
INSERT INTO playernames (nameid, name)
SELECT (SELECT IFNULL(MAX(CAST(nameid AS UNSIGNED)),0) + ROW_NUMBER() OVER ()) AS nameid,
       firstname
FROM (SELECT DISTINCT firstname FROM tmp_names WHERE firstname <> '') AS t
WHERE firstname NOT IN (SELECT name FROM playernames);
SELECT ROW_COUNT();

-- 2️⃣ Insertion des nouveaux noms manquants
INSERT INTO playernames (nameid, name)
SELECT (SELECT IFNULL(MAX(CAST(nameid AS UNSIGNED)),0) + ROW_NUMBER() OVER ()) AS nameid,
       lastname
FROM (SELECT DISTINCT lastname FROM tmp_names WHERE lastname <> '') AS t
WHERE lastname NOT IN (SELECT name FROM playernames);
SELECT ROW_COUNT();

-- 3️⃣ Mise à jour systématique pour tous les playerid existants
UPDATE players p
JOIN tmp_names t ON p.playerid = t.playerid
LEFT JOIN playernames pn_first ON pn_first.name = t.firstname
LEFT JOIN playernames pn_last  ON pn_last.name  = t.lastname
SET 
    p.firstnameid = COALESCE(pn_first.nameid, p.firstnameid),
    p.lastnameid  = COALESCE(pn_last.nameid,  p.lastnameid);
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"

echo "✅ Firstname / lastname mis à jour pour tous les joueurs." | tee -a "$LOG_FILE"

# --- Import massif teamplayerlinks ---
echo "📥 Import / update teamplayerlinks..." | tee -a "$LOG_FILE"
$cmd "
SET NAMES utf8mb4;
LOAD DATA LOCAL INFILE '$TEAMPLAYERLINKS_CSV'
REPLACE INTO TABLE teamplayerlinks
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"
echo "✅ Teamplayerlinks importés / mis à jour." | tee -a "$LOG_FILE"

# --- Mise à jour position / jerseynumber ---
echo "🔁 Mise à jour position / jerseynumber..." | tee -a "$LOG_FILE"
$cmd "
SET NAMES utf8mb4;
UPDATE teamplayerlinks tpl
JOIN tmp_names t ON tpl.playerid = t.playerid
SET tpl.position = 29,
    tpl.jerseynumber = IFNULL(
        tpl.jerseynumber,
        (SELECT IFNULL(MAX(CAST(tpl2.jerseynumber AS UNSIGNED)),0) + 1
         FROM teamplayerlinks tpl2
         WHERE tpl2.teamid = tpl.teamid)
    );
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"
echo "✅ Position / jerseynumber mis à jour." | tee -a "$LOG_FILE"

# --- Dégagement des joueurs PL / clubs majeurs ---
echo "🚨 Dégagement des joueurs PL ou clubs majeurs..." | tee -a "$LOG_FILE"
AUTHORISED_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374"
FREE_AGENT_TEAMID=111592

$cmd "
SET NAMES utf8mb4;
UPDATE teamplayerlinks tpl
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
SET tpl.teamid = $FREE_AGENT_TEAMID
WHERE (ltl.leagueid = 13 OR tpl.teamid IN ($AUTHORISED_TEAMS));
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"

echo "✅ Joueurs concernés transférés en agents libres (teamid=$FREE_AGENT_TEAMID)." | tee -a "$LOG_FILE"

echo "🏁 Import et mise à jour terminés avec succès !" | tee -a "$LOG_FILE"
