#!/bin/bash

DB="FC26"
cmd="mysql -uroot -proot -h127.0.0.1 -P5000 -D $DB"
# Liste des ID d'équipes à exclure (sélections nationales + All Star)
EXCLUDED_TEAMS="974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190"

while true; do
    read -p "Nom du joueur à transférer : " search_name

    players=$($cmd  -se "
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
    WHERE (CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%$search_name%'
       OR pn_common.name LIKE '%$search_name%')
      AND (t.teamid IS NULL OR t.teamid NOT IN ($EXCLUDED_TEAMS));
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

    teams=$($cmd  -se "
        SELECT tpl.teamid, t.teamname
        FROM teamplayerlinks tpl
        LEFT JOIN teams t ON tpl.teamid = t.teamid
        WHERE tpl.playerid=$playerid
          AND t.teamid NOT IN ($EXCLUDED_TEAMS);
    ")

    if [[ -z "$teams" ]]; then
        echo "❌ Aucune équipe trouvée pour $fullname."
        continue
    fi

    num_teams=$(echo "$teams" | wc -l)

    if [[ $num_teams -eq 1 ]]; then
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

    read -p "➡️  Nom (ou partie du nom) du club de destination : " new_team_search
    matching_teams=$($cmd  -se "
        SELECT teamid, teamname
        FROM teams
        WHERE teamname LIKE '%$new_team_search%'
          AND teamid NOT IN ($EXCLUDED_TEAMS);
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
    bash /mnt/c/github/fifa/key.sh $playerid $new_teamid $DB

    echo "✅ $fullname transféré de $old_teamname vers $new_teamname (position 29 – réserviste)."

    read -p "Voulez-vous continuer ? (y/n) : " cont
    [[ "$cont" != "y" ]] && break
done
