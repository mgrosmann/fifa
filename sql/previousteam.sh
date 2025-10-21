#!/bin/bash

DB_NAME="FIFA15"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"
read -p "Nom de l'équipe : " TEAM_NAME
# Requête SQL avec séparateur explicite '|'
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
WHERE t_current.teamname = '$TEAM_NAME'
" | sed 's/\t/|/g')

# Vérifier s’il y a des joueurs
if [[ -z "$players" ]]; then
    echo "❌ Aucun joueur trouvé dans l’équipe '$TEAM_NAME'."
    exit 0
fi

# Lecture ligne par ligne en découpant sur '|'
IFS=$'\n'
for line in $players; do
    IFS='|' read -r playerid fullname current_team_id current_team_name prev_team_id prev_team_name <<< "$line"

    echo "--------------------------------------------"
    echo "Joueur : $fullname (ID $playerid)"
    echo "Équipe actuelle : $current_team_name"
    echo "Ancienne équipe : ${prev_team_name:-Aucune}"

    read -p "Renvoyer dans l’ancienne équipe ? (y/n) : " yn
    if [[ "$yn" == "y" && -n "$prev_team_id" && "$prev_team_id" != "NULL" ]]; then
        mysql -u $USER -p$PASSWORD -D $DB_NAME -e \
        "UPDATE teamplayerlinks 
         SET teamid=$prev_team_id, position=29  
         WHERE playerid=$playerid AND teamid=$current_team_id;"
        echo "✅ $fullname renvoyé vers $prev_team_name."
    else
        echo "➡️  $fullname reste dans $current_team_name."
    fi
done

