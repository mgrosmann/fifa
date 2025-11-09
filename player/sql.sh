#!/bin/bash

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"

# --- Demande du nom du club ---
read -p "Nom (ou partie du nom) du club : " CLUB_SEARCH

# Recherche des clubs correspondants
matching_teams=$($cmd  -se "
    SELECT teamid, teamname 
    FROM teams 
    WHERE teamname LIKE '%$CLUB_SEARCH%';
")

if [[ -z "$matching_teams" ]]; then
    echo "❌ Aucun club trouvé correspondant à '$CLUB_SEARCH'."
    exit 1
fi

num_matches=$(echo "$matching_teams" | wc -l)

# Si un seul club trouvé
if [[ $num_matches -eq 1 ]]; then
    TEAM_ID=$(echo "$matching_teams" | awk '{print $1}')
    TEAM_NAME=$($cmd  -se "
        SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
    ")
else
    echo "🏁 Clubs trouvés :"
    echo "$matching_teams" | nl -w2 -s'  '
    read -p "➡️  Entrez le numéro du club voulu : " club_selection
    selected_club=$(echo "$matching_teams" | sed -n "${club_selection}p")
    TEAM_ID=$(echo "$selected_club" | awk '{print $1}')
    TEAM_NAME=$($cmd  -se "
        SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
    ")
fi

echo ""
echo "✅ Club sélectionné : $TEAM_NAME (ID $TEAM_ID)"
echo "--------------------------------------------"
echo "📋 Liste des joueurs :"
echo ""

# --- Requête principale ---
$cmd  --table -e "
    SELECT 
        p.playerid AS 'ID',
        CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) AS 'Nom complet',
        p.overallrating AS 'Overall',
        p.potential AS 'Potentiel'
    FROM players p
    JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
    LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
    LEFT JOIN playernames pn_last  ON p.lastnameid = pn_last.nameid
    WHERE tpl.teamid = $TEAM_ID
    ORDER BY p.overallrating DESC, p.potential DESC;
"

echo ""
echo "🏁 Fin de la liste."
