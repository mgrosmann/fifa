#!/bin/bash

DB_NAME="FIFA15"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

# --- Étape 1 : Recherche du joueur ---
read -p "Nom (ou partie du nom) du joueur : " PLAYER_SEARCH

matching_players=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
    SELECT 
        p.playerid, 
        CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) AS fullname,
        n.nationname AS nationality
    FROM players p
    LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
    LEFT JOIN playernames pn_last  ON p.lastnameid = pn_last.nameid
    LEFT JOIN nations n ON p.nationality = n.nationid
    WHERE CONCAT(IFNULL(pn_first.name,''), ' ', IFNULL(pn_last.name,'')) LIKE '%$PLAYER_SEARCH%';
")

if [[ -z "$matching_players" ]]; then
    echo "❌ Aucun joueur trouvé correspondant à '$PLAYER_SEARCH'."
    exit 1
fi

# Compter le nombre de lignes
nb_players=$(echo "$matching_players" | wc -l)

if [[ $nb_players -eq 1 ]]; then
    selected_player="$matching_players"
    echo "✅ Joueur trouvé :"
    echo "$selected_player"
else
    echo "🏟️ Joueurs trouvés :"
    echo "$matching_players" | nl -w2 -s'  '
    read -p "➡️  Entrez le numéro du joueur à modifier : " player_choice
    selected_player=$(echo "$matching_players" | sed -n "${player_choice}p")
fi

PLAYER_ID=$(echo "$selected_player" | awk '{print $1}')
PLAYER_NAME=$(echo "$selected_player" | cut -f2)

echo ""
echo "✅ Joueur sélectionné : $PLAYER_NAME (ID $PLAYER_ID)"
echo ""

# --- Étape 2 : Recherche de la nouvelle nationalité ---
read -p "Nouvelle nationalité (ou partie du nom) : " NATION_SEARCH

matching_nations=$(mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
    SELECT nationid, nationname FROM nations WHERE nationname LIKE '%$NATION_SEARCH%';
")

if [[ -z "$matching_nations" ]]; then
    echo "❌ Aucune nationalité trouvée correspondant à '$NATION_SEARCH'."
    exit 1
fi

nb_nations=$(echo "$matching_nations" | wc -l)

if [[ $nb_nations -eq 1 ]]; then
    selected_nation="$matching_nations"
    echo "🌍 Nouvelle nationalité :"
    echo "$selected_nation"
else
    echo "🌍 Nationalités possibles :"
    echo "$matching_nations" | nl -w2 -s'  '
    read -p "➡️  Entrez le numéro de la nouvelle nationalité : " nation_choice
    selected_nation=$(echo "$matching_nations" | sed -n "${nation_choice}p")
fi

NEW_NATION_ID=$(echo "$selected_nation" | awk '{print $1}')
NEW_NATION_NAME=$(echo "$selected_nation" | cut -f2)

echo ""
echo "🛠️ Mise à jour : $PLAYER_NAME → $NEW_NATION_NAME"

# --- Étape 3 : Confirmation ---
read -p "Confirmer la mise à jour ? (o/n) : " confirm
if [[ "$confirm" != "o" && "$confirm" != "O" ]]; then
    echo "❌ Opération annulée."
    exit 0
fi

# --- Étape 4 : Mise à jour dans la base ---
mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
    UPDATE players 
    SET nationality = $NEW_NATION_ID 
    WHERE playerid = $PLAYER_ID;
"

if [[ $? -eq 0 ]]; then
    echo "✅ Nationalité mise à jour avec succès !"
else
    echo "❌ Erreur lors de la mise à jour."
fi