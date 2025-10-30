#!/bin/bash
# ==========================================================
#  Script : fix-league.sh
#  But : Vérifier et corriger le nombre d'équipes par championnat
#        (ajoute automatiquement une équipe libre si manque)
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

# --- Boucle principale ---
echo "⚽ Vérification du nombre d’équipes par championnat"
echo "----------------------------------------------------"

for leagueid in "${!EXPECTED_COUNTS[@]}"; do
  expected=${EXPECTED_COUNTS[$leagueid]}
  name=${LEAGUE_NAMES[$leagueid]}

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
      # Cherche une équipe libre (non liée à un championnat)
      free_team=$(mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
        SELECT t.teamid, t.teamname
        FROM teams t
        LEFT JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
        WHERE ltl.teamid IS NULL
        ORDER BY t.teamid ASC
        LIMIT 1;
      ")

      if [ -n "$free_team" ]; then
        free_id=$(echo "$free_team" | awk '{print $1}')
        free_name=$(echo "$free_team" | cut -d' ' -f2-)
        echo "✨ Équipe libre trouvée : $free_name (ID $free_id)"
        mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
          INSERT IGNORE INTO leagueteamlinks (leagueid, teamid) VALUES ($leagueid, $free_id);
        "
        echo "➕ Équipe '$free_name' ajoutée à $name."
      else
        echo "❌ Aucune équipe libre trouvée. Veuillez créer une équipe manuellement."
        read -p "👉 Entrez le teamid à ajouter : " addid
        read -p "👉 Nom de l’équipe : " teamname
        mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
          INSERT INTO teams (teamid, teamname) VALUES ($addid, '$teamname');
          INSERT INTO leagueteamlinks (leagueid, teamid) VALUES ($leagueid, $addid);
        "
        echo "✅ Équipe '$teamname' (ID $addid) créée et ajoutée à $name."
      fi
    done
  fi
done

echo "----------------------------------------------------"
echo "🏁 Vérification et correction terminées."
