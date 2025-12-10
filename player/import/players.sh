#!/bin/bash
set -euo pipefail

# -----------------------
# CONFIG
# -----------------------
MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA1518 -N -s"
CSV_NAMES="/mnt/c/github/fifa/player/import/playernames.csv"
CSV_PLAYERS="/mnt/c/github/fifa/player/import/players.csv"
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

# 1) INSERT PLAYERNAMES
# -----------------------
echo "[LOG] === INSERTION DES NOMS DANS playernames ==="
while IFS=';' read -r playerid firstname lastname commonname playerjerseyname; do
    for raw in "$firstname" "$lastname" "$commonname" "$playerjerseyname"; do
        NAME=$(trim "$raw")
        [[ -z "$NAME" || "$NAME" == "NULL" ]] && continue
        NAME_ESCAPED=$(sql_escape "$NAME")
        exists=$($MYSQL_CMD --skip-column-names -e "SELECT nameid FROM playernames WHERE name='$NAME_ESCAPED' LIMIT 1;")
        if [[ -z "$exists" ]]; then
            newid=$(get_next_nameid)
            echo "→ Insertion '$NAME' (nameid=$newid)"
            $MYSQL_CMD -e "INSERT INTO playernames (nameid,name,commentaryid) VALUES ($newid,'$NAME_ESCAPED',900000);"
        fi
    done
done < <(tail -n +2 "$CSV_NAMES")

# -----------------------
# 2) SUPPRESSION JOUEURS EXISTANTS
# -----------------------
echo "[LOG] === SUPPRESSION DES JOUEURS ==="
while IFS=';' read -r playerid _; do
    playerid=$(trim "$playerid")
    [[ -z "$playerid" ]] && continue
    echo "→ Suppression playerid=$playerid"
    $MYSQL_CMD -e "DELETE FROM players WHERE playerid=$playerid;"
done < <(tail -n +2 "$CSV_NAMES")

# -----------------------
# 3) LOAD PLAYERS
# -----------------------
echo "[LOG] === CHARGEMENT PLAYERS.CSV ==="
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_PLAYERS'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;"

# -----------------------
# 4) UPDATE NAMEID
# -----------------------
echo "[LOG] === MISE À JOUR NAMEID ==="
while IFS=';' read -r playerid firstname lastname commonname playerjerseyname; do
    playerid=$(trim "$playerid"); [[ -z "$playerid" ]] && continue
    firstnameid=0; lastnameid=0; commonnameid=0; playerjerseynameid=0

    [[ "$firstname" != "NULL" ]] && firstnameid=$($MYSQL_CMD --skip-column-names -e "SELECT COALESCE((SELECT nameid FROM playernames WHERE name='$(sql_escape "$firstname")' LIMIT 1),0);")
    [[ "$lastname" != "NULL" ]] && lastnameid=$($MYSQL_CMD --skip-column-names -e "SELECT COALESCE((SELECT nameid FROM playernames WHERE name='$(sql_escape "$lastname")' LIMIT 1),0);")
    [[ "$commonname" != "NULL" && -n "$commonname" ]] && commonnameid=$($MYSQL_CMD --skip-column-names -e "SELECT COALESCE((SELECT nameid FROM playernames WHERE name='$(sql_escape "$commonname")' LIMIT 1),0);")
    [[ "$playerjerseyname" != "NULL" && -n "$playerjerseyname" ]] && playerjerseynameid=$($MYSQL_CMD --skip-column-names -e "SELECT COALESCE((SELECT nameid FROM playernames WHERE name='$(sql_escape "$playerjerseyname")' LIMIT 1),0);")

    echo "→ UPDATE playerid=$playerid firstnameid=$firstnameid lastnameid=$lastnameid commonnameid=$commonnameid playerjerseynameid=$playerjerseynameid"
    $MYSQL_CMD -e "UPDATE players SET firstnameid=$firstnameid,lastnameid=$lastnameid,commonnameid=$commonnameid,playerjerseynameid=$playerjerseynameid WHERE playerid=$playerid;"
done < <(tail -n +2 "$CSV_NAMES")