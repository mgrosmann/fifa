#!/bin/bash
set -e

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC15 -N -s"
CSV_TPL="/mnt/c/github/fifa/player/import/teamplayerlinks.csv"

# Liste des équipes autorisées (jerseynumber fixe)
AUTH_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374"
FREE_AGENT=111592

# Exclusion pour équipes spéciales
exclude_condition="(
    t.teamname LIKE '%All star%'
 OR t.teamname LIKE '%Adidas%'
 OR t.teamname LIKE '%Nike%'
 OR t.teamname LIKE '% xi%'
 OR t.teamname LIKE '%allstar%'
 OR ltl.leagueid = 78
)"

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

    # Vérifier si le joueur existe dans n'importe quelle équipe
    existing_team=$($MYSQL_CMD --skip-column-names -e "
SELECT tpl.teamid
FROM teamplayerlinks tpl
LEFT JOIN teams t ON tpl.teamid = t.teamid
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE tpl.playerid=$tpl_playerid
  AND NOT $exclude_condition
LIMIT 1;
    ")

    if [[ -n "$existing_team" ]]; then
        if [[ "$existing_team" == "$tpl_teamid" ]]; then
            # Même équipe → update
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
            echo "✔ Player $tpl_playerid mis à jour dans team $tpl_teamid"
        else
            # Déplacement uniquement si pas équipe exclue
            echo "↳ Déplacement de $tpl_playerid de team $existing_team → $tpl_teamid"
            KEY=$($MYSQL_CMD --skip-column-names -e "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")

            # Calcul du jersey number si nécessaire
            if [[ ",$AUTH_TEAMS," =~ ",$tpl_teamid," ]]; then
                number=$jerseynumber
            else
                number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
  ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
 AND tpl1.teamid = $tpl_teamid
WHERE tpl1.teamid = $tpl_teamid AND tpl2.jerseynumber IS NULL;
                ")
                [[ -z "$number" ]] && number=1
            fi

            $MYSQL_CMD -e "
UPDATE teamplayerlinks
SET teamid=$tpl_teamid,
    artificialkey=$KEY,
    leaguegoals=$leaguegoals,
    isamongtopscorers=$isamongtopscorers,
    yellows=$yellows,
    isamongtopscorersinteam=$isamongtopscorersinteam,
    position=$position,
    injury=$injury,
    leagueappearances=$leagueappearances,
    prevform=$prevform,
    istopscorer=$istopscorer,
    form=$form,
    reds=$reds,
    jerseynumber=$number
WHERE playerid=$tpl_playerid;
            "
            echo "✔ Player $tpl_playerid déplacé vers team $tpl_teamid (key $KEY, jersey $number)"
        fi
    else
        # Joueur inexistant → insert
        KEY=$($MYSQL_CMD --skip-column-names -e "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")
        if [[ ",$AUTH_TEAMS," =~ ",$tpl_teamid," ]]; then
            number=$jerseynumber
        else
            number=$($MYSQL_CMD --skip-column-names -e "
SELECT COALESCE(MIN(tpl1.jerseynumber + 1),1)
FROM teamplayerlinks tpl1
LEFT JOIN teamplayerlinks tpl2
  ON tpl1.jerseynumber + 1 = tpl2.jerseynumber
 AND tpl1.teamid = $tpl_teamid
WHERE tpl1.teamid = $tpl_teamid AND tpl2.jerseynumber IS NULL;
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
        echo "✔ Player $tpl_playerid ajouté dans team $tpl_teamid (key $KEY, jersey $number)"
    fi

done

echo "--- FIN TEAMPLAYERLINKS ---"
