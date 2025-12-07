#!/bin/bash
set -e

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFC15 -N -s"
CSV_TPL="/mnt/c/github/fifa/player/import/teamplayerlinks.csv"

# Équipes autorisées (jerseynumber fixe)
AUTH_TEAMS="21,22,32,34,44,45,46,47,48,52,65,66,73,240,241,243,461,483,110374,1,2,5,7,8,9,10,11,13,14,18,19,106,110,144,1796,1799,1808,1925,1943"

FREE_AGENT=111592

exclude_condition="(
    t.teamname LIKE '%All star%'
 OR t.teamname LIKE '%Adidas%'
 OR t.teamname LIKE '%Nike%'
 OR t.teamname LIKE '% xi%'
 OR t.teamname LIKE '%allstar%'
 OR ltl.leagueid = 78
)"

##########################################################
# 📌 Fonction : choisir automatiquement la bonne position
##########################################################
get_position_for_team() {
    local teamid=$1
    local desired=$2

    local titulaires=$($MYSQL_CMD -e "
        SELECT COUNT(*) FROM teamplayerlinks
        WHERE teamid=$teamid AND position BETWEEN 0 AND 27;
    ")

    local remp=$($MYSQL_CMD -e "
        SELECT COUNT(*) FROM teamplayerlinks
        WHERE teamid=$teamid AND position = 28;
    ")

    # Cas 1 : position entre 0 et 27
    if (( desired >= 0 && desired <= 27 )); then
        if (( titulaires < 11 )); then
            echo "$desired"
        elif (( remp < 7 )); then
            echo 28
        else
            echo 29
        fi

    # Cas 2 : remplaçant demandé
    elif (( desired == 28 )); then
        if (( remp < 7 )); then
            echo 28
        elif (( titulaires < 11 )); then
            echo 0
        else
            echo 29
        fi

    # Cas 3 : autre valeur → placement intelligent
    else
        if (( titulaires < 11 )); then
            echo 0
        elif (( remp < 7 )); then
            echo 28
        else
            echo 29
        fi
    fi
}

##########################################################
# 🚨 Libération players des équipes autorisées
##########################################################

echo "🚨 Libération des joueurs des équipes AUTH_TEAMS → FREE_AGENT…"
$MYSQL_CMD -e "
UPDATE teamplayerlinks tpl
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
SET tpl.teamid=$FREE_AGENT
WHERE tpl.teamid IN ($AUTH_TEAMS);
"

echo "--- IMPORT TEAMPLAYERLINKS ---"

##########################################################
# 🔄 Import CSV
##########################################################

tail -n +2 "$CSV_TPL" | while IFS=';' read -r leaguegoals isamongtopscorers yellows isamongtopscorersinteam jerseynumber \
    position artificialkey teamid injury leagueappearances prevform istopscorer playerid form reds
do
    tpl_teamid=$(echo "$teamid" | tr -d '" ' | xargs)
    tpl_playerid=$(echo "$playerid" | tr -d '" ' | xargs)
    [[ -z "$tpl_teamid" || -z "$tpl_playerid" ]] && continue

    # 🔍 Vérifier si joueur déjà présent
    existing_team=$($MYSQL_CMD --skip-column-names -e "
SELECT tpl.teamid
FROM teamplayerlinks tpl
LEFT JOIN teams t ON tpl.teamid = t.teamid
LEFT JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE tpl.playerid=$tpl_playerid
  AND NOT $exclude_condition
LIMIT 1;
")

    ##########################################################
    # 🟦 CAS 1 : Le joueur existe déjà
    ##########################################################
    if [[ -n "$existing_team" ]]; then

        # 🟩 Même équipe → simple update
        if [[ "$existing_team" == "$tpl_teamid" ]]; then

            final_position=$(get_position_for_team "$tpl_teamid" "$position")

            $MYSQL_CMD -e "
UPDATE teamplayerlinks
SET leaguegoals=$leaguegoals,
    isamongtopscorers=$isamongtopscorers,
    yellows=$yellows,
    isamongtopscorersinteam=$isamongtopscorersinteam,
    position=$final_position,
    injury=$injury,
    leagueappearances=$leagueappearances,
    prevform=$prevform,
    istopscorer=$istopscorer,
    form=$form,
    reds=$reds
WHERE teamid=$tpl_teamid AND playerid=$tpl_playerid;
            "

            echo "✔ UPDATE : Player $tpl_playerid dans team $tpl_teamid"
        
        # 🟥 Joueur doit être déplacé
        else
            echo "↳ Déplacement $tpl_playerid : $existing_team → $tpl_teamid"

            KEY=$($MYSQL_CMD -e "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")

            # Jersey
            if [[ ",$AUTH_TEAMS," =~ ",$tpl_teamid," ]]; then
                number=$jerseynumber
            else
                number=$($MYSQL_CMD -e "
SELECT COALESCE(MIN(t1.jerseynumber + 1),1)
FROM teamplayerlinks t1
LEFT JOIN teamplayerlinks t2
  ON t1.jerseynumber + 1 = t2.jerseynumber
 AND t1.teamid = $tpl_teamid
WHERE t1.teamid = $tpl_teamid AND t2.jerseynumber IS NULL;
                ")
                [[ -z "$number" ]] && number=1
            fi

            final_position=$(get_position_for_team "$tpl_teamid" "$position")

            $MYSQL_CMD -e "
UPDATE teamplayerlinks
SET teamid=$tpl_teamid,
    artificialkey=$KEY,
    leaguegoals=$leaguegoals,
    isamongtopscorers=$isamongtopscorers,
    yellows=$yellows,
    isamongtopscorersinteam=$isamongtopscorersinteam,
    position=$final_position,
    injury=$injury,
    leagueappearances=$leagueappearances,
    prevform=$prevform,
    istopscorer=$istopscorer,
    form=$form,
    reds=$reds,
    jerseynumber=$number
WHERE playerid=$tpl_playerid;
            "

            echo "✔ MOVE : $tpl_playerid → team $tpl_teamid (key=$KEY, pos=$final_position, jersey=$number)"
        fi

    ##########################################################
    # 🟩 CAS 2 : Joueur inexistant → INSERT
    ##########################################################
    else
        
        KEY=$($MYSQL_CMD -e "SELECT IFNULL(MAX(artificialkey)+1,1) FROM teamplayerlinks WHERE teamid=$tpl_teamid;")

        if [[ ",$AUTH_TEAMS," =~ ",$tpl_teamid," ]]; then
            number=$jerseynumber
        else
            number=$($MYSQL_CMD -e "
SELECT COALESCE(MIN(t1.jerseynumber + 1),1)
FROM teamplayerlinks t1
LEFT JOIN teamplayerlinks t2
  ON t1.jerseynumber + 1 = t2.jerseynumber
 AND t1.teamid = $tpl_teamid
WHERE t1.teamid = $tpl_teamid AND t2.jerseynumber IS NULL;
            ")
            [[ -z "$number" ]] && number=1
        fi

        final_position=$(get_position_for_team "$tpl_teamid" "$position")

        $MYSQL_CMD -e "
INSERT INTO teamplayerlinks
(teamid, playerid, artificialkey, leaguegoals, isamongtopscorers, yellows,
 isamongtopscorersinteam, injury, leagueappearances, prevform, form,
 istopscorer, reds, position, jerseynumber)
VALUES
($tpl_teamid, $tpl_playerid, $KEY, $leaguegoals, $isamongtopscorers, $yellows,
 $isamongtopscorersinteam, $injury, $leagueappearances, $prevform, $form,
 $istopscorer, $reds, $final_position, $number);
        "

        echo "✔ INSERT : Player $tpl_playerid → team $tpl_teamid (key=$KEY, pos=$final_position, jersey=$number)"
    fi

done

echo "--- FIN TEAMPLAYERLINKS ---"
