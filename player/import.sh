#!/bin/bash

DB_NAME="FIFA16"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

PLAYERS_CSV="players.csv"           # CSV complet de la table players
NAMES_TEAMS_CSV="players_names_teams.csv"  # CSV léger (firstname;lastname;teamid;playerid)

# Vérifie que le CSV léger existe
if [[ ! -f "$NAMES_TEAMS_CSV" ]]; then
    echo "❌ Fichier introuvable : $NAMES_TEAMS_CSV"
    exit 1
fi

# --- Étape 1 : déterminer les playerid manquants ---
missing_playerids=()

while IFS=";" read -r firstname lastname teamid playerid
do
    [[ "$firstname" == "firstname" ]] && continue

    exists=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT 1 FROM players WHERE playerid=$playerid;
    ")

    if [[ -z "$exists" ]]; then
        missing_playerids+=("$playerid")
    else
        echo "⚠️  Joueur $playerid existe déjà, ignoré"
    fi
done < "$NAMES_TEAMS_CSV"

# --- Étape 2 : si des joueurs manquent, créer un CSV temporaire filtré ---
if [[ ${#missing_playerids[@]} -gt 0 ]]; then
    TMP_CSV="players_to_import.csv"
    # En-tête
    head -n 1 "$PLAYERS_CSV" > "$TMP_CSV"
    # Pour chaque playerid manquant, extraire la ligne correspondante
    for pid in "${missing_playerids[@]}"; do
        grep -E ";$pid$" "$PLAYERS_CSV" >> "$TMP_CSV"
    done

    # --- Étape 3 : LOAD DATA pour tous les joueurs manquants en une seule fois ---
    mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
        LOAD DATA LOCAL INFILE '$TMP_CSV'
        INTO TABLE players
        FIELDS TERMINATED BY ';'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES;
    "
    echo "✅ Joueurs manquants importés dans la table players depuis $TMP_CSV"
    rm "$TMP_CSV"
else
    echo "ℹ️ Aucun joueur nouveau à importer dans players.csv"
fi

# --- Étape 4 : mettre à jour firstname, lastname et teamid pour tous les joueurs ---
while IFS=";" read -r firstname lastname teamid playerid
do
    [[ "$firstname" == "firstname" ]] && continue

    # --- firstname ---
    existing_fname=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT nameid FROM playernames WHERE name='$firstname';
    ")
    if [[ -z "$existing_fname" ]]; then
        mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
            INSERT INTO playernames (nameid, name) VALUES ((SELECT IFNULL(MAX(nameid),0)+1 FROM playernames), '$firstname');
        "
        new_fnameid=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "SELECT MAX(nameid) FROM playernames;")
    else
        new_fnameid="$existing_fname"
    fi

    # --- lastname ---
    existing_lname=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT nameid FROM playernames WHERE name='$lastname';
    ")
    if [[ -z "$existing_lname" ]]; then
        mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
            INSERT INTO playernames (nameid, name) VALUES ((SELECT IFNULL(MAX(nameid),0)+1 FROM playernames), '$lastname');
        "
        new_lnameid=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "SELECT MAX(nameid) FROM playernames;")
    else
        new_lnameid="$existing_lname"
    fi

    # --- Met à jour le joueur ---
    mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
        UPDATE players
        SET firstnameid=$new_fnameid, lastnameid=$new_lnameid
        WHERE playerid=$playerid;
    "

    # --- teamplayerlinks ---
    exists=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT 1 FROM teamplayerlinks WHERE playerid=$playerid AND teamid=$teamid;
    ")
    if [[ -z "$exists" ]]; then
        mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
            INSERT INTO teamplayerlinks (playerid, teamid, position) VALUES ($playerid, $teamid, 29);
        "
    fi

    echo "✅ Joueur $firstname $lastname (ID $playerid) traité et associé à l'équipe $teamid."

done < "$NAMES_TEAMS_CSV"

echo "✅ Import terminé"
