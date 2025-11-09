#!/bin/bash

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
read -p "Nom du joueur : " player_name

# Recherche du playerid correspondant (tolérance sur le nom)
playerid=$($cmd -Nse "
SELECT p.playerid
FROM players p
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN playernames pn_common ON p.commonnameid = pn_common.nameid
WHERE CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%$player_name%'
   OR pn_common.name LIKE '%$player_name%'
LIMIT 1;
")

if [[ -z "$playerid" ]]; then
    echo "❌ Aucun joueur trouvé pour '$player_name'."
    exit 1
fi

echo "✅ Joueur trouvé : $player_name (ID : $playerid)"
echo "📊 Informations de prêt :"
echo "--------------------------------------------"

# Afficher toutes les infos de la table playerloans pour ce joueur
$cmd -t -e "
SELECT * FROM playerloans WHERE playerid = $playerid;
"

