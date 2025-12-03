#!/bin/bash

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA15 -N -s"
CSV_NAMES="/mnt/c/github/fifa/cmtracker/playernames.csv"

# ---------------------------------------------------------
# 1) INSERT DES NOMS DANS playernames SI ABSENTS
# ---------------------------------------------------------
while IFS=';' read -r playerid firstname lastname
do
    # Nettoyage des espaces et retours chariot
firstname=$(echo "$firstname" | tr -d '\r' | xargs | tr -cd '\11\12\15\40-\176')
lastname=$(echo "$lastname"  | tr -d '\r' | xargs | tr -cd '\11\12\15\40-\176')


    for NAME in "$firstname" "$lastname"; do
        [[ -z "$NAME" ]] && continue  # Ignorer les champs vides

        # Vérifier si le nom existe déjà
        exists=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME';")

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
VALUES ($newid, '$NAME', 900000);
"
        else
            echo "→ Nom '$NAME' existe déjà (nameid $exists), pas d'insertion"
        fi
    done
done < <(tail -n +2 "$CSV_NAMES")  # ignorer l'en-tête CSV

