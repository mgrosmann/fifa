#!/bin/bash
DB="FIFA15"
USER="root"
PASS="root"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'

LEAGUE_IDS=(13 14 60 61 16 17 19 20 31 32 53 54)

echo "⚽️ Comptage du nombre d'équipes par championnat"
echo "----------------------------------------------------"

for id in "${LEAGUE_IDS[@]}"; do
  result=$(mysql -u$USER -p$PASS -h${MYSQL_HOST} -P${MYSQL_PORT} -N -D $DB -e "
    SELECT 
      CONCAT(l.leaguename, ' (', l.leagueid, ') : ', COUNT(t.teamid), ' équipes')
    FROM teams t
    INNER JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
    INNER JOIN leagues l ON l.leagueid = ltl.leagueid
    WHERE l.leagueid = $id
    GROUP BY l.leagueid, l.leaguename;
  ")

  if [ -z "$result" ]; then
    echo "❌ Aucune donnée pour leagueid $id"
  else
    echo "✅ $result"
  fi
done

echo "----------------------------------------------------"
echo "�� Terminé."

