#!/bin/bash
# key.sh
# Usage: ./key.sh <playerid> <new_teamid> <db_name>

PLAYERID=$1
NEW_TEAMID=$2
DB=$3

if [[ -z "$PLAYERID" || -z "$NEW_TEAMID" || -z "$DB" ]]; then
    echo "Usage: $0 <playerid> <new_teamid> <db_name>"
    exit 1
fi

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 $DB -s -N -e"

# Exclusion pour équipes spéciales / nationales
EXCLUDE_CONDITION="(t.teamname LIKE '%All star%' OR t.teamname LIKE '%Adidas%' OR t.teamname LIKE '%Nike%' OR t.teamname LIKE '% xi%' OR t.teamname LIKE '%allstar%' OR ltl.leagueid = 78)"

# 🔹 Récupérer les infos du joueur
read old_teamid old_pos old_key pref1 pref2 <<< $($MYSQL_CMD "
SELECT tpl.teamid, tpl.position, tpl.artificialkey, p.preferredposition1, p.preferredposition2
FROM teamplayerlinks_copy tpl
JOIN players p ON tpl.playerid = p.playerid
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE tpl.playerid=$PLAYERID
  AND NOT $EXCLUDE_CONDITION
LIMIT 1;
")

echo "Joueur $PLAYERID : team=$old_teamid, pos=$old_pos, key=$old_key, pref1=$pref1, pref2=$pref2"

# 🔹 Libérer temporairement sa clé
$MYSQL_CMD "UPDATE teamplayerlinks_copy SET artificialkey=999999999 WHERE playerid=$PLAYERID;"

# 🔹 Déterminer le joueur à promouvoir
promu_id=""

if [[ "$old_pos" -lt 28 ]]; then
    # titulaire : chercher remplaçant correspondant aux positions préférées
    promu_id=$($MYSQL_CMD "
    SELECT tpl.playerid
    FROM teamplayerlinks_copy tpl
    JOIN players p ON tpl.playerid=p.playerid
    WHERE tpl.teamid=$old_teamid
      AND tpl.position IN (28,29)
      AND (p.preferredposition1=$pref1)
    ORDER BY tpl.position ASC, tpl.artificialkey ASC
    LIMIT 1;
    ")

    # si aucun trouvé, prendre n'importe quel remplaçant
    if [[ -z "$promu_id" ]]; then
        promu_id=$($MYSQL_CMD "
        SELECT playerid
        FROM teamplayerlinks_copy
        WHERE teamid=$old_teamid AND position IN (28,29)
        ORDER BY position ASC, artificialkey ASC
        LIMIT 1;
        ")
    fi
elif [[ "$old_pos" -eq 28 ]]; then
    # remplaçant : chercher réserviste
    promu_id=$($MYSQL_CMD "
    SELECT playerid
    FROM teamplayerlinks_copy
    WHERE teamid=$old_teamid AND position=29
    ORDER BY artificialkey ASC
    LIMIT 1;
    ")
fi

echo "Joueur promu : $promu_id"

# 🔹 Sauvegarder clé du promu et mettre à jour sa position
if [[ -n "$promu_id" ]]; then
    promu_old_key=$($MYSQL_CMD "SELECT tpl.artificialkey FROM teamplayerlinks_copy tpl
    JOIN teams t ON tpl.teamid = t.teamid
    JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid WHERE playerid=$promu_id AND NOT $EXCLUDE_CONDITION;")
    $MYSQL_CMD "UPDATE teamplayerlinks_copy SET position=$old_pos, artificialkey=$old_key WHERE playerid=$promu_id;"
else
    promu_old_key="0"
fi

# 🔹 Déterminer la clé de référence pour le décalage
if [[ "$promu_old_key" == "0" ]]; then
    key_to_shift="$old_key"
    echo "pas de promu, la clé: $old_key"
else
    key_to_shift="$promu_old_key"
    echo "promu trouvé, la clé : $promu_old_key"
fi

echo "Clé de référence pour décalage : $key_to_shift"

# 🔹 Décaler clés supérieures dans l'équipe d'origine
$MYSQL_CMD "
UPDATE teamplayerlinks_copy
SET artificialkey = artificialkey - 1
WHERE artificialkey > $key_to_shift;
"

# 🔹 Déterminer nouvelle clé pour la nouvelle équipe
max_new_key=$($MYSQL_CMD "SELECT IFNULL(MAX(artificialkey), -1) FROM teamplayerlinks_copy WHERE teamid=$NEW_TEAMID;")

# 🔹 Décaler clés supérieures pour libérer le slot
$MYSQL_CMD "
UPDATE teamplayerlinks_copy
SET artificialkey = artificialkey + 1
WHERE artificialkey > $max_new_key;
"

# 🔹 Mettre à jour le joueur transféré
$MYSQL_CMD "
UPDATE teamplayerlinks_copy tpl
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
SET tpl.teamid=$NEW_TEAMID,
    tpl.position=29,
    tpl.artificialkey=$((max_new_key + 1))
    jerseynumber = (
    SELECT MIN(t.jerseynumber + 1)
    FROM teamplayerlinks t
    LEFT JOIN teamplayerlinks t2
      ON t2.teamid = t.teamid
     AND t2.jerseynumber = t.jerseynumber + 1
    WHERE t.teamid = $NEW_TEAMID
      AND t2.jerseynumber IS NULL
)
WHERE playerid=$PLAYERID AND NOT $EXCLUDE_CONDITION;
"

echo "✅ Joueur $PLAYERID transféré vers l'équipe $NEW_TEAMID et artificialkey recalculée."
