#!/bin/bash
# ============================================================
# Import CM Tracker FIFA15 avec valeurs par défaut
# ============================================================

# --- Configuration MySQL ---
DB_NAME="FIFA15"
DB_USER="root"
DB_PASS="root"
DB_HOST="127.0.0.1"
DB_PORT="5000"
MYSQL_CMD="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT -D$DB_NAME --local-infile=1"

CSV_CMTRACKER="players_cmtracker.csv"  # CSV CM Tracker
CSV_DEFAULT="default_player.csv"       # CSV joueur par défaut (CM15)
TMP_CSV="/tmp/tmp_players_final.csv"

# ============================================================
# 1️⃣ Charger la ligne par défaut dans tmp_players_default
# ============================================================
$MYSQL_CMD -e "
DROP TEMPORARY TABLE IF EXISTS tmp_players_default;
CREATE TEMPORARY TABLE tmp_players_default LIKE players;
LOAD DATA LOCAL INFILE '$CSV_DEFAULT'
REPLACE INTO TABLE tmp_players_default
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TEMPORARY TABLE IF EXISTS tmp_players;
CREATE TEMPORARY TABLE tmp_players LIKE players;
"

# ============================================================
# 2️⃣ Boucle CSV CM Tracker : copier la ligne par défaut + appliquer les valeurs du CSV
# ============================================================
tail -n +2 "$CSV_CMTRACKER" | while IFS=';' read -r \
playerid overallrating potential birthdate playerjointeamdate contractvaliduntil \
haircolorcode eyecolorcode skintonecode headtypecode bodytypecode height weight \
preferredfoot skillmoves internationalrep hashighqualityhead isretiring \
nationid preferredposition1 preferredposition2 preferredposition3 preferredposition4 \
acceleration sprintspeed agility balance jumping stamina strength reactions aggression \
interceptions positioning vision ballcontrol crossing dribbling finishing freekickaccuracy \
headingaccuracy longpassing shortpassing marking shotpower longshots standingtackle \
slidingtackle volleys curve penalties gkdiving gkhandling gkkicking gkreflexes gkpositioning
do
    # Copier la ligne par défaut
    $MYSQL_CMD -e "
    INSERT INTO tmp_players
    SELECT * FROM tmp_players_default;
    "

    # Récupérer le dernier playerid temporaire (copie de default)
    LAST_PLAYERID=$($MYSQL_CMD -N -e "SELECT playerid FROM tmp_players ORDER BY playerid DESC LIMIT 1;")

    # Mettre à jour cette ligne avec les valeurs du CSV CM Tracker
    $MYSQL_CMD -e "
    UPDATE tmp_players
    SET
        playerid = $playerid,
        overallrating = $overallrating,
        potential = $potential,
        birthdate = '$birthdate',
        playerjointeamdate = '$playerjointeamdate',
        contractvaliduntil = '$contractvaliduntil',
        haircolorcode = $haircolorcode,
        eyecolorcode = $eyecolorcode,
        skintonecode = $skintonecode,
        headtypecode = $headtypecode,
        bodytypecode = $bodytypecode,
        height = $height,
        weight = $weight,
        preferredfoot = $preferredfoot,
        skillmoves = $skillmoves,
        internationalrep = $internationalrep,
        hashighqualityhead = '$hashighqualityhead',
        isretiring = $isretiring,
        nationid = $nationid,
        preferredposition1 = $preferredposition1,
        preferredposition2 = $preferredposition2,
        preferredposition3 = $preferredposition3,
        preferredposition4 = $preferredposition4,
        acceleration = $acceleration,
        sprintspeed = $sprintspeed,
        agility = $agility,
        balance = $balance,
        jumping = $jumping,
        stamina = $stamina,
        strength = $strength,
        reactions = $reactions,
        aggression = $aggression,
        interceptions = $interceptions,
        positioning = $positioning,
        vision = $vision,
        ballcontrol = $ballcontrol,
        crossing = $crossing,
        dribbling = $dribbling,
        finishing = $finishing,
        freekickaccuracy = $freekickaccuracy,
        headingaccuracy = $headingaccuracy,
        longpassing = $longpassing,
        shortpassing = $shortpassing,
        marking = $marking,
        shotpower = $shotpower,
        longshots = $longshots,
        standingtackle = $standingtackle,
        slidingtackle = $slidingtackle,
        volleys = $volleys,
        curve = $curve,
        penalties = $penalties,
        gkdiving = $gkdiving,
        gkhandling = $gkhandling,
        gkkicking = $gkkicking,
        gkreflexes = $gkreflexes,
        gkpositioning = $gkpositioning
    WHERE playerid = $LAST_PLAYERID;
    "
done

# ============================================================
# 3️⃣ Export tmp_players vers CSV temporaire
# ============================================================
$MYSQL_CMD -e "
SELECT * FROM tmp_players
INTO OUTFILE '$TMP_CSV'
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n';
"

# ============================================================
# 4️⃣ Importer dans players (ON DUPLICATE KEY pour gérer doublons)
# ============================================================
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$TMP_CSV'
REPLACE INTO TABLE players
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n';
"

echo "✔ Tous les joueurs CM Tracker ont été importés dans players avec valeurs par défaut appliquées."
