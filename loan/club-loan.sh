#!/bin/bash

DB_NAME="FIFA15"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"
CONVERT_SCRIPT="./dateloan.sh"  # <- chemin vers ton script de conversion

# --- Demande du club ---
read -p "Nom (ou partie du nom) du club : " CLUB_SEARCH

# Recherche tolérante du club
matching_teams=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -se "
    SELECT teamid, teamname 
    FROM teams 
    WHERE teamname LIKE '%$CLUB_SEARCH%';
")

if [[ -z "$matching_teams" ]]; then
    echo "❌ Aucun club trouvé correspondant à '$CLUB_SEARCH'."
    exit 1
fi

num_matches=$(echo "$matching_teams" | wc -l)

if [[ $num_matches -eq 1 ]]; then
    TEAM_ID=$(echo "$matching_teams" | awk '{print $1}')
    TEAM_NAME=$(echo "$matching_teams" | cut -d' ' -f2-)
else
    echo "🏟️ Clubs correspondants :"
    echo "$matching_teams" | nl -w2 -s'  '
    read -p "➡️  Entrez le numéro du club voulu : " club_selection
    selected_club=$(echo "$matching_teams" | sed -n "${club_selection}p")
    TEAM_ID=$(echo "$selected_club" | awk '{print $1}')
    TEAM_NAME=$(echo "$selected_club" | cut -d' ' -f2-)
fi

echo "✅ Club sélectionné : $TEAM_NAME (ID $TEAM_ID)"
echo "--------------------------------------------"
echo "📋 Liste des joueurs prêtés par $TEAM_NAME :"

# --- Liste brute des joueurs prêtés ---
players=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB_NAME -Nse "
SELECT 
    p.playerid,
    CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
    t_cur.teamname AS loaned_to,
    pl.loandateend
FROM playerloans pl
LEFT JOIN players p ON pl.playerid = p.playerid
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
LEFT JOIN teams t_cur ON tpl.teamid = t_cur.teamid
WHERE pl.teamidloanedfrom = $TEAM_ID
ORDER BY pl.loandateend DESC;
")

if [[ -z "$players" ]]; then
    echo "❌ Aucun joueur prêté par $TEAM_NAME."
    exit 0
fi

# --- Affichage avec conversion de la date ---
printf "\n%-10s | %-25s | %-25s | %-12s\n" "PlayerID" "Nom complet" "Prêté à" "Fin de prêt"
printf -- "-------------------------------------------------------------------------------------------\n"

IFS=$'\n'
for line in $players; do
    IFS=$'\t' read -r pid name loaned_to loandateend <<< "$line"
    if [[ -n "$loandateend" && "$loandateend" != "NULL" ]]; then
        end_date=$($CONVERT_SCRIPT date "$loandateend")
    else
        end_date="(inconnue)"
    fi
    printf "%-10s | %-25s | %-25s | %-12s\n" "$pid" "$name" "$loaned_to" "$end_date"
done

echo "-------------------------------------------------------------------------------------------"
echo "🏁 Fin de la liste."
