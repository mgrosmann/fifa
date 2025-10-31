#!/bin/bash

DB_NAME="FIFA15"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

# --- Sélection du club à parcourir ---
read -p "Nom (ou partie du nom) de l’équipe à parcourir : " TEAM_SEARCH

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

# --- Récupération des joueurs de l’équipe ---
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
ORDER BY fullname ASC;
" | sed 's/\t/|/g')

if [[ -z "$players" ]]; then
    echo "❌ Aucun joueur trouvé dans l’équipe '$TEAM_NAME'."
    exit 0
fi

# --- Parcours de chaque joueur ---
IFS=$'\n'
for line in $players; do
    IFS='|' read -r playerid fullname current_team_id current_team_name prev_team_id prev_team_name <<< "$line"

    echo "--------------------------------------------"
    echo "👤 Joueur : $fullname (ID $playerid)"
    echo "🏟️ Équipe actuelle : $current_team_name"
    echo "📜 Ancienne équipe actuelle : ${prev_team_name:-Aucune}"

    read -p "Souhaitez-vous définir ou modifier l’ancienne équipe ? (y/n) : " yn
    [[ "$yn" != "y" ]] && continue

    # Recherche tolérante de l'ancienne équipe
    read -p "Nom (ou partie du nom) de l’ancienne équipe : " OLD_TEAM_SEARCH
    old_matching=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
        SELECT teamid, teamname FROM teams WHERE teamname LIKE '%$OLD_TEAM_SEARCH%';
    ")

    if [[ -z "$old_matching" ]]; then
        echo "❌ Aucun club trouvé correspondant à '$OLD_TEAM_SEARCH'."
        continue
    fi

    num_old=$(echo "$old_matching" | wc -l)
    if [[ $num_old -eq 1 ]]; then
        OLD_TEAM_ID=$(echo "$old_matching" | awk '{print $1}')
        OLD_TEAM_NAME=$(echo "$old_matching" | cut -d' ' -f2-)
    else
        echo "🏟️ Clubs correspondants :"
        echo "$old_matching" | nl -w2 -s'  '
        read -p "➡️  Entrez le numéro du club voulu : " old_sel
        selected_old=$(echo "$old_matching" | sed -n "${old_sel}p")
        OLD_TEAM_ID=$(echo "$selected_old" | awk '{print $1}')
        OLD_TEAM_NAME=$(echo "$selected_old" | cut -d' ' -f2-)
    fi

    echo "🔙 Ancienne équipe choisie : $OLD_TEAM_NAME (ID $OLD_TEAM_ID)"

    # --- Mise à jour ou insertion ---
    exists=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
        SELECT COUNT(*) FROM previousteam WHERE playerid=$playerid;
    ")

    if [[ $exists -eq 0 ]]; then
        mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -e "
            INSERT INTO previousteam (playerid, previousteamid) VALUES ($playerid, $OLD_TEAM_ID);
        "
        echo "✅ Ancienne équipe ajoutée : $fullname → $OLD_TEAM_NAME"
    else
        mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -e "
            UPDATE previousteam SET previousteamid=$OLD_TEAM_ID WHERE playerid=$playerid;
        "
        echo "✅ Ancienne équipe mise à jour : $fullname → $OLD_TEAM_NAME"
    fi
done
