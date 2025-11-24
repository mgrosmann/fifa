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

-- 🔹 Déterminer le joueur à promouvoir
SET @promu_id = NULL;

-- Cas titulaire
IF @old_pos < 28 THEN
    SELECT playerid INTO @promu_id
    FROM teamplayerlinks tpl
    JOIN players p ON tpl.playerid=p.playerid
    WHERE tpl.teamid=@old_teamid
      AND tpl.position IN (28,29)
      AND (p.preferredposition1=@pref1 OR p.preferredposition2=@pref1
           OR p.preferredposition1=@pref2 OR p.preferredposition2=@pref2)
    ORDER BY tpl.position ASC, tpl.artificialkey ASC
    LIMIT 1;

    -- Si aucun trouvé, prendre n'importe quel remplaçant/réserviste
    IF @promu_id IS NULL THEN
        SELECT playerid INTO @promu_id
        FROM teamplayerlinks
        WHERE teamid=@old_teamid AND position IN (28,29)
        ORDER BY position ASC, artificialkey ASC
        LIMIT 1;
    END IF;
END IF;

-- Cas remplaçant (28)
IF @old_pos = 28 AND @promu_id IS NULL THEN
    SELECT playerid INTO @promu_id
    FROM teamplayerlinks
    WHERE teamid=@old_teamid AND position=29
    ORDER BY artificialkey ASC
    LIMIT 1;
END IF;

-- 🔹 Sauvegarder l'ancienne clé du promu avant modification
SET @promu_old_key = NULL;
IF @promu_id IS NOT NULL THEN
    SELECT artificialkey INTO @promu_old_key
    FROM teamplayerlinks
    WHERE playerid=@promu_id;

    -- 🔹 Mettre à jour le promu avec la position et la clé du joueur transféré
    UPDATE teamplayerlinks
    SET position=@old_pos,
        artificialkey=@old_key
    WHERE playerid=@promu_id;
END IF;

-- 🔹 Déterminer la clé de référence pour le décalage
SET @key_to_shift = COALESCE(@promu_old_key, @old_key);


-- 🔹 Décaler toutes les clés supérieures à la clé de référence dans l'équipe d'origine
UPDATE teamplayerlinks
SET artificialkey = artificialkey - 1
WHERE artificialkey > @key_to_shift
  AND teamid=@old_teamid
  AND playerid <> COALESCE(@promu_id, 0);

-- 🔹 Déterminer la nouvelle clé pour la nouvelle équipe
SELECT IFNULL(MAX(artificialkey), -1) INTO @max_new_teamid
FROM teamplayerlinks
WHERE teamid = $NEW_TEAMID;

-- 🔹 Décaler toutes les clés supérieures pour libérer le slot
UPDATE teamplayerlinks
SET artificialkey = artificialkey + 1
WHERE artificialkey > @max_new_teamid;

-- 🔹 Mettre à jour le joueur transféré
UPDATE teamplayerlinks
SET teamid = $NEW_TEAMID,
    position = 29,
    artificialkey = @max_new_teamid + 1
WHERE playerid = $PLAYERID;
"

echo "✅ Joueur $PLAYERID transféré vers l'équipe $NEW_TEAMID et artificialkey recalculée."
