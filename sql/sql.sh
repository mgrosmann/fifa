#!/bin/bash

# --- Configuration ---
DB="FIFA14"
USER="root"
PASS="root"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'
read -p "Quel équipe ? " TEAMNAME

echo "🔎 Étape 1 : Recherche de l'équipe \"$TEAMNAME\"..."
TEAMID=$(mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "SELECT teamid FROM teams WHERE teamname = '$TEAMNAME';")

if [ -z "$TEAMID" ]; then
  echo "❌ Équipe \"$TEAMNAME\" non trouvée."
  exit 1
fi
echo "✅ ID trouvé : $TEAMID"

# --- Étape 2 : Extraction des PlayerIDs ---
echo "🔎 Étape 2 : Récupération des joueurs de l'équipe..."
mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "SELECT playerid FROM teamplayerlinks WHERE teamid = '$TEAMID';" > player_ids.txt

NUM_PLAYERS=$(wc -l < player_ids.txt)
echo "✅ $NUM_PLAYERS joueurs trouvés."

# --- Étape 3 : Affichage des infos détaillées ---
echo "🔎 Étape 3 : Récupération des informations joueurs..."

# On convertit la liste en CSV pour le IN (...)
PLAYER_IDS=$(tr '\n' ',' < player_ids.txt | sed 's/,$//')

mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -D $DB -e "
SELECT 
    p.playerid,
    CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
    p.overallrating,
    p.potential
FROM players p
INNER JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
INNER JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
WHERE p.playerid IN ($PLAYER_IDS)
#ORDER BY p.preferredposition1;
ORDER BY p.potential DESC;
"

echo "🏁 Terminé."
