#!/bin/bash
# --- Configuration ---
DB="FIFA14"
USER="root"
PASS="root"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'

# --- Liste des ligues disponibles ---
LEAGUES=(
  "England Premier League (1)"
  "England League Championship (2)"
  "France Ligue 1 (1)"
  "France Ligue 2 (2)"
  "Germany 1. Bundesliga (1)"
  "Italy Serie A (1)"
  "Spain Primera Division (1)"
)

# --- Étape 1 : Sélection de la ligue ---
echo "🌍 Sélectionne une ligue dans la liste ci-dessous :"
echo "--------------------------------------------------"
i=1
for league in "${LEAGUES[@]}"; do
  echo "$i) $league"
  ((i++))
done
echo "--------------------------------------------------"

read -p "👉 Entrez le numéro de la ligue : " choice

# Validation du choix
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#LEAGUES[@]} ]; then
  echo "❌ Choix invalide."
  exit 1
fi

LEAGUENAME="${LEAGUES[$((choice-1))]}"
echo ""
echo "🔎 Étape 1 : Recherche de la ligue \"$LEAGUENAME\"..."

# --- Nettoyage du nom (au cas où) ---
LEAGUENAME=$(echo "$LEAGUENAME" | tr -d '\r')

# --- Recherche de l'ID de la ligue ---
LEAGUEID=$(mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB \
  -e "SELECT leagueid FROM leagues WHERE TRIM(LOWER(leaguename)) = TRIM(LOWER('$LEAGUENAME'));" )

if [ -z "$LEAGUEID" ]; then
  echo "❌ Ligue \"$LEAGUENAME\" non trouvée dans la base $DB."
  exit 1
fi

echo "✅ ID trouvé : $LEAGUEID"
echo ""

# --- Étape 2 : Extraction des équipes appartenant à cette ligue ---
echo "🔎 Étape 2 : Récupération des équipes de la ligue \"$LEAGUENAME\"..."

mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
SELECT 
    t.teamid AS 'ID',
    t.teamname AS 'Nom de l’équipe'
FROM teams t
INNER JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.leagueid = $LEAGUEID
ORDER BY t.teamname ASC;
"

echo ""
echo "🏁 Terminé."
