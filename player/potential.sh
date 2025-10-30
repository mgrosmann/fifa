#!/bin/bash

# --- Configuration ---
DB="FIFA16"
USER="root"
PASS="root"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'
MIN_POTENTIAL=90  # Seuil minimal du potentiel
MIN_OVERALL=80    #seuil minimal du overall
echo "🔎 Recherche de tous les joueurs avec un potentiel ≥ $MIN_POTENTIAL..."

mysql -u"$USER" -p"$PASS" -h${MYSQL_HOST} -P${MYSQL_PORT} -D "$DB" -e "
SELECT
    CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
    p.overallrating AS overall,
    p.potential,
    t.teamname,
    p.preferredposition1
FROM players p
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
LEFT JOIN teams t ON tpl.teamid = t.teamid
WHERE p.potential >= $MIN_POTENTIAL
AND p.overallrating <= $MIN_OVERALL
ORDER BY p.potential DESC, p.overallrating DESC;
"

echo "🏁 Terminé — affichage des joueurs avec potentiel ≥ $MIN_POTENTIAL."
