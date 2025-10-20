#!/bin/bash

DB_NAME="fifa_db"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"
TEAM_ID="$1"  # ID de l'équipe passée en argument

# Récupérer tous les joueurs de l'équipe avec noms complets et previous team
players=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
SELECT 
    p.playerid,
    CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
    tpl.teamid AS current_team_id,
    t_current.teamname AS current_team_name,
    pt.previousteamid AS prev_team_id,
    t_prev.teamname AS prev_team_name
FROM players p
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
LEFT JOIN teams t_current ON tpl.teamid = t_current.teamid
LEFT JOIN previousteam pt ON p.playerid = pt.playerid
LEFT JOIN teams t_prev ON pt.previousteamid = t_prev.teamid
WHERE tpl.teamid = $TEAM_ID;
")

# Boucle interactive sur chaque joueur
while read -r playerid fullname current_team prev_team; do
    echo "--------------------------------------------"
    echo "Joueur : $fullname (ID $playerid)"
    echo "Équipe actuelle : $current_team"
    echo "Ancienne équipe : $prev_team"
    read -p "Renvoyer dans l'ancienne équipe ? (y/n) : " yn

    if [[ "$yn" == "y" && "$prev_team" != "NULL" ]]; then
        # Mise à jour uniquement pour la ligne du teamid initial
        mysql -u $USER -p$PASSWORD -D $DB_NAME -e \
        "UPDATE teamplayerlinks SET teamid=$prev_team WHERE playerid=$playerid AND teamid=$TEAM_ID;"
        echo "$fullname renvoyé dans l'équipe $prev_team."
    else
        echo "$fullname reste dans l'équipe actuelle."
    fi
done <<< "$players"
