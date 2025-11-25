#!/bin/bash
# import_massive_full.sh
DB="FIFA14"
MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="5000"
cmd="mysql --local-infile=1 -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT -D $DB -A -N -e"

PLAYERS_CSV="players.csv"
NAMES_TEAMS_CSV="players_names_teams.csv"
TEAMPLAYERLINKS_CSV="teamplayerlinks.csv"
LOG_FILE="import_massive_full.log"

echo "===== Import démarré $(date) =====" | tee -a "$LOG_FILE"

# --- Import players ---
$cmd "
SET NAMES utf8mb4;
LOAD DATA LOCAL INFILE '$PLAYERS_CSV'
REPLACE INTO TABLE players
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' IGNORE 1 LINES;
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"

# --- Temp table pour noms ---
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
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' IGNORE 1 LINES;
" | tee -a "$LOG_FILE"

# --- Update playernames avec comparaison tolérante ---
$cmd "
SET NAMES utf8mb4;

INSERT INTO playernames (nameid,name)
SELECT (SELECT IFNULL(MAX(nameid),0)+ROW_NUMBER() OVER()) AS nameid, firstname
FROM (SELECT DISTINCT firstname FROM tmp_names WHERE firstname<>'') AS t
WHERE firstname NOT IN (SELECT name FROM playernames);

INSERT INTO playernames (nameid,name)
SELECT (SELECT IFNULL(MAX(nameid),0)+ROW_NUMBER() OVER()) AS nameid, lastname
FROM (SELECT DISTINCT lastname FROM tmp_names WHERE lastname<>'') AS t
WHERE lastname NOT IN (SELECT name FROM playernames);

UPDATE players p
JOIN tmp_names t ON p.playerid = t.playerid
JOIN playernames pn_first_new ON pn_first_new.name = t.firstname
JOIN playernames pn_last_new  ON pn_last_new.name  = t.lastname
JOIN playernames pn_first_old ON pn_first_old.nameid = p.firstnameid
JOIN playernames pn_last_old  ON pn_last_old.nameid  = p.lastnameid
SET p.firstnameid = pn_first_new.nameid,
    p.lastnameid  = pn_last_new.nameid
WHERE LOWER(REPLACE(pn_first_old.name,' ','')) <> LOWER(REPLACE(t.firstname,' ',''))
   OR LOWER(REPLACE(pn_last_old.name,' ','')) <> LOWER(REPLACE(t.lastname,' ',''));
" | tee -a "$LOG_FILE"

# --- Import teamplayerlinks ---
$cmd "
SET NAMES utf8mb4;
LOAD DATA LOCAL INFILE '$TEAMPLAYERLINKS_CSV'
REPLACE INTO TABLE teamplayerlinks
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' IGNORE 1 LINES;
SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"

# --- Recalcul complet des artificialkey ---
$cmd "
SET NAMES utf8mb4;

UPDATE teamplayerlinks tpl
JOIN (
    SELECT tpl2.playerid,
           ROW_NUMBER() OVER (
             ORDER BY
               tpl2.teamid ASC,
               CASE
                 WHEN tpl2.position < 28 THEN 0
                 WHEN tpl2.position = 28 THEN 1
                 WHEN tpl2.position = 29 THEN 2
                 ELSE 3
               END,
               CASE
                 WHEN tpl2.position < 28 THEN
                   CASE
                     WHEN p.preferredposition1 = 0 OR p.preferredposition2 = 0 THEN 0
                     WHEN tpl2.position BETWEEN 2 AND 8 THEN 1
                     WHEN tpl2.position BETWEEN 9 AND 19 THEN 2
                     WHEN tpl2.position BETWEEN 20 AND 27 THEN 3
                     ELSE 9
                   END
                 ELSE 9
               END,
               tpl2.position ASC,
               COALESCE(tpl2.artificialkey, 999999999),
               tpl2.playerid ASC
           ) - 1 AS new_key
    FROM teamplayerlinks tpl2
    LEFT JOIN players p ON p.playerid = tpl2.playerid
) AS rk ON tpl.playerid = rk.playerid
SET tpl.artificialkey = rk.new_key;
" | tee -a "$LOG_FILE"

# --- Donner à chaque joueur un jerseynumber libre ---
$cmd "
SET NAMES utf8mb4;

UPDATE teamplayerlinks tpl
JOIN tmp_names t ON tpl.playerid = t.playerid
SET tpl.position = 29,
    tpl.jerseynumber = COALESCE(
        tpl.jerseynumber,
        (SELECT IFNULL(MAX(t2.jerseynumber),0)+1
         FROM teamplayerlinks t2
         WHERE t2.teamid = tpl.teamid)
    );

SELECT ROW_COUNT();
" | tee -a "$LOG_FILE"

echo "🏁 Import complet et artificialkey recalculées !" | tee -a "$LOG_FILE"
