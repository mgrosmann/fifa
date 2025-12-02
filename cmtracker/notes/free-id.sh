#!/bin/bash

# Config MySQL
DB_NAME="FIFA15"
DB_USER="root"
DB_PASS="root"
DB_HOST="127.0.0.1"


# Liste des playerid à libérer (séparés par espace)
PLAYER_IDS="275372 275468 275867 271119 260570 273018 271032 278901 278455 272829 279239 278903 275507 271417 278523 273018 271032"

for OLD_ID in $PLAYER_IDS; do
    # Obtenir le prochain playerid libre >= 50000
    NEW_ID=$(mysql -N -u$DB_USER -p$DB_PASS -h$DB_HOST -P5000 $DB_NAME -e "
        SELECT t1.playerid + 1 AS next_free_playerid
        FROM players t1
        LEFT JOIN players t2 ON t2.playerid = t1.playerid + 1
        WHERE t1.playerid >= 50000 AND t2.playerid IS NULL
        ORDER BY t1.playerid
        LIMIT 1;
    ")

    echo "Remplacement de $OLD_ID par $NEW_ID"

    # Mettre à jour players
    mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P5000 $DB_NAME -e "
        UPDATE players SET playerid = $NEW_ID WHERE playerid = $OLD_ID;
    "

    # Mettre à jour teamplayerlinks
    mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P5000 $DB_NAME -e "
        UPDATE teamplayerlinks SET playerid = $NEW_ID WHERE playerid = $OLD_ID;
    "

    # Mettre à jour playerloans
    mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P5000 $DB_NAME -e "
        UPDATE playerloans SET playerid = $NEW_ID WHERE playerid = $OLD_ID;
    "
done

echo "Mise à jour terminée pour tous les joueurs."

