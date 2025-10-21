#!/bin/bash

DB_NAME="FIFA14"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

while true; do
    read -p "Nom du joueur à transférer : " search_name

    # Rechercher tous les joueurs correspondant au nom
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
        echo "$players" | awk -F'\t' '{printf "%s - %s (%s) - Club: %s - Overall: %s\n", NR, $2, $3, $4, $5}'
        read -p "➡️  Entrez le numéro du joueur à transférer : " player_selection
        selected_player=$(echo "$players" | sed -n "${player_selection}p")
    fi

    playerid=$(echo "$selected_player" | awk '{print $1}')
    fullname=$(echo "$selected_player" | awk '{for(i=2;i<=NF;i++){printf $i " "} print ""}')


    # Afficher les équipes actuelles du joueur
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

    echo "📋 Équipes de $fullname :"
    echo "$teams" | nl -w2 -s'  '

    read -p "➡️  Entrez le numéro de l'équipe à transférer : " team_selection
    selected_team=$(echo "$teams" | sed -n "${team_selection}p")
    old_teamid=$(echo "$selected_team" | awk '{print $1}')
    old_teamname=$(echo "$selected_team" | cut -d' ' -f2-)

    read -p "➡️  Nom du club de destination : " new_teamname
    new_teamid=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se \
        "SELECT teamid FROM teams WHERE teamname='$new_teamname' LIMIT 1;")

    if [[ -z "$new_teamid" ]]; then
        echo "❌ Club '$new_teamname' introuvable."
        continue
    fi

    # Transfert + mise en position 29 (réserviste)
    mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -e "
        UPDATE teamplayerlinks 
        SET teamid=$new_teamid, position=29 
        WHERE playerid=$playerid AND teamid=$old_teamid;
    "

    echo "✅ $fullname transféré de $old_teamname vers $new_teamname (position 29 – réserviste)."

    read -p "Voulez-vous continuer ? (y/n) : " cont
    [[ \"$cont\" != \"y\" ]] && break
done

