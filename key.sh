#!/bin/bash
# artificialkey.sh
# Usage: ./artificialkey.sh <playerid> <new_teamid>

PLAYERID=$1
NEW_TEAMID=$2
DB=$3

# Vérification des paramètres
if [[ -z "$PLAYERID" || -z "$NEW_TEAMID" ]]; then
    echo "Usage: $0 <playerid> <new_teamid>"
    exit 1
fi

# Commande MySQL, à adapter si nécessaire (utilisateur, mot de passe, base)
MYSQL_CMD="mysql -u user -proot $DB -e"

# Exécution des requêtes SQL pour gérer l'artificialkey
$MYSQL_CMD "
-- 1️⃣ Récupérer l'artificialkey actuelle du joueur
SELECT artificialkey INTO @old_key
FROM teamplayerlinks
WHERE playerid = $PLAYERID;

-- 2️⃣ Libérer la clé du joueur temporairement
UPDATE teamplayerlinks
SET artificialkey = 999999999
WHERE playerid = $PLAYERID;

-- 3️⃣ Décaler toutes les clés supérieures à l'ancienne clé (-1) dans l'équipe d'origine
UPDATE teamplayerlinks
SET artificialkey = artificialkey - 1
WHERE artificialkey > @old_key;

-- 4️⃣ Déterminer le maximum des artificialkey de la nouvelle équipe
SELECT IFNULL(MAX(artificialkey), -1) INTO @new_key
FROM teamplayerlinks
WHERE teamid = $NEW_TEAMID;

-- 5️⃣ Décaler toutes les clés supérieures à @new_key pour libérer le slot
UPDATE teamplayerlinks
SET artificialkey = artificialkey + 1
WHERE artificialkey > @new_key;

-- 6️⃣ Mettre à jour le joueur avec sa nouvelle équipe et la clé libérée
UPDATE teamplayerlinks
SET teamid = $NEW_TEAMID,
    position = 29,
    artificialkey = @new_key + 1
WHERE playerid = $PLAYERID;
"

echo "✅ Transfert du joueur $PLAYERID vers l'équipe $NEW_TEAMID effectué."
