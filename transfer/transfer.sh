#!/bin/bash

DB_NAME="FIFA14"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

while true; do
    read -p "Nom du joueur à transférer : " search_name

    # Rechercher les joueurs correspondants
    players=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
    SELECT p.playerid, CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
           IFNULL(pn_common.name,'') AS commonname,
           IFNULL(t.teamname,'Inconnu') AS current_team,
           p.overallrating
    FROM players p
    LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
    LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
    LEFT JOIN playernames pn_common ON p.commonnameid = pn_common.nameid
    LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
    LEFT JOIN teams t ON tpl.teamid = t.teamid
    WHERE CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%$search_name%'
       OR pn_common.name LIKE '%$search_name%';
    ")

    if [[ -z "$players" ]]; then
        echo "❌ Aucun joueur trouvé pour '$search_name'."
        continue
    fi

    num_players=$(echo "$players" | wc -l)

    if [[ $num_players -eq 1 ]]; then
        selected_player="$players"
    else
        echo "👥 Plusieurs joueurs trouvés :"
        echo "$players" | awk -F'\t' '{printf "%s - ID: %s - %s (%s) - Club: %s - Overall: %s\n", NR, $1, $2, $3, $4, $5}'
        read -p "➡️  Entrez le numéro du joueur à transférer : " player_selection
        selected_player=$(echo "$players" | sed -n "${player_selection}p")
    fi

    playerid=$(echo "$selected_player" | awk '{print $1}')
    fullname=$(echo "$selected_player" | awk -F'\t' '{print $2}')
    commonname=$(echo "$selected_player" | awk -F'\t' '{print $3}')

    if [[ -n "$commonname" && "$commonname" != "NULL" ]]; then
        display_name="$fullname ($commonname)"
    else
        display_name="$fullname"
    fi

    echo "📋 Équipes de $display_name :"

    # Récupérer les équipes actuelles
    teams=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
        SELECT tpl.teamid, t.teamname
        FROM teamplayerlinks tpl
        LEFT JOIN teams t ON tpl.teamid = t.teamid
        WHERE tpl.playerid=$playerid;
    ")

    if [[ -z "$teams" ]]; then
        echo "❌ Aucune équipe trouvée pour $fullname."
        continue
    fi

    num_teams=$(echo "$teams" | wc -l)

    if [[ $num_teams -eq 1 ]]; then
        # Si le joueur n’a qu’une seule équipe, on la prend directement
        old_teamid=$(echo "$teams" | awk '{print $1}')
        old_teamname=$(echo "$teams" | cut -d' ' -f2-)
        echo "⚽ Joueur actuellement dans : $old_teamname"
    else
        echo "$teams" | nl -w2 -s'  '
        read -p "➡️  Entrez le numéro de l'équipe à transférer : " team_selection
        selected_team=$(echo "$teams" | sed -n "${team_selection}p")
        old_teamid=$(echo "$selected_team" | awk '{print $1}')
        old_teamname=$(echo "$selected_team" | cut -d' ' -f2-)
    fi

    # Recherche tolérante du club de destination
    read -p "➡️  Nom (ou partie du nom) du club de destination : " new_team_search
    matching_teams=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
        SELECT teamid, teamname FROM teams WHERE teamname LIKE '%$new_team_search%';
    ")

    if [[ -z "$matching_teams" ]]; then
        echo "❌ Aucun club trouvé correspondant à '$new_team_search'."
        continue
    fi

    num_matches=$(echo "$matching_teams" | wc -l)
    if [[ $num_matches -eq 1 ]]; then
        new_teamid=$(echo "$matching_teams" | awk '{print $1}')
        new_teamname=$(echo "$matching_teams" | awk '{print $2}')
    else
        echo "🏟️ Clubs correspondants :"
        echo "$matching_teams" | nl -w2 -s'  '
        read -p "➡️  Entrez le numéro du club de destination : " club_selection
        selected_club=$(echo "$matching_teams" | sed -n "${club_selection}p")
        new_teamid=$(echo "$selected_club" | awk '{print $1}')
        new_teamname=$(echo "$selected_club" | cut -d' ' -f2-)
    fi

    # Effectuer le transfert
    mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -e "
        UPDATE teamplayerlinks 
        SET teamid=$new_teamid, position=29 
        WHERE playerid=$playerid AND teamid=$old_teamid;
    "

    echo "✅ $fullname transféré de $old_teamname vers $new_teamname (position 29 – réserviste)."

    read -p "Voulez-vous continuer ? (y/n) : " cont
    [[ "$cont" != "y" ]] && break
done