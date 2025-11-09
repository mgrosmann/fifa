#!/bin/bash

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"

# --- Recherche tolérante du nom de l’équipe ---
read -p "Nom (ou partie du nom) de l’équipe : " TEAM_SEARCH

matching_teams=$($cmd  -se "
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

# --- Récupération des joueurs avec rating et potentiel ---
players=$($cmd  -se "
SELECT 
    p.playerid,
    CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
    p.overallrating,
    p.potential
FROM players p
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
INNER JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
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
    IFS='|' read -r playerid fullname overall potential <<< "$line"

    echo "--------------------------------------------"
    echo "Joueur : $fullname (ID $playerid)"
    echo "Overall Rating actuel : $overall"
    echo "Potential actuel     : $potential"

    read -p "Modifier Overall Rating et Potential ensemble ? (y/n) : " yn
    if [[ "$yn" == "y" ]]; then
        read -p "Nouveau Overall Rating : " new_overall
        read -p "Nouveau Potential : " new_pot
        # Mise à jour en base
        $cmd  -e "
            UPDATE players 
            SET overallrating=$new_overall, potential=$new_pot 
            WHERE playerid=$playerid;
        "
        echo "✅ $fullname mis à jour (Overall: $new_overall, Potential: $new_pot)."
    else
        echo "➡️ $fullname reste inchangé."
    fi
done

echo "🏁 Mise à jour terminée."