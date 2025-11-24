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

MYSQL_CMD="mysql -u user -proot $DB -e"

$MYSQL_CMD "
-- 🔹 Récupérer infos du joueur
SELECT tpl.teamid, tpl.position, tpl.artificialkey, p.preferredposition1, p.preferredposition2
INTO @old_teamid, @old_pos, @old_key, @pref1, @pref2
FROM teamplayerlinks tpl
JOIN players p ON tpl.playerid = p.playerid
WHERE tpl.playerid = $PLAYERID;

-- 🔹 Libérer temporairement sa clé
UPDATE teamplayerlinks
SET artificialkey = 999999999
WHERE playerid = $PLAYERID;

-- 🔹 Promouvoir un remplaçant/réserviste si le joueur était titulaire
IF @old_pos < 28 THEN
    -- Trouver le remplaçant/réserviste compatible
    SELECT playerid INTO @promu_id
    FROM teamplayerlinks tpl
    JOIN players p ON tpl.playerid=p.playerid
    WHERE tpl.teamid=@old_teamid
      AND tpl.position IN (28,29)
      AND (p.preferredposition1=@pref1 OR p.preferredposition2=@pref1
           OR p.preferredposition1=@pref2 OR p.preferredposition2=@pref2)
    ORDER BY tpl.position ASC, tpl.artificialkey ASC
    LIMIT 1;

    -- Mettre à jour le promu avec la position et artificialkey du titulaire
    UPDATE teamplayerlinks
    SET position=@old_pos,
        artificialkey=@old_key
    WHERE playerid=@promu_id;
END IF;

-- 🔹 Décaler toutes les clés supérieures à l'ancienne clé du promu (le reste)
UPDATE teamplayerlinks
SET artificialkey = artificialkey - 1
WHERE artificialkey > @old_key
  AND teamid=@old_teamid
  AND playerid <> COALESCE(@promu_id, 0);

-- 🔹 Déterminer la nouvelle clé pour la nouvelle équipe
SELECT IFNULL(MAX(artificialkey), -1) INTO @new_key
FROM teamplayerlinks
WHERE teamid = $NEW_TEAMID;

-- 🔹 Décaler toutes les clés supérieures pour libérer le slot
UPDATE teamplayerlinks
SET artificialkey = artificialkey + 1
WHERE artificialkey > @new_key;

-- 🔹 Mettre à jour le joueur transféré
UPDATE teamplayerlinks
SET teamid = $NEW_TEAMID,
    position = 29,
    artificialkey = @new_key + 1
WHERE playerid = $PLAYERID;
"

echo "✅ Joueur $PLAYERID transféré vers l'équipe $NEW_TEAMID et artificialkey recalculée."
