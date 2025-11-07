#!/bin/bash

DB_NAME="FIFA16"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

PLAYERS_CSV="players.csv"           # CSV complet de la table players
NAMES_TEAMS_CSV="players_names_teams.csv"  # CSV plus léger (firstname;lastname;teamid;playerid)

# Vérifie que le CSV existe
if [[ ! -f "$NAMES_TEAMS_CSV" ]]; then
    echo "❌ Fichier introuvable : $NAMES_TEAMS_CSV"
    exit 1
fi

while IFS=";" read -r firstname lastname teamid playerid
do
    # Ignorer l'en-tête
    [[ "$firstname" == "firstname" ]] && continue

    # Vérifie si le joueur existe déjà
    playerexist=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT 1 FROM players WHERE playerid=$playerid;
    ")

    if [[ -n "$playerexist" ]]; then
        echo "⚠️  Joueur $playerid existe déjà, ignoré"
    else
        # Import du CSV complet pour ce joueur
        if [[ ! -f "$PLAYERS_CSV" ]]; then
            echo "❌ Fichier introuvable : $PLAYERS_CSV"
            exit 1
        fi

        mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
            LOAD DATA LOCAL INFILE '$PLAYERS_CSV'
            INTO TABLE players
            FIELDS TERMINATED BY ';'
            LINES TERMINATED BY '\n'
            IGNORE 1 LINES;
        "
        echo "✅ données du Joueur $playerid importé dans table players depuis players.csv"
    fi

    # --- Gestion des firstname / lastname ainsi que des teamid ---
    # Vérifie si le firstname existe
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

    # Vérifie si le lastname existe
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

    # Met à jour le joueur avec les nameid
    mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
        UPDATE players
        SET firstnameid=$new_fnameid, lastnameid=$new_lnameid
        WHERE playerid=$playerid;
    "

    # Vérifie si le lien joueur-équipe existe
    exists=$(mysql -N -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -se "
        SELECT 1 FROM teamplayerlinks WHERE playerid=$playerid AND teamid=$teamid;
    ")

    if [[ -z "$exists" ]]; then
        mysql -u "$USER" -p"$PASSWORD" -h "$HOST" -P "$PORT" -D "$DB_NAME" -e "
            INSERT INTO teamplayerlinks (playerid, teamid, position) VALUES ($playerid, $teamid, 29);
        "
    fi

    echo "✅ Joueur $firstname $lastname (ID $playerid) importé et associé à l'équipe $teamid."

done < "$NAMES_TEAMS_CSV"

echo "✅ Import terminé"
