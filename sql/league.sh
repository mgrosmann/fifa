#!/bin/bash
# --- Configuration ---
DB="FIFA14"
USER="root"
PASS="root"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'

read -p "Quelle ligue / championnat ? " LEAGUENAME

echo "🔎 Étape 1 : Recherche de la ligue \"$LEAGUENAME\"..."
LEAGUEID=$(mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "SELECT leagueid FROM leagues WHERE leaguename = '$LEAGUENAME';")

if [ -z "$LEAGUEID" ]; then
  echo "❌ Ligue \"$LEAGUENAME\" non trouvée."
  exit 1
fi
echo "✅ ID trouvé : $LEAGUEID"

# --- Étape 2 : Extraction des équipes appartenant à cette ligue ---
echo "🔎 Étape 2 : Récupération des équipes de la ligue..."

mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
SELECT teamid, teamname
FROM teams
WHERE leagueid = '$LEAGUEID'
ORDER BY teamname ASC;
" > teams_list.txt

NUM_TEAMS=$(wc -l < teams_list.txt)
echo "✅ $NUM_TEAMS équipes trouvées."

# --- Étape 3 : Affichage formaté ---
echo "🔎 Étape 3 : Liste des équipes du championnat \"$LEAGUENAME\" :"
echo "------------------------------------------------------------"
column -t -s $'\t' teams_list.txt
echo "------------------------------------------------------------"

echo "🏁 Terminé."
