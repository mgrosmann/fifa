#!/bin/bash
# Config
DB_NAME="FIFA15"
DB_USER="root"
DB_PASS="root"
DB_HOST="127.0.0.1"
DB_PORT="5000"

MYSQL_CMD="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT -D$DB_NAME"

############################################################
# --- INSERT players ---
############################################################
TABLE_PLAYERS="players"
CSV_PLAYERS="players.csv"

tail -n +2 "$CSV_PLAYERS" | while IFS=';' read -r \
playerid overallrating potential birthdate playerjointeamdate contractvaliduntil \
haircolorcode eyecolorcode skintonecode headtypecode bodytypecode height weight \
preferredfoot skillmoves internationalrep hashighqualityhead isretiring \
nationid preferredposition1 preferredposition2 preferredposition3 preferredposition4 \
acceleration sprintspeed agility balance jumping stamina strength reactions aggression \
interceptions positioning vision ballcontrol crossing dribbling finishing freekickaccuracy \
headingaccuracy longpassing shortpassing marking shotpower longshots standingtackle \
slidingtackle volleys curve penalties gkdiving gkhandling gkkicking gkreflexes gkpositioning
do

    SQL="INSERT INTO $TABLE_PLAYERS (
        playerid, overallrating, potential, birthdate, playerjointeamdate, contractvaliduntil,
        haircolorcode, eyecolorcode, skintonecode, headtypecode, bodytypecode, height, weight,
        preferredfoot, skillmoves, internationalrep, hashighqualityhead, isretiring, nationid,
        preferredposition1, preferredposition2, preferredposition3, preferredposition4,
        acceleration, sprintspeed, agility, balance, jumping, stamina, strength, reactions,
        aggression, interceptions, positioning, vision, ballcontrol, crossing, dribbling,
        finishing, freekickaccuracy, headingaccuracy, longpassing, shortpassing, marking,
        shotpower, longshots, standingtackle, slidingtackle, volleys, curve, penalties,
        gkdiving, gkhandling, gkkicking, gkreflexes, gkpositioning
    ) VALUES (
        $playerid, $overallrating, $potential, '$birthdate', '$playerjointeamdate', '$contractvaliduntil',
        $haircolorcode, $eyecolorcode, $skintonecode, $headtypecode, $bodytypecode, $height, $weight,
        $preferredfoot, $skillmoves, $internationalrep, '$hashighqualityhead', $isretiring, $nationid,
        $preferredposition1, $preferredposition2, $preferredposition3, $preferredposition4,
        $acceleration, $sprintspeed, $agility, $balance, $jumping, $stamina, $strength, $reactions,
        $aggression, $interceptions, $positioning, $vision, $ballcontrol, $crossing, $dribbling,
        $finishing, $freekickaccuracy, $headingaccuracy, $longpassing, $shortpassing, $marking,
        $shotpower, $longshots, $standingtackle, $slidingtackle, $volleys, $curve, $penalties,
        $gkdiving, $gkhandling, $gkkicking, $gkreflexes, $gkpositioning
    );"

    $MYSQL_CMD -e "$SQL"
done


############################################################
# --- INSERT teamplayerlinks ---
############################################################
TABLE_TPL="teamplayerlinks"
CSV_TPL="teamplayerlinks.csv"

tail -n +2 "$CSV_TPL" | while IFS=';' read -r teamid playerid jerseynumber position
do
    SQL="INSERT INTO $TABLE_TPL (
        teamid, playerid, jerseynumber, position
    ) VALUES (
        $teamid, $playerid, $jerseynumber, $position
    );"

    $MYSQL_CMD -e "$SQL"
done


############################################################
# --- INSERT / UPDATE playernames ---
############################################################
CSV_NAMES="playernames.csv"

# Reset temp table
$MYSQL_CMD -e "DROP TEMPORARY TABLE IF EXISTS tmp_names;"
$MYSQL_CMD -e "
CREATE TEMPORARY TABLE tmp_names (
    firstname  VARCHAR(100),
    lastname   VARCHAR(100),
    commonname VARCHAR(100),
    jerseyname VARCHAR(100)
);
"

# load CSV data into tmp table
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r firstname lastname commonname jerseyname
do
    SQL="INSERT INTO tmp_names (firstname, lastname, commonname, jerseyname)
         VALUES ('$firstname', '$lastname', '$commonname', '$jerseyname');"
    $MYSQL_CMD -e "$SQL"
done


############################################################
# ⚡ LOGIQUE INTELLIGENTE COMME TON SCRIPT EXISTANT
############################################################
$MYSQL_CMD -e "
SET NAMES utf8mb4;

-- Ajout prénoms/noms/common/jersey manquants dans playernames
INSERT INTO playernames (nameid,name)
SELECT IFNULL((SELECT MAX(nameid) FROM playernames),0) + ROW_NUMBER() OVER (), firstname
FROM (SELECT DISTINCT firstname FROM tmp_names WHERE firstname<>'' ) AS t
WHERE firstname NOT IN (SELECT name FROM playernames);

INSERT INTO playernames (nameid,name)
SELECT IFNULL((SELECT MAX(nameid) FROM playernames),0) + ROW_NUMBER() OVER (), lastname
FROM (SELECT DISTINCT lastname FROM tmp_names WHERE lastname<>'' ) AS t
WHERE lastname NOT IN (SELECT name FROM playernames);

INSERT INTO playernames (nameid,name)
SELECT IFNULL((SELECT MAX(nameid) FROM playernames),0) + ROW_NUMBER() OVER (), commonname
FROM (SELECT DISTINCT commonname FROM tmp_names WHERE commonname<>'' ) AS t
WHERE commonname NOT IN (SELECT name FROM playernames);

INSERT INTO playernames (nameid,name)
SELECT IFNULL((SELECT MAX(nameid) FROM playernames),0) + ROW_NUMBER() OVER (), jerseyname
FROM (SELECT DISTINCT jerseyname FROM tmp_names WHERE jerseyname<>'' ) AS t
WHERE jerseyname NOT IN (SELECT name FROM playernames);

-- Update players selon correspondance
UPDATE players p
JOIN tmp_names t ON p.playerid = p.playerid  -- playerid connu du CSV joueurs
LEFT JOIN playernames pn_first  ON pn_first.name  = t.firstname
LEFT JOIN playernames pn_last   ON pn_last.name   = t.lastname
LEFT JOIN playernames pn_common ON pn_common.name = t.commonname
LEFT JOIN playernames pn_jersey ON pn_jersey.name = t.jerseyname
SET p.firstnameid  = pn_first.nameid,
    p.lastnameid   = pn_last.nameid,
    p.commonnameid = pn_common.nameid,
    p.jerseynameid = pn_jersey.nameid;
"

echo "✔ playernames mis à jour"