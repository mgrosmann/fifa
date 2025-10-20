#!/bin/bash
# --- Configuration ---
DB="FIFA14"
USER="root"
PASS="root"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'

# --- Liste des ligues disponibles (avec leagueid) ---
declare -A LEAGUES=(
  [13]="Premier League"
  [14]="Championship"
  [60]="League One"
  [61]="League Two"
  [16]="Ligue 1"
  [17]="Ligue 2"
  [19]="Bundesliga"
  [20]="Bundesliga 2"
  [31]="Serie A"
  [32]="Serie B"
  [53]="Liga BBVA"
  [54]="Liga Aldente"
)

# --- Étape 1 : Sélection de la ligue ---
echo "🌍 Sélectionne une ligue dans la liste ci-dessous :"
echo "--------------------------------------------------"
i=1
IDS=()
for id in "${!LEAGUES[@]}"; do
  IDS+=("$id")
done
# Affichage trié par ordre croissant des leagueid
IFS=$'\n' sorted_ids=($(sort -n <<<"${IDS[*]}"))
unset IFS

i=1
for id in "${sorted_ids[@]}"; do
  echo "$i) ${LEAGUES[$id]} (ID: $id)"
  ((i++))
done
echo "--------------------------------------------------"

read -p "👉 Entrez le numéro de la ligue : " choice

# Validation du choix
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#sorted_ids[@]} ]; then
  echo "❌ Choix invalide."
  exit 1
fi

LEAGUEID="${sorted_ids[$((choice-1))]}"
LEAGUENAME="${LEAGUES[$LEAGUEID]}"

echo ""
echo "🔎 Étape 1 : Recherche de la ligue \"$LEAGUENAME\" (ID: $LEAGUEID)..."
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

