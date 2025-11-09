#!/usr/bin/env bash
# Script de prêt d’un joueur vers un autre club
# Utilisation : ./loan_player.sh

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
read -p "Nom du joueur à prêter : " search_name

# Récupération du playerid
playerid=$($cmd -Nse "
SELECT playerid FROM players p
JOIN playernames n1 ON p.firstnameid = n1.nameid
JOIN playernames n2 ON p.lastnameid = n2.nameid
WHERE CONCAT(n1.name, ' ', n2.name) LIKE '%$search_name%'
LIMIT 1;
")

if [[ -z "$playerid" ]]; then
  echo "❌ Joueur '$search_name' introuvable."
  exit 1
fi

# Trouver le club actuel
current_team=$($cmd -Nse "
SELECT teamid FROM teamplayerlinks WHERE playerid=$playerid LIMIT 1;
")

current_team_name=$($cmd -Nse "
SELECT teamname FROM teams WHERE teamid=$current_team LIMIT 1;
")

echo "ℹ️  Club actuel : $current_team_name ($current_team)"

# 🔹 On demande le nom du club de prêt (pas son ID)
read -p "Nom du club où le joueur part en prêt : " loan_team_name

# Récupérer l’ID du club à partir du nom
loan_team=$($cmd -Nse "
SELECT teamid FROM teams WHERE teamname LIKE '%$loan_team_name%' LIMIT 1;
")

if [[ -z "$loan_team" ]]; then
  echo "❌ Club '$loan_team_name' introuvable."
  exit 1
fi

# Vérif pour éviter un auto-prêt
if [[ "$loan_team" == "$current_team" ]]; then
  echo "⚠️  Impossible de prêter un joueur à son propre club."
  exit 1
fi

read -p "Date de fin du prêt (ex: 30/06/2025) : " end_date

# Convertir la date en loandateend
loandateend=$(./convert_loandate.sh id "$end_date")

if [[ -z "$loandateend" ]]; then
  echo "❌ Erreur de conversion de la date."
  exit 1
fi

# Mettre à jour le club du joueur (le prêter)
$cmd -e "
UPDATE teamplayerlinks SET teamid=$loan_team, position=29  WHERE playerid=$playerid;
"

# Ajouter le prêt dans playerloans
$cmd -e "
INSERT INTO playerloans (teamidloanedfrom, playerid, loandateend)
VALUES ($current_team, $playerid, $loandateend);
"

loan_team_name_real=$($cmd -Nse "
SELECT teamname FROM teams WHERE teamid=$loan_team LIMIT 1;
")

echo "✅ $search_name prêté de '$current_team_name' à '$loan_team_name_real' jusqu’au $end_date (loandateend=$loandateend)"