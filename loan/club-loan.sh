#!/bin/bash

DB_NAME="FIFA15"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"
CONVERT_SCRIPT="./dateloan.sh"

# --- Demande du club ---
read -p "Nom (ou partie du nom) du club : " CLUB_SEARCH

# Recherche du club
matching_teams=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
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
    # Récupère la seule ligne
    selected_club=$(echo "$matching_teams" | head -n1)
    TEAM_ID=$(echo "$selected_club" | awk '{print $1}')
    # Récupère le nom complet depuis la base
    TEAM_NAME=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
    ")
else
    echo "🏁 Clubs correspondants :"
    echo "$matching_teams" | nl -w2 -s'  '
    read -p "➡️  Entrez le numéro du club voulu : " club_selection
    selected_club=$(echo "$matching_teams" | sed -n "${club_selection}p")
    TEAM_ID=$(echo "$selected_club" | awk '{print $1}')
    TEAM_NAME=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT teamname FROM teams WHERE teamid = $TEAM_ID;
    ")
fi


# --- Choix du type de prêt ---
echo ""
echo "🎯 Que souhaitez-vous afficher pour $TEAM_NAME ?"
echo "1️⃣  Joueurs PRÊTÉS PAR le club"
echo "2️⃣  Joueurs PRÊTÉS AU club"
read -p "➡️  Entrez 1 ou 2 : " CHOICE
echo ""

echo "✅ Club sélectionné : $TEAM_NAME (ID $TEAM_ID)"
echo "--------------------------------------------"

# --- Requête 1 : joueurs prêtés PAR le club ---
if [[ "$CHOICE" == "1" ]]; then
    TITLE="📋 Liste des joueurs prêtés PAR $TEAM_NAME :"
    echo "$TITLE"

    players=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -Nse "
        SELECT DISTINCT
            p.playerid,
            CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) AS fullname,
            IFNULL(t_loanedto.teamname, '(inconnu)') AS club_associe,
            pl.loandateend
        FROM playerloans pl
        JOIN players p ON p.playerid = pl.playerid
        LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
        LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
        LEFT JOIN teamplayerlinks tpl2 ON p.playerid = tpl2.playerid
        LEFT JOIN teams t_loanedto ON tpl2.teamid = t_loanedto.teamid
        WHERE pl.teamidloanedfrom = $TEAM_ID
        ORDER BY pl.loandateend DESC;
    ")

# --- Requête 2 : joueurs prêtés AU club ---
elif [[ "$CHOICE" == "2" ]]; then
    TITLE="📋 Liste des joueurs prêtés À $TEAM_NAME :"
    echo "$TITLE"

    players=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -Nse "
        SELECT DISTINCT
            p.playerid,
            CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) AS fullname,
            IFNULL(t_from.teamname, '(inconnu)') AS club_associe,
            pl.loandateend
        FROM teamplayerlinks tpl
        JOIN playerloans pl ON tpl.playerid = pl.playerid
        JOIN players p ON p.playerid = tpl.playerid
        LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
        LEFT JOIN playernames pn_last  ON p.lastnameid = pn_last.nameid
        LEFT JOIN teams t_from ON pl.teamidloanedfrom = t_from.teamid
        WHERE tpl.teamid = $TEAM_ID
        ORDER BY pl.loandateend DESC;
    ")
else
    echo "❌ Choix invalide."
    exit 1
fi

# --- Vérification et affichage ---
if [[ -z "$players" ]]; then
    echo "❌ Aucun prêt trouvé pour $TEAM_NAME."
    exit 0
fi

printf "\n%-10s | %-25s | %-25s | %-12s\n" "PlayerID" "Nom complet" "Club associé" "Fin de prêt"
printf -- "-------------------------------------------------------------------------------------------\n"

IFS=$'\n'
for line in $players; do
    IFS=$'\t' read -r pid name club_associe loandateend <<< "$line"
    if [[ -n "$loandateend" && "$loandateend" != "NULL" ]]; then
        end_date=$($CONVERT_SCRIPT date "$loandateend")
    else
        end_date="(inconnue)"
    fi
    [[ "$club_associe" == "NULL" || -z "$club_associe" ]] && club_associe="(inconnu)"
    printf "%-10s | %-25s | %-25s | %-12s\n" "$pid" "$name" "$club_associe" "$end_date"
done

echo "-------------------------------------------------------------------------------------------"
echo "🏁 Fin de la liste."
