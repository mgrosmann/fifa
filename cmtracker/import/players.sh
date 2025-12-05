#!/bin/bash

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA15 -N -s"

CSV_CMTRACKER="/mnt/c/github/fifa/cmtracker/import/players.csv"
CSV_DEFAULT="/mnt/c/github/fifa/cmtracker/import/test.csv"

echo "=== IMPORT / UPDATE PLAYERS ==="

# ---------------------------------------------------------
# 1) RÉINITIALISATION DU JOUEUR TEMPLATE (50075)
# ---------------------------------------------------------
default_exists=$($MYSQL_CMD --skip-column-names -e "SELECT 1 FROM players WHERE playerid=50075;")
if [[ "$default_exists" == "1" ]]; then
    echo "→ Suppression du joueur template 50075"
    $MYSQL_CMD -e "DELETE FROM players WHERE playerid=50075;"
fi

# ---------------------------------------------------------
# 2) UPDATE / INSERT DES JOUEURS CMTRACKER
# ---------------------------------------------------------
tail -n +2 "$CSV_CMTRACKER" | while IFS=';' read -r \
playerid overallrating potential birthdate playerjointeamdate contractvaliduntil \
_ _ _ _ _ height weight \
preferredfoot skillmoves internationalrep _ isretiring nationality \
preferredposition1 preferredposition2 preferredposition3 preferredposition4 firstname lastname \
acceleration sprintspeed agility balance jumping stamina strength reactions aggression interceptions positioning \
vision ballcontrol crossing dribbling finishing freekickaccuracy headingaccuracy longpassing shortpassing marking \
shotpower longshots standingtackle slidingtackle volleys curve penalties gkdiving gkhandling gkkicking gkreflexes gkpositioning
do
    [[ -z "$playerid" ]] && continue
    echo "== Joueur : $playerid =="

    exists=$($MYSQL_CMD --skip-column-names -e "SELECT 1 FROM players WHERE playerid=$playerid;")

    if [[ "$exists" == "1" ]]; then
        echo "→ Le joueur existe déjà : mise à jour"
        $MYSQL_CMD -e "
UPDATE players
SET
    overallrating=$overallrating,
    potential=$potential,
    contractvaliduntil='$contractvaliduntil',
    playerjointeamdate='$playerjointeamdate',
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
        echo "→ Nouveau joueur : création via template"

        # 1) Supprimer 50075 s'il existe
        $MYSQL_CMD -e "DELETE FROM players WHERE playerid=50075;"

        # 2) Charger le template
        $MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_DEFAULT'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

        # 3) Mise à jour des données du template
        $MYSQL_CMD -e "
UPDATE players
SET
    overallrating=$overallrating,
    potential=$potential,
    birthdate='$birthdate',
    playerjointeamdate='$playerjointeamdate',
    contractvaliduntil='$contractvaliduntil',
    height=$height,
    weight=$weight,
    preferredfoot='$preferredfoot',
    skillmoves=$skillmoves,
    internationalrep=$internationalrep,
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

        # 4) Changer l'ID vers celui du joueur réel
        $MYSQL_CMD -e "
UPDATE players
SET playerid=$playerid
WHERE playerid=50075;
"

        # 5) Mise à jour des nameids
        firstid=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$firstname' LIMIT 1;")
        lastid=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$lastname' LIMIT 1;")

        $MYSQL_CMD -e "
UPDATE players
SET firstnameid=$firstid,
    lastnameid=$lastid,
    playerjerseynameid=$lastid
WHERE playerid=$playerid;
"
    fi

done

echo "=== FIN IMPORT PLAYERS ==="
