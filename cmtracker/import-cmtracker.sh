#!/bin/bash

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC26 -N -s"

CSV_CMTRACKER="/mnt/c/github/fifa/cmtracker/players.csv"
CSV_DEFAULT="/mnt/c/github/fifa/cmtracker/test.csv"
CSV_TPL="/mnt/c/github/fifa/cmtracker/teamplayerlinks.csv"
CSV_NAMES="/mnt/c/github/fifa/cmtracker/playernames.csv"

# ---------------------------------------------------------
# 1) RÉINITIALISATION DU JOUEUR PAR DÉFAUT (50075)
# ---------------------------------------------------------
default_exists=$($MYSQL_CMD --skip-column-names -e "SELECT 1 FROM players WHERE playerid=50075;")
if [[ "$default_exists" == "1" ]]; then
    echo "→ Suppression du joueur par défaut 50075"
    $MYSQL_CMD -e "DELETE FROM players WHERE playerid=50075;"
fi

# Charger le template pour réutilisation
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_DEFAULT'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

# ---------------------------------------------------------
# 2) UPDATE / INSERT DES JOUEURS CMTRACKER
# ---------------------------------------------------------
tail -n +2 "$CSV_CMTRACKER" | while IFS=';' read -r \
playerid overallrating potential birthdate playerjointeamdate contractvaliduntil \
haircolorcode eyecolorcode skintonecode headtypecode bodytypecode height weight \
preferredfoot skillmoves internationalrep hashighqualityhead isretiring nationality \
preferredposition1 preferredposition2 preferredposition3 preferredposition4 \
acceleration sprintspeed agility balance jumping stamina strength reactions aggression interceptions positioning \
vision ballcontrol crossing dribbling finishing freekickaccuracy headingaccuracy longpassing shortpassing marking \
shotpower longshots standingtackle slidingtackle volleys curve penalties gkdiving gkhandling gkkicking gkreflexes gkpositioning
do
    [[ -z "$playerid" ]] && continue
    echo "== Joueur : $playerid =="

    exists=$($MYSQL_CMD --skip-column-names -e "SELECT 1 FROM players WHERE playerid=$playerid;")

    if [[ "$exists" == "1" ]]; then
        echo "→ Le joueur existe déjà : mise à jour partielle"
        $MYSQL_CMD -e "
UPDATE players
SET
    overallrating=$overallrating,
    potential=$potential,
    contractvaliduntil='$contractvaliduntil',
    internationalrep=$internationalrep,
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
    else
        echo "→ Nouveau joueur : création depuis le template 50075"

        # 1) Supprimer 50075 si elle traîne
        $MYSQL_CMD -e "DELETE FROM players WHERE playerid=50075;"

        # 2) Charger le template
        $MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_DEFAULT'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

        # 3) Mettre à jour le template avec les données du CSV
        $MYSQL_CMD -e "
UPDATE players
SET
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
WHERE playerid=50075;
"

        # 4) Changer l'ID pour le nouveau joueur
        $MYSQL_CMD -e "
UPDATE players
SET playerid=$playerid
WHERE playerid=50075;
"
    fi
done

# ---------------------------------------------------------
# 3) TEAMPLAYERLINKS
# ---------------------------------------------------------
echo "--- TEAMPLAYERLINKS ---"

tail -n +2 "$CSV_TPL" | while IFS=';' read -r teamid playerid jerseynumber position
do
    tpl_teamid=$(echo "$teamid" | tr -d '" ' | xargs)
    tpl_playerid=$(echo "$playerid" | tr -d '" ' | xargs)
    [[ -z "$tpl_teamid" || -z "$tpl_playerid" ]] && continue

    exists_tpl=$($MYSQL_CMD --skip-column-names \
        -e "SELECT 1 FROM teamplayerlinks WHERE teamid=$tpl_teamid AND playerid=$tpl_playerid;")

    [[ "$exists_tpl" == "1" ]] && continue

    KEY=$($MYSQL_CMD --skip-column-names -e \
        "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")

    number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
    ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
   AND tpl1.teamid = tpl2.teamid
WHERE tpl1.teamid = $tpl_teamid
  AND tpl2.jerseynumber IS NULL;
" | tr -d '\n')
    [[ -z "$number" ]] && number=1

    $MYSQL_CMD -e "
INSERT INTO teamplayerlinks
(teamid, playerid, artificialkey, leaguegoals, isamongtopscorers, yellows,
 isamongtopscorersinteam, injury, leagueappearances, prevform, form,
 istopscorer, reds, position, jerseynumber)
VALUES ($tpl_teamid, $tpl_playerid, $KEY,0,0,0,0,0,0,0,3,0,0,29,$number);
"
done

echo "--- FIN TEAMPLAYERLINKS ---"

# ---------------------------------------------------------
# 4) PLAYERNAMES
# ---------------------------------------------------------
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname jerseyname
do
    for NAME in "$firstname" "$lastname" "$commonname" ; do
        [[ -z "$NAME" ]] && continue
        exists=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME';")
        if [[ -z "$exists" ]]; then
            maxid=$($MYSQL_CMD --skip-column-names -e "SELECT IFNULL(MAX(nameid),0) FROM playernames;")
            newid=$((maxid+1))
            $MYSQL_CMD -e "INSERT INTO playernames (nameid,name,commentaryid) VALUES ($newid,'$NAME',900000);"
        fi
    done

    firstid=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$firstname';")
    lastid=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$lastname';")
    commonid=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$commonname';")

    $MYSQL_CMD -e "
UPDATE players
SET firstnameid=$firstid,
    lastnameid=$lastid,
    commonnameid=$commonid,
    playerjerseynameid=$lastid
WHERE playerid=$playerid;
"
done
