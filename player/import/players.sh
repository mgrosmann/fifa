#!/bin/bash
set -e

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA15 -N -s"

CSV_NAMES="/mnt/c/github/fifa/player/import/playernames.csv"
CSV_PLAYERS="/mnt/c/github/fifa/cmtracker/import/players.csv"

echo "=== SUPPRESSION DES JOUEURS EXISTANTS DANS LE CSV NAMES ==="
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname playerjerseyname; do
    [[ -z "$playerid" ]] && continue
    $MYSQL_CMD -e "DELETE FROM players WHERE playerid=$playerid;"
    echo "✔ Player $playerid supprimé (s'il existait)"
done

echo "=== INSERTION DE TOUS LES JOUEURS DEPUIS players.csv ==="
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_PLAYERS'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

echo "=== MISE À JOUR DES nameid ==="
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname playerjerseyname; do
    [[ -z "$playerid" ]] && continue

    declare -A ids

    for FIELD in "firstname" "lastname" "commonname" "playerjerseyname"; do
        NAME=${!FIELD}
        [[ -z "$NAME" || "$NAME" == "NULL" ]] && continue  # Ignorer vide ou 'NULL'

        # Récupérer le nameid dans playernames
        ids[$FIELD]=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME' LIMIT 1;")
    done

    # Construire la clause SET
    set_clause=""
    [[ -n "${ids[firstname]}" ]] && set_clause+="firstnameid=${ids[firstname]},"
    [[ -n "${ids[lastname]}" ]] && set_clause+="lastnameid=${ids[lastname]},"
    [[ -n "${ids[commonname]}" ]] && set_clause+="commonnameid=${ids[commonname]},"
    [[ -n "${ids[playerjerseyname]}" ]] && set_clause+="playerjerseynameid=${ids[playerjerseyname]},"
    set_clause=${set_clause%,}  # retirer la dernière virgule

    if [[ -n "$set_clause" ]]; then
        $MYSQL_CMD -e "UPDATE players SET $set_clause WHERE playerid=$playerid;"
        echo "✔ Player $playerid mis à jour avec les nameid"
    fi
done

echo "=== FIN ==="
