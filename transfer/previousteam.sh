#!/bin/bash

DB_NAME="FIFA15"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

# --- Recherche tolérante du nom de l’équipe ---
read -p "Nom (ou partie du nom) de l’équipe : " TEAM_SEARCH

matching_teams=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
    SELECT teamid, teamname FROM teams WHERE teamname LIKE '%$TEAM_SEARCH%';
")

if [[ -z "$matching_teams" ]]; then
    echo "❌ Aucun club trouvé correspondant à '$TEAM_SEARCH'."
    exit 0
fi

num_matches=$(echo "$matching_teams" | wc -l)

if [[ $num_matches -eq 1 ]]; then
    TEAM_ID=$(echo "$matching_teams" | awk '{print $1}')
    TEAM_NAME=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
    ")
else
    echo "🏟️ Clubs correspondants :"
    echo "$matching_teams" | nl -w2 -s'  '
    read -p "➡️  Entrez le numéro du club voulu : " club_selection
    selected_club=$(echo "$matching_teams" | sed -n "${club_selection}p")
    TEAM_ID=$(echo "$selected_club" | awk '{print $1}')
    TEAM_NAME=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
    ")
fi

echo "✅ Équipe sélectionnée : $TEAM_NAME"

# --- Requête SQL avec séparateur explicite '|'
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
WHERE tpl.teamid = $TEAM_ID
" | sed 's/\t/|/g')

# Vérifier s’il y a des joueurs
if [[ -z "$players" ]]; then
    echo "❌ Aucun joueur trouvé dans l’équipe '$TEAM_NAME'."
    exit 0
fi

# --- Lecture ligne par ligne ---
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
