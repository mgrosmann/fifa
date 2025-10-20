#!/bin/bash

DB_NAME="fifa_db"
USER="root"
PASSWORD="root"

while true; do
    read -p "Nom du joueur à transférer : " search_name

    # Rechercher tous les joueurs correspondant au nom
    players=$(mysql -u $USER -p$PASSWORD -D $DB_NAME -se "
    SELECT p.playerid, CONCAT(pn_first.name, ' ', pn_last.name) AS fullname
    FROM players p
    LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
    LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
    WHERE CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%$search_name%';
    ")

    if [[ -z "$players" ]]; then
        echo "Aucun joueur trouvé pour '$search_name'."
        continue
    fi

    # Compter le nombre de résultats
    num_players=$(echo "$players" | wc -l)

    if [[ $num_players -eq 1 ]]; then
        # Un seul joueur trouvé → on l'utilise directement
        selected_player="$players"
    else
        # Plusieurs joueurs trouvés → demander à l'utilisateur
        echo "Plusieurs joueurs trouvés :"
        echo "$players" | nl -w2 -s'  '
        read -p "Entrez le numéro du joueur à transférer : " player_selection
        selected_player=$(echo "$players" | sed -n "${player_selection}p")
    fi

    playerid=$(echo "$selected_player" | awk '{print $1}')
    fullname=$(echo "$selected_player" | awk '{print $2" "$3}')

    # Afficher toutes les équipes pour ce joueur
    teams=$(mysql -u $USER -p$PASSWORD -D $DB_NAME -se "
    SELECT tpl.teamid, t.teamname, t.teamtype
    FROM teamplayerlinks tpl
    LEFT JOIN teams t ON tpl.teamid = t.teamid
    WHERE tpl.playerid=$playerid;
    ")

    echo "Équipes de $fullname :"
    echo "$teams" | nl -w2 -s'  '

    read -p "Entrez le numéro de l'équipe à transférer : " team_selection
    selected_team=$(echo "$teams" | sed -n "${team_selection}p")
    old_teamid=$(echo "$selected_team" | awk '{print $1}')
    old_teamname=$(echo "$selected_team" | awk '{print $2}')
    teamtype=$(echo "$selected_team" | awk '{print $3}')

    read -p "Nom du club de destination : " new_teamname
    new_teamid=$(mysql -u $USER -p$PASSWORD -D $DB_NAME -se \
    "SELECT teamid FROM teams WHERE teamname='$new_teamname' LIMIT 1;")

    if [[ -z "$new_teamid" ]]; then
        echo "Club '$new_teamname' introuvable."
        continue
    fi

    mysql -u $USER -p$PASSWORD -D $DB_NAME -e \
    "UPDATE teamplayerlinks SET teamid=$new_teamid WHERE playerid=$playerid AND teamid=$old_teamid;"

    echo "$fullname ($teamtype) transféré de $old_teamname vers $new_teamname."

    read -p "Voulez-vous continuer ? (y/n) : " cont
    [[ "$cont" != "y" ]] && break
done
