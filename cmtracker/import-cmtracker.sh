#!/bin/bash

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC26 -N -s"

CSV_CMTRACKER="/mnt/c/github/fifa/cmtracker/players.csv"
CSV_DEFAULT="/mnt/c/github/fifa/cmtracker/test.csv"
NEW_CSV="/tmp/test.csv"
CSV_TPL="/mnt/c/github/fifa/cmtracker/teamplayerlinks.csv"
CSV_NAMES="/mnt/c/github/fifa/cmtracker/playernames.csv"

cp "$CSV_DEFAULT" "$NEW_CSV"

# 1) Charger valeurs par défaut
$MYSQL_CMD -e "DELETE FROM players WHERE playerid=50075;"
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$NEW_CSV'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

# 2) Update joueurs CMTracker
tail -n +2 "$CSV_CMTRACKER" | while IFS=';' read -r \
playerid overallrating potential birthdate playerjointeamdate contractvaliduntil \
haircolorcode eyecolorcode skintonecode headtypecode bodytypecode height weight \
preferredfoot skillmoves internationalrep hashighqualityhead isretiring nationality \
preferredposition1 preferredposition2 preferredposition3 preferredposition4 \
acceleration sprintspeed agility balance jumping stamina strength reactions aggression interceptions positioning \
vision ballcontrol crossing dribbling finishing freekickaccuracy headingaccuracy longpassing shortpassing marking \
shotpower longshots standingtackle slidingtackle volleys curve penalties gkdiving gkhandling gkkicking gkreflexes gkpositioning
do
    echo "== Joueur : $playerid =="

    $MYSQL_CMD -e "
UPDATE players
SET
    playerid=$playerid,
    overallrating=$overallrating,
    potential=$potential,
    birthdate='$birthdate',
    playerjointeamdate='$playerjointeamdate',
    contractvaliduntil='$contractvaliduntil',
    haircolorcode=$haircolorcode,
    eyecolorcode=$eyecolorcode,
    skintonecode=$skintonecode,
    headtypecode=$headtypecode,
    bodytypecode=$bodytypecode,
    height=$height,
    weight=$weight,
    preferredfoot='$preferredfoot',
    skillmoves=$skillmoves,
    internationalrep=$internationalrep,
    hashighqualityhead='$hashighqualityhead',
    isretiring=$isretiring,
    nationality='$nationality',
    preferredposition1='$preferredposition1',
    preferredposition2='$preferredposition2',
    preferredposition3='$preferredposition3',
    preferredposition4='$preferredposition4',
    acceleration=$acceleration,
    sprintspeed=$sprintspeed,
    agility=$agility,
    balance=$balance,
    jumping=$jumping,
    stamina=$stamina,
    strength=$strength,
    reactions=$reactions,
    aggression=$aggression,
    interceptions=$interceptions,
    positioning=$positioning,
    vision=$vision,
    ballcontrol=$ballcontrol,
    crossing=$crossing,
    dribbling=$dribbling,
    finishing=$finishing,
    freekickaccuracy=$freekickaccuracy,
    headingaccuracy=$headingaccuracy,
    longpassing=$longpassing,
    shortpassing=$shortpassing,
    marking=$marking,
    shotpower=$shotpower,
    longshots=$longshots,
    standingtackle=$standingtackle,
    slidingtackle=$slidingtackle,
    volleys=$volleys,
    curve=$curve,
    penalties=$penalties,
    gkdiving=$gkdiving,
    gkhandling=$gkhandling,
    gkkicking=$gkkicking,
    gkreflexes=$gkreflexes,
    gkpositioning=$gkpositioning
WHERE playerid=$playerid;
    "
done
#3
echo "--- TEAMPLAYERLINKS ---"

# Lire CSV en ignorant la première ligne
tail -n +2 "$CSV_TPL" | while IFS=';' read -r teamid playerid jerseynumber position
do
    # Nettoyer les variables (supprimer guillemets, espaces)
    tpl_teamid=$(echo "$teamid" | tr -d '" ' | xargs)
    tpl_playerid=$(echo "$playerid" | tr -d '" ' | xargs)

    # Vérification basique
    if [ -z "$tpl_teamid" ] || [ -z "$tpl_playerid" ] || ! [[ "$tpl_teamid" =~ ^[0-9]+$ ]]; then
        echo "Ligne ignorée : teamid ou playerid invalide (teamid='$tpl_teamid', playerid='$tpl_playerid')"
        continue
    fi

    echo "Traitement : teamid=$tpl_teamid, playerid=$tpl_playerid"

    # Générer une clé unique pour cette équipe
    KEY=$($MYSQL_CMD --skip-column-names -e "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")
    [ -z "$KEY" ] && KEY=1

    # Trouver le prochain numéro de maillot libre
    number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
    ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
   AND tpl1.teamid = tpl2.teamid
WHERE tpl1.teamid = $tpl_teamid
  AND tpl2.jerseynumber IS NULL;
" | tr -d '\n')

    [ -z "$number" ] && number=1

    # Insérer ou mettre à jour
    $MYSQL_CMD -e "
INSERT INTO teamplayerlinks
(teamid, playerid, artificialkey, leaguegoals, isamongtopscorers, yellows,
 isamongtopscorersinteam, injury, leagueappearances, prevform, form,
 istopscorer, reds, position, jerseynumber)
VALUES ($tpl_teamid, $tpl_playerid, $KEY,0,0,0,0,0,0,0,3,0,0,29,$number)
ON DUPLICATE KEY UPDATE artificialkey=$KEY;
"

done

echo "--- FIN TEAMPLAYERLINKS ---"

# 4) PLAYERNAMES
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname jerseyname
do
    echo "DEBUG: playerid='$playerid'"
    # Ajouter les noms dans playernames si manquant
    for NAME in "$firstname" "$lastname" "$commonname" "$jerseyname"; do
        EXISTS=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME';")
        if [ -z "$EXISTS" ]; then
            MAX_ID=$($MYSQL_CMD --skip-column-names -e "SELECT IFNULL(MAX(nameid),0) FROM playernames;")
            NEW_ID=$((MAX_ID+1))
            $MYSQL_CMD -e "INSERT INTO playernames (nameid,name,commentaryid) VALUES ($NEW_ID,'$NAME',900000);"
        fi
    done

    # Récupérer les ids
    FIRST_ID=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$firstname';")
    LAST_ID=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$lastname';")
    COMMON_ID=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$commonname';")
    JERSEY_ID=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$jerseyname';")

    $MYSQL_CMD -e "
UPDATE players
SET firstnameid=$FIRST_ID, lastnameid=$LAST_ID, commonnameid=$COMMON_ID, playerjerseynameid=$JERSEY_ID
WHERE playerid=$playerid;
    "
done
