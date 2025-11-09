#!/bin/bash
# --- import_massive_simple.sh ---
# Import massif de joueurs depuis CSV
# - REPLACE pour players et teamplayerlinks
# - Met à jour firstname/lastname
# - Position = 29
# - jerseynumber = MAX+1 par équipe si NULL

DB_NAME="FIFA14"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="3306"

PLAYERS_CSV="players.csv"
NAMES_TEAMS_CSV="players_names_teams.csv"
TEAMPLAYERLINKS_CSV="teamplayerlinks.csv"

LOG_FILE="import_massive_simple.log"
echo "===== Import démarré $(date) =====" >> "$LOG_FILE"

# --- Vérification des fichiers ---
for f in "$PLAYERS_CSV" "$NAMES_TEAMS_CSV" "$TEAMPLAYERLINKS_CSV"; do
    if [[ ! -f "$f" ]]; then
        echo "❌ Fichier manquant : $f" | tee -a "$LOG_FILE"
        exit 1
    fi
done

# --- Import massif players ---
echo "📥 Import / update players..." | tee -a "$LOG_FILE"
mysql --local-infile=1 -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
LOAD DATA LOCAL INFILE '$PLAYERS_CSV'
REPLACE INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"
echo "✅ Players importés / mis à jour." | tee -a "$LOG_FILE"

# --- Import temporaire CSV léger ---
echo "🔁 Import temporaire CSV léger..." | tee -a "$LOG_FILE"
mysql --local-infile=1 -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
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
"

# --- Update firstname/lastname en masse ---
echo "🔁 Mise à jour firstname / lastname..." | tee -a "$LOG_FILE"
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
-- Insertion des nouveaux prénoms
INSERT INTO playernames (nameid, name)
SELECT (SELECT IFNULL(MAX(CAST(nameid AS UNSIGNED)),0) + ROW_NUMBER() OVER ()) AS nameid,
       firstname
FROM (SELECT DISTINCT firstname FROM tmp_names WHERE firstname <> '') AS t
WHERE firstname NOT IN (SELECT name FROM playernames);

-- Insertion des nouveaux noms
INSERT INTO playernames (nameid, name)
SELECT (SELECT IFNULL(MAX(CAST(nameid AS UNSIGNED)),0) + ROW_NUMBER() OVER ()) AS nameid,
       lastname
FROM (SELECT DISTINCT lastname FROM tmp_names WHERE lastname <> '') AS t
WHERE lastname NOT IN (SELECT name FROM playernames);

-- Mise à jour des IDs prénom/nom
UPDATE players p
JOIN tmp_names t ON p.playerid = t.playerid
SET p.firstnameid = (SELECT nameid FROM playernames WHERE name = t.firstname LIMIT 1),
    p.lastnameid  = (SELECT nameid FROM playernames WHERE name = t.lastname LIMIT 1);
"
echo "✅ Firstname / lastname mis à jour." | tee -a "$LOG_FILE"

# --- Import massif teamplayerlinks ---
echo "📥 Import / update teamplayerlinks..." | tee -a "$LOG_FILE"
mysql --local-infile=1 -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
LOAD DATA LOCAL INFILE '$TEAMPLAYERLINKS_CSV'
REPLACE INTO TABLE teamplayerlinks
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"
echo "✅ Teamplayerlinks importés / mis à jour." | tee -a "$LOG_FILE"

# --- Mise à jour position et jerseynumber simple ---
echo "🔁 Mise à jour position / jerseynumber..." | tee -a "$LOG_FILE"
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
UPDATE teamplayerlinks tpl
JOIN tmp_names t ON tpl.playerid = t.playerid
SET tpl.position = 29,
    tpl.jerseynumber = IFNULL(
        tpl.jerseynumber,
        (SELECT IFNULL(MAX(CAST(tpl2.jerseynumber AS UNSIGNED)),0) + 1
         FROM teamplayerlinks tpl2
         WHERE tpl2.teamid = tpl.teamid)
    );
"
echo "✅ Position / jerseynumber mis à jour." | tee -a "$LOG_FILE"

echo "🏁 Import et mise à jour terminés avec succès !" | tee -a "$LOG_FILE"
