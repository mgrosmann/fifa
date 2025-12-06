#!/bin/bash
set -e

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA15 -N -s"
CSV_TPL="/mnt/c/github/fifa/player/import/teamplayerlinks.csv"

# Liste des équipes autorisées (jerseynumber fixe)
AUTH_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374"
FREE_AGENT=111592

echo "🚨 Libération des joueurs PL / clubs majeurs (mise à FREE_AGENT)..."
$MYSQL_CMD -e "
UPDATE teamplayerlinks tpl
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
SET tpl.teamid=$FREE_AGENT
WHERE ltl.leagueid=13 OR tpl.teamid IN ($AUTH_TEAMS);
"

echo "--- IMPORT TEAMPLAYERLINKS ---"

tail -n +2 "$CSV_TPL" | while IFS=';' read -r leaguegoals isamongtopscorers yellows isamongtopscorersinteam jerseynumber \
    position artificialkey teamid injury leagueappearances prevform istopscorer playerid form reds
do
    tpl_teamid=$(echo "$teamid" | tr -d '" ' | xargs)
    tpl_playerid=$(echo "$playerid" | tr -d '" ' | xargs)
    [[ -z "$tpl_teamid" || -z "$tpl_playerid" ]] && continue

    # Vérifier si le joueur existe déjà dans cette équipe
    exists_tpl=$($MYSQL_CMD --skip-column-names -e "
        SELECT 1 FROM teamplayerlinks WHERE teamid=$tpl_teamid AND playerid=$tpl_playerid;
    ")

    if [[ "$exists_tpl" == "1" ]]; then
        # Mise à jour des stats
        $MYSQL_CMD -e "
UPDATE teamplayerlinks
SET leaguegoals=$leaguegoals,
    isamongtopscorers=$isamongtopscorers,
    yellows=$yellows,
    isamongtopscorersinteam=$isamongtopscorersinteam,
    position=$position,
    injury=$injury,
    leagueappearances=$leagueappearances,
    prevform=$prevform,
    istopscorer=$istopscorer,
    form=$form,
    reds=$reds
WHERE teamid=$tpl_teamid AND playerid=$tpl_playerid;
        "
        echo "✔ Player $tpl_playerid mis à jour pour team $tpl_teamid"

        # Recalcul du jersey si équipe non autorisée
        if ! [[ ",$AUTH_TEAMS," =~ ",$tpl_teamid," ]]; then
            number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
    ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
   AND tpl1.teamid = $tpl_teamid
WHERE tpl1.teamid = $tpl_teamid
  AND tpl2.jerseynumber IS NULL;
            ")
            [[ -z "$number" ]] && number=1
            $MYSQL_CMD -e "
UPDATE teamplayerlinks
SET jerseynumber=$number
WHERE teamid=$tpl_teamid AND playerid=$tpl_playerid;
            "
            echo "↳ Jerseynumber recalculé : $number"
        fi

        continue
    fi

    # Ajouter un nouveau joueur
    KEY=$($MYSQL_CMD --skip-column-names -e "
SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;
    ")

    # Calcul du jerseynumber
    if [[ ",$AUTH_TEAMS," =~ ",$tpl_teamid," ]]; then
        number=$jerseynumber
    else
        number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
    ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
   AND tpl1.teamid = $tpl_teamid
WHERE tpl1.teamid = $tpl_teamid
  AND tpl2.jerseynumber IS NULL;
        ")
        [[ -z "$number" ]] && number=1
    fi

    $MYSQL_CMD -e "
INSERT INTO teamplayerlinks
(teamid, playerid, artificialkey, leaguegoals, isamongtopscorers, yellows,
 isamongtopscorersinteam, injury, leagueappearances, prevform, form,
 istopscorer, reds, position, jerseynumber)
VALUES
($tpl_teamid, $tpl_playerid, $KEY, $leaguegoals, $isamongtopscorers, $yellows,
 $isamongtopscorersinteam, $injury, $leagueappearances, $prevform, $form,
 $istopscorer, $reds, $position, $number);
    "
    echo "✔ Player $tpl_playerid ajouté pour team $tpl_teamid (key $KEY, jersey $number)"
done

echo "--- FIN TEAMPLAYERLINKS ---"
