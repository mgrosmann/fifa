#!/bin/bash
set -euo pipefail

# -----------------------
# CONFIG
# -----------------------
MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC16 -N -s"
CSV_NAMES="/mnt/c/github/fifa/player/import/playernames.csv"
CSV_PLAYERS="/mnt/c/github/fifa/player/import/players.csv"

# -----------------------
# UTILITAIRES
# -----------------------
sql_escape() { printf '%s' "$1" | sed "s/'/\\\\'/g"; }
trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r'; }

get_next_nameid() {
    $MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(pn1.nameid + 1), 1)
FROM playernames pn1
LEFT JOIN playernames pn2 ON pn1.nameid + 1 = pn2.nameid
WHERE pn2.nameid IS NULL;" | tr -d '\n'
}
start=$(date +%s)
# -----------------------
# 0) Création table temporaire pour playerid CSV
# -----------------------
$MYSQL_CMD -e "
DROP TABLE IF EXISTS tmp_playerids;
CREATE TABLE tmp_playerids (playerid INT PRIMARY KEY);
LOAD DATA LOCAL INFILE '$CSV_NAMES'
INTO TABLE tmp_playerids
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(playerid);
"
echo "[LOG] Table temporaire tmp_playerids créée"

# -----------------------
# 1) SUPPRESSION MASSIVE DES PLAYERS EXISTANTS
# -----------------------
$MYSQL_CMD -e "
DELETE p
FROM players p
JOIN tmp_playerids tmp ON tmp.playerid = p.playerid;
"
echo "[LOG] Suppression massive terminée"

# -----------------------
# 2) INSERTION DE PLAYERS.CSV
# -----------------------
echo "[LOG] === INSERTION PLAYERS.CSV ==="
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_PLAYERS'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"
echo "[LOG] Insertion players.csv terminée"

# -----------------------
# 3) INSERTION DES NOUVEAUX NOMS ET AFFECTATION DES NAMEID
# -----------------------
echo "[LOG] === INSERTION DES NOMS ET MISE À JOUR DES PLAYERS ==="
while IFS=';' read -r playerid firstname lastname commonname playerjerseyname; do
    playerid=$(trim "$playerid")
    [[ -z "$playerid" ]] && continue

    # -----------------------
    # Initialisation des nameid à 0 pour éviter 'unbound variable'
    # -----------------------
    declare -A ids=( ["firstnameid"]=0 ["lastnameid"]=0 ["commonnameid"]=0 ["playerjerseynameid"]=0 )

    # Boucle sur chaque nom
    for key in firstname lastname commonname playerjerseyname; do
        NAME=$(trim "${!key}")
        [[ -z "$NAME" || "$NAME" == "NULL" ]] && continue
        NAME_ESCAPED=$(sql_escape "$NAME")

        # Vérifie si le nom existe déjà
        nameid=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME_ESCAPED' LIMIT 1;")
        if [[ -z "$nameid" ]]; then
            newid=$(get_next_nameid)
            echo "→ Insertion '$NAME' (nameid=$newid)"
            $MYSQL_CMD -e "INSERT INTO playernames (nameid,name,commentaryid) VALUES ($newid,'$NAME_ESCAPED',900000);"
            nameid=$newid
        fi
        ids["${key}id"]=$nameid
    done

    # Mise à jour des nameid dans players
    $MYSQL_CMD -e "
UPDATE players
SET firstnameid=${ids["firstnameid"]}, 
    lastnameid=${ids["lastnameid"]}, 
    commonnameid=${ids["commonnameid"]}, 
    playerjerseynameid=${ids["playerjerseynameid"]}
WHERE playerid=$playerid;
"
done < <(tail -n +2 "$CSV_NAMES")

echo "🎉 IMPORT TERMINÉ: players insérés et nameid affectés"
end=$(date +%s)
elapsed=$(( end - start ))
printf "Durée : %02d:%02d:%02d\n" \
    $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))
