#!/bin/bash

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA1518 -N -s"
CSV_NAMES="/mnt/c/github/fifa/player/import/playernames.csv"

# ---------------------------------------------------------
# 1) INSERT DES NOMS DANS playernames SI ABSENTS
# ---------------------------------------------------------
tail -n +2 "$CSV_NAMES" | while IFS=';' read -r playerid firstname lastname commonname playerjerseyname
do
    # Nettoyage des espaces et retours chariot sans xargs
    firstname=$(echo "$firstname" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')
    lastname=$(echo "$lastname" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')
    commonname=$(echo "$commonname" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')
    playerjerseyname=$(echo "$playerjerseyname" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')

    # Boucle sur tous les noms à traiter
    for NAME in "$firstname" "$lastname" "$commonname" "$playerjerseyname"; do
        # Ignorer vide ou 'NULL'
        [[ -z "$NAME" || "$NAME" == "NULL" ]] && continue

        # Ajouter un backslash avant chaque apostrophe pour MySQL
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
