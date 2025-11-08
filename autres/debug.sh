#!/bin/bash

# Bases à comparer
DBS=("FIFA14" "FIFA15" "FIFA16" "FIFA1518")
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

read -p "Entrez le playerid : " playerid
echo ""

printf "Résultats pour playerid %s :\n" "$playerid"
echo "-------------------------------------------------------------"
printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" "Base" "Firstname" "Lastname" "Commonname" "Fullname"
echo "-------------------------------------------------------------"

for DB in "${DBS[@]}"; do
    result=$(mysql -u $USER -p$PASSWORD -h$HOST -P$PORT -D $DB -N -e "
        SELECT
            COALESCE(fn.name, '') AS firstname,
            COALESCE(ln.name, '') AS lastname,
            COALESCE(cn.name, '') AS commonname,
            CONCAT(COALESCE(fn.name, ''), ' ', COALESCE(ln.name, '')) AS fullname
        FROM players p
        LEFT JOIN playernames fn ON p.firstnameid = fn.nameid
        LEFT JOIN playernames ln ON p.lastnameid = ln.nameid
        LEFT JOIN playernames cn ON p.commonnameid = cn.nameid
        WHERE p.playerid = $playerid;
    ")

    if [[ -z "$result" ]]; then
        printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" "$DB" "❌" "❌" "❌" "Non trouvé"
    else
        firstname=$(echo "$result" | awk '{print $1}')
        lastname=$(echo "$result" | awk '{print $2}')
        commonname=$(echo "$result" | awk '{print $3}')
        fullname=$(echo "$result" | awk '{print $4, $5}')
        printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" "$DB" "$firstname" "$lastname" "$commonname" "$fullname"
    fi
done

echo "-------------------------------------------------------------"