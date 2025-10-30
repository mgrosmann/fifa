#!/bin/bash
# ==========================================================
#  Script : fix-league.sh
#  But : Vérifier et corriger le nombre d'équipes par championnat
# ==========================================================

# --- Configuration MySQL ---
DB="FIFA15"
USER="root"
PASS="root"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'

# --- Configuration attendue ---
declare -A EXPECTED_COUNTS=(
  [13]=20   # England Premier League
  [14]=24   # England Championship
  [60]=24   # England League One
  [61]=24   # England League Two
  [16]=20   # France Ligue 1
  [17]=20   # France Ligue 2
  [19]=18   # Germany Bundesliga
  [20]=18   # Germany 2. Bundesliga
  [31]=20   # Italy Serie A
  [32]=22   # Italy Serie B
  [53]=20   # Spain Primera Division
  [54]=22   # Spain Segunda A
)

declare -A LEAGUE_NAMES=(
  [13]="England Premier League"
  [14]="England Championship"
  [60]="England League One"
  [61]="England League Two"
  [16]="France Ligue 1"
  [17]="France Ligue 2"
  [19]="Germany Bundesliga"
  [20]="Germany 2. Bundesliga"
  [31]="Italy Serie A"
  [32]="Italy Serie B"
  [53]="Spain Primera Division"
  [54]="Spain Segunda A"
)

declare -A COUNTRY_IDS=(
  [13]=14  # England
  [14]=14
  [60]=14
  [61]=14
  [16]=17  # France
  [17]=17
  [19]=19  # Germany
  [20]=19
  [31]=27  # Italy
  [32]=27
  [53]=45  # Spain
  [54]=45
)

# --- Boucle principale ---
echo "⚽ Vérification du nombre d’équipes par championnat"
echo "----------------------------------------------------"

for leagueid in "${!EXPECTED_COUNTS[@]}"; do
  expected=${EXPECTED_COUNTS[$leagueid]}
  name=${LEAGUE_NAMES[$leagueid]}

  # Récupération du nombre d’équipes
  count=$(mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
    SELECT COUNT(*) FROM leagueteamlinks WHERE leagueid = $leagueid;
  ")

  if [ -z "$count" ]; then
    echo "❌ Erreur : impossible de récupérer le nombre d’équipes pour la ligue $leagueid"
    continue
  fi

  diff=$((count - expected))

  if [ $diff -eq 0 ]; then
    echo "✅ $name ($leagueid) : $count équipes (OK)"
  elif [ $diff -gt 0 ]; then
    echo "⚠️ $name ($leagueid) : $count équipes, $diff en trop."
    echo "Liste des équipes :"
    mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
      SELECT t.teamid, t.teamname 
      FROM teams t 
      INNER JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid 
      WHERE ltl.leagueid = $leagueid
      ORDER BY t.teamname ASC;
    "
    for ((i=1; i<=diff; i++)); do
      read -p "👉 Entrez l'ID de l’équipe à supprimer : " delid
      mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
        DELETE FROM leagueteamlinks WHERE teamid = $delid AND leagueid = $leagueid;
      "
      echo "🗑️ Équipe $delid supprimée de $name."
    done
  else
    absdiff=$((expected - count))
    echo "⚠️ $name ($leagueid) : $count équipes, $absdiff manquante(s)."
    for ((i=1; i<=absdiff; i++)); do
      read -p "👉 Entrez le teamid à ajouter à $name : " addid
      # Vérifie si l’équipe existe déjà
      exists=$(mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
        SELECT COUNT(*) FROM teams WHERE teamid = $addid;
      ")
      if [ "$exists" -eq 0 ]; then
        echo "⚙️ L’équipe $addid n’existe pas. Création..."
        read -p "👉 Nom de l’équipe : " teamname
        countryid=${COUNTRY_IDS[$leagueid]}
        mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
          INSERT INTO teams (teamid, teamname, countryid) VALUES ($addid, '$teamname', $countryid);
        "
        echo "✅ Équipe '$teamname' (ID $addid) créée avec countryid=$countryid."
      fi
      # Ajout au lien league-team
      mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
        INSERT IGNORE INTO leagueteamlinks (leagueid, teamid) VALUES ($leagueid, $addid);
      "
      echo "➕ Équipe $addid ajoutée à $name."
    done
  fi
done

echo "----------------------------------------------------"
echo "🏁 Vérification et correction terminées."
