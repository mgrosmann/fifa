#!/bin/bash

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC26 -N -s"

# Chemin CSV
CSV_TPL="/mnt/c/github/fifa/cmtracker/teamplayerlinks.csv"

echo "--- TEAMPLAYERLINKS ---"

# Lire CSV en ignorant la première ligne
tail -n +2 "$CSV_TPL" | while IFS=';' read -r teamid playerid jerseynumber position
do
    # Nettoyer les variables (supprimer guillemets, espaces)
    tpl_teamid=$(echo "$teamid" | tr -d '" ' | xargs)
    tpl_playerid=$(echo "$playerid" | tr -d '" ' | xargs)

    # Vérification basique
    if [ -z "$tpl_teamid" ] || [ -z "$tpl_playerid" ] || ! [[ "$tpl_teamid" =~ ^[0-9]+$ ]]; then
        echo "Ligne ignorée : teamid ou playerid invalide (teamid='$tpl_teamid', playerid='$tpl_playerid')"
        continue
    fi

    echo "Traitement : teamid=$tpl_teamid, playerid=$tpl_playerid"

    # Générer une clé unique pour cette équipe
    KEY=$($MYSQL_CMD --skip-column-names -e "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")
    [ -z "$KEY" ] && KEY=1

    # Trouver le prochain numéro de maillot libre
    number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
    ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
   AND tpl1.teamid = tpl2.teamid
WHERE tpl1.teamid = $tpl_teamid
  AND tpl2.jerseynumber IS NULL;
" | tr -d '\n')

    [ -z "$number" ] && number=1

    # Insérer ou mettre à jour
    $MYSQL_CMD -e "
INSERT INTO teamplayerlinks
(teamid, playerid, artificialkey, leaguegoals, isamongtopscorers, yellows,
 isamongtopscorersinteam, injury, leagueappearances, prevform, form,
 istopscorer, reds, position, jerseynumber)
VALUES ($tpl_teamid, $tpl_playerid, $KEY,0,0,0,0,0,0,0,3,0,0,29,$number)
ON DUPLICATE KEY UPDATE artificialkey=$KEY;
"

done

echo "--- FIN TEAMPLAYERLINKS ---"
