#!/bin/bash

DB_USER="root"
DB_PASS="root"
DB_HOST="127.0.0.1"
DB_PORT="5000"
DB_NAME="FIFA15"
# Tableau OLD→NEW
declare -A MAP=(
    [241468]=258966
    [241505]=243627
    [241859]=242816
    [239889]=239892
    [212406]=73562
    [220168]=255654
    [237957]=242434
    [207967]=238216
    [225679]=253004
    [240235]=246174
    [266578]=265578
    [242148]=256261
    [273025]=273018
    [234233]=271032
    [241268]=272505
)

# Liste des tables à modifier
TABLES=(
    players
    teamplayerlinks
    playerloans
)

echo "=== Mise à jour des playerid dans la base $DB_NAME ==="

for OLD_ID in "${!MAP[@]}"; do
    NEW_ID="${MAP[$OLD_ID]}"

    echo "-> $OLD_ID  devient  $NEW_ID"

    for TABLE in "${TABLES[@]}"; do
        mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -e "
            UPDATE $TABLE SET playerid = $NEW_ID WHERE playerid = $OLD_ID;
        "
    done
done

echo "=== Terminé ==="
