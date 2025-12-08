#!/bin/bash
set -e

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------
MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC15 -N -s"
CSV_NAMES="/mnt/c/github/fifa/player/import/playernames.csv"
CSV_PLAYERS="/mnt/c/github/fifa/player/import/players.csv"

# ---------------------------------------------------------
# 1) INSERT DES NOMS DANS playernames SI ABSENTS
# ---------------------------------------------------------
echo "=== INSERTION DES NOMS DANS playernames ==="
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname playerjerseyname
do
    for NAME in "$firstname" "$lastname" "$commonname" "$playerjerseyname"; do
        [[ -z "$NAME" || "$NAME" == "NULL" ]] && continue

        # Nettoyage des espaces et retours chariot
        NAME=$(echo "$NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')

        # Échapper les apostrophes pour MySQL
        NAME_ESCAPED=$(echo "$NAME" | sed "s/'/\\\\'/g")

        # Vérifier si le nom existe déjà
        exists=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME_ESCAPED';")

        if [[ -z "$exists" ]]; then
            # Trouver le prochain nameid disponible
            newid=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(pn1.nameid + 1), 1)
FROM playernames pn1
LEFT JOIN playernames pn2 ON pn1.nameid + 1 = pn2.nameid
WHERE pn2.nameid IS NULL;
" | tr -d '\n')

            # Insérer le nom
            echo "→ Insertion du nom '$NAME' avec nameid $newid"
            $MYSQL_CMD -e "
INSERT INTO playernames (nameid, name, commentaryid)
VALUES ($newid, '$NAME_ESCAPED', 900000);
"
        else
            echo "→ Nom '$NAME' existe déjà (nameid $exists), pas d'insertion"
        fi
    done
done

# ---------------------------------------------------------
# 2) SUPPRESSION DES JOUEURS EXISTANTS
# ---------------------------------------------------------
echo "=== SUPPRESSION DES JOUEURS EXISTANTS ==="
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname playerjerseyname; do
    [[ -z "$playerid" ]] && continue
    $MYSQL_CMD -e "DELETE FROM players WHERE playerid=$playerid;"
    echo "✔ Player $playerid supprimé (s'il existait)"
done

# ---------------------------------------------------------
# 3) INSERTION DES JOUEURS
# ---------------------------------------------------------
echo "=== INSERTION DES JOUEURS DEPUIS players.csv ==="
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_PLAYERS'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

# ---------------------------------------------------------
# 4) MISE À JOUR DES nameid
# ---------------------------------------------------------
echo "=== MISE À JOUR DES nameid DES JOUEURS ==="
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname playerjerseyname; do
    [[ -z "$playerid" ]] && continue

    declare -A ids

    for FIELD in "firstname" "lastname" "commonname" "playerjerseyname"; do
        NAME=${!FIELD}
        [[ -z "$NAME" || "$NAME" == "NULL" ]] && continue

        # Nettoyage et échappement des apostrophes
        NAME=$(echo "$NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')
        NAME_ESCAPED=$(echo "$NAME" | sed "s/'/\\\\'/g")

        # Récupérer le nameid
        ids[$FIELD]=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME_ESCAPED' LIMIT 1;")
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

