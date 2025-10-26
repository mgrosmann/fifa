#!/bin/bash

DB_NAME="FIFA15"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

echo "🔍 Recherche des prêts avec loandateend inconnu..."
echo "-----------------------------------------------"

mysql -u "$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D "$DB_NAME" -e "
SELECT p.playerid, 
       CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
       pl.loandateend,
       IFNULL(t.teamname, 'Inconnu') AS teamname
FROM playerloans pl
LEFT JOIN players p ON pl.playerid = p.playerid
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last ON p.lastnameid = pn_last.nameid
LEFT JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
LEFT JOIN teams t ON tpl.teamid = t.teamid
WHERE pl.loandateend NOT IN (
    157499,
    157679,
    157864,
    158044,
    158229,
    158410,
    158595,
    158775,
    158960,
    159140,
    159325,
    159505,
    159690,
    159871,
    160236,
    160421,
    160601,
    160786,
    160966,
    161151,
    161332,
    161517,
    161697,
    161882,
    162062
)
ORDER BY pl.loandateend;
"
