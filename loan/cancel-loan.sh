#!/usr/bin/env bash
# Annule le prêt d’un joueur et le renvoie dans son club d’origine

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
read -p "Nom du joueur à rapatrier : " search_name

# Trouver l'ID du joueur
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

# Trouver l'équipe d'origine du prêt
loanedfrom=$($cmd -Nse "
SELECT teamidloanedfrom FROM playerloans WHERE playerid=$playerid LIMIT 1;
")

if [[ -z "$loanedfrom" ]]; then
  echo "❌ Ce joueur n'a pas de prêt actif."
  exit 1
fi

# Trouver le nom du club d'origine (optionnel)
clubname=$($cmd -Nse "
SELECT teamname FROM teams WHERE teamid=$loanedfrom LIMIT 1;
")

# Mise à jour de teamplayerlinks
$cmd -e "
UPDATE teamplayerlinks SET teamid=$loanedfrom, position=29 WHERE playerid=$playerid;
"

# Suppression de la ligne dans playerloans
$cmd -e "
DELETE FROM playerloans WHERE playerid=$playerid;
"

echo "✅ Joueur '$search_name' renvoyé à son club d'origine : $clubname (teamid=$loanedfrom)"