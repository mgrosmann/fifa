#!/bin/bash

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA15 -N -s"
CSV_TPL="/mnt/c/github/fifa/cmtracker/import/tpl_fixed.csv"

echo "--- IMPORT TEAMPLAYERLINKS ---"

tail -n +2 "$CSV_TPL" | while IFS=';' read -r teamid playerid
do
    tpl_teamid=$(echo "$teamid" | tr -d '" ' | xargs)
    tpl_playerid=$(echo "$playerid" | tr -d '" ' | xargs)
    [[ -z "$tpl_teamid" || -z "$tpl_playerid" ]] && continue

    echo "→ Traitement joueur $tpl_playerid pour l'équipe corrigée $tpl_teamid..."

    exists_tpl=$($MYSQL_CMD --skip-column-names \
        -e "SELECT 1 FROM teamplayerlinks WHERE teamid=$tpl_teamid AND playerid=$tpl_playerid;")

    if [[ "$exists_tpl" == "1" ]]; then
        echo "   ✔ Déjà présent → ignoré"
        continue
    fi

    KEY=$($MYSQL_CMD --skip-column-names -e \
        "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")

    echo "   ↳ artificialkey assigné : $KEY"

    $MYSQL_CMD -e "
UPDATE teamplayerlinks
SET artificialkey = artificialkey + 1
WHERE artificialkey >= $KEY
  AND teamid = $tpl_teamid;
"

    number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
    ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
   AND tpl1.teamid = tpl2.teamid
WHERE tpl1.teamid = $tpl_teamid
  AND tpl2.jerseynumber IS NULL;
")

    [[ -z "$number" ]] && number=1

    echo "   ↳ Numéro attribué : $number"

    $MYSQL_CMD -e "
INSERT INTO teamplayerlinks
(teamid, playerid, artificialkey, leaguegoals, isamongtopscorers, yellows,
 isamongtopscorersinteam, injury, leagueappearances, prevform, form,
 istopscorer, reds, position, jerseynumber)
VALUES ($tpl_teamid, $tpl_playerid, $KEY,0,0,0,0,0,0,0,3,0,0,29,$number);
"

    echo "   ✔ Insertion OK"

done

echo "--- FIN TEAMPLAYERLINKS ---"
