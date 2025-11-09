#!/bin/bash
# set_join_date.sh — Modifie la date d’arrivée d’un joueur (par équipe ou par nom)

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
CONVERTER="./dateloan.sh"  # Script de conversion ID/date FIFA

# Liste des équipes à exclure (sélections nationales + All Star)
EXCLUDED_TEAMS="974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190"

echo "🎯 Que souhaitez-vous faire ?"
echo "1️⃣  Parcourir une équipe entière"
echo "2️⃣  Modifier un joueur spécifique"
read -p "➡️  Choix (1 ou 2) : " mode

# -------------------------------------------------------------
# 🔹 MODE 1 : Parcourir une équipe
# -------------------------------------------------------------
if [[ "$mode" == "1" ]]; then
    read -p "Nom (ou partie du nom) de l’équipe à parcourir : " TEAM_SEARCH

    matching_teams=$($cmd -se "
        SELECT teamid, teamname 
        FROM teams 
        WHERE teamname LIKE '%$TEAM_SEARCH%'
          AND teamid NOT IN ($EXCLUDED_TEAMS);
    ")

    if [[ -z "$matching_teams" ]]; then
        echo "❌ Aucun club trouvé correspondant à '$TEAM_SEARCH'."
        exit 0
    fi

    num_matches=$(echo "$matching_teams" | wc -l)
    if [[ $num_matches -eq 1 ]]; then
        TEAM_ID=$(echo "$matching_teams" | awk '{print $1}')
        TEAM_NAME=$($cmd -se "
            SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
        ")
    else
        echo "🏟️ Clubs correspondants :"
        echo "$matching_teams" | nl -w2 -s'  '
        read -p "➡️  Entrez le numéro du club voulu : " club_selection
        selected_club=$(echo "$matching_teams" | sed -n "${club_selection}p")
        TEAM_ID=$(echo "$selected_club" | awk '{print $1}')
        TEAM_NAME=$($cmd -se "
            SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
        ")
    fi

    echo "✅ Équipe sélectionnée : $TEAM_NAME"
    echo "--------------------------------------------"

    players=$($cmd -se "
        SELECT 
            p.playerid,
            CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) AS fullname,
            p.playerjointeamdate
        FROM players p
        JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
        LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
        LEFT JOIN playernames pn_last  ON p.lastnameid = pn_last.nameid
        WHERE tpl.teamid = $TEAM_ID
          AND tpl.teamid NOT IN ($EXCLUDED_TEAMS)
        ORDER BY fullname ASC;
    " | sed 's/\t/|/g')

    if [[ -z "$players" ]]; then
        echo "❌ Aucun joueur trouvé dans l’équipe '$TEAM_NAME'."
        exit 0
    fi

    IFS=$'\n'
    for line in $players; do
        IFS='|' read -r playerid fullname join_id <<< "$line"

        if [[ -n "$join_id" && "$join_id" != "NULL" ]]; then
            join_date=$($CONVERTER date "$join_id")
        else
            join_date="Inconnue"
        fi

        echo "--------------------------------------------"
        echo "👤 Joueur : $fullname (ID $playerid)"
        echo "📅 Date d’arrivée : $join_date"

        read -p "Souhaitez-vous modifier cette date d’arrivée ? (y/n) : " yn
        [[ "$yn" != "y" ]] && continue

        read -p "➡️ Nouvelle date (JJ/MM/AAAA) : " new_date
        new_join_id=$($CONVERTER id "$new_date")

        if [[ -z "$new_join_id" ]]; then
            echo "❌ Erreur de conversion de la date."
            continue
        fi

        $cmd -se "
            UPDATE players SET playerjointeamdate = $new_join_id WHERE playerid = $playerid;
        "
        echo "✅ Date modifiée : $fullname → $new_date"
    done

    echo "--------------------------------------------"
    echo "🏁 Fin du traitement pour $TEAM_NAME."

# -------------------------------------------------------------
# 🔹 MODE 2 : Modifier un joueur spécifique
# -------------------------------------------------------------
elif [[ "$mode" == "2" ]]; then
    read -p "Nom (ou partie du nom) du joueur : " PLAYER_SEARCH

    matching_players=$($cmd -se "
        SELECT 
            p.playerid, 
            CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) AS fullname,
            t.teamname,
            p.playerjointeamdate
        FROM players p
        LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
        LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
        LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
        LEFT JOIN teams t ON tpl.teamid = t.teamid
        WHERE (CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) LIKE '%$PLAYER_SEARCH%')
          AND (t.teamid IS NULL OR t.teamid NOT IN ($EXCLUDED_TEAMS));
    ")

    if [[ -z "$matching_players" ]]; then
        echo "❌ Aucun joueur trouvé correspondant à '$PLAYER_SEARCH'."
        exit 0
    fi

    num_players=$(echo "$matching_players" | wc -l)
    if [[ $num_players -eq 1 ]]; then
        PLAYER_ID=$(echo "$matching_players" | awk '{print $1}')
    else
        echo "👥 Joueurs trouvés :"
        echo "$matching_players" | nl -w2 -s'  '
        read -p "➡️  Entrez le numéro du joueur voulu : " player_sel
        selected_player=$(echo "$matching_players" | sed -n "${player_sel}p")
        PLAYER_ID=$(echo "$selected_player" | awk '{print $1}')
    fi

    fullname=$($cmd -se "
        SELECT CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) 
        FROM players p 
        LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
        LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
        WHERE playerid = $PLAYER_ID;
    ")

    join_id=$($cmd -se "
        SELECT playerjointeamdate FROM players WHERE playerid = $PLAYER_ID;
    ")

    if [[ -n "$join_id" && "$join_id" != "NULL" ]]; then
        join_date=$($CONVERTER date "$join_id")
    else
        join_date="Inconnue"
    fi

    echo "--------------------------------------------"
    echo "👤 $fullname (ID $PLAYER_ID)"
    echo "📅 Date actuelle d’arrivée : $join_date"

    read -p "➡️ Nouvelle date (JJ/MM/AAAA) : " new_date
    new_join_id=$($CONVERTER id "$new_date")

    $cmd -se "
        UPDATE players SET playerjointeamdate = $new_join_id WHERE playerid = $PLAYER_ID;
    "
    echo "✅ Date mise à jour : $fullname → $new_date"

else
    echo "❌ Choix invalide."
    exit 1
fi
