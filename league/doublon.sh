#!/bin/bash
# ==========================================================
# Script : check-duplicates.sh
# But : Identifier les équipes présentes dans plusieurs championnats
#       et aider à choisir dans quel championnat les enlever
# ==========================================================

# --- Configuration MySQL ---
DB="FIFA15"
USER="root"
PASS="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="5000"

echo "⚽ Vérification des doublons d'équipes dans plusieurs championnats"
echo "----------------------------------------------------"

# Récupère toutes les équipes présentes dans plusieurs ligues
mysql -u$USER -p$PASS -h$MYSQL_HOST -P$MYSQL_PORT -N -D $DB -e "
SELECT 
    t.teamid,
    t.teamname,
    COUNT(ltl.leagueid) AS nb_leagues,
    GROUP_CONCAT(ltl.leagueid ORDER BY ltl.leagueid SEPARATOR ', ') AS leagues
FROM teams t
INNER JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
GROUP BY t.teamid, t.teamname
HAVING COUNT(ltl.leagueid) > 1
ORDER BY nb_leagues DESC;
" | while read teamid teamname nb_leagues leagues; do

    echo "🛑 L’équipe '$teamname' (ID $teamid) est présente dans $nb_leagues championnats : $leagues"

    # Affiche le nombre d'équipes par championnat
    echo "Nombre d’équipes par championnat concerné :"
    for leagueid in $(echo $leagues | tr ',' ' '); do
        count=$(mysql -u$USER -p$PASS -h$MYSQL_HOST -P$MYSQL_PORT -N -D $DB -e "
            SELECT COUNT(*) FROM leagueteamlinks WHERE leagueid = $leagueid;
        ")
        name=$(mysql -u$USER -p$PASS -h$MYSQL_HOST -P$MYSQL_PORT -N -D $DB -e "
            SELECT leaguename FROM leagues WHERE leagueid = $leagueid;
        ")
        echo "   - $name ($leagueid) : $count équipes"
    done

    # Propose de supprimer dans un championnat
    read -p "👉 Entrez l'ID de la ligue où supprimer '$teamname' (ou 'skip' pour passer) : " delleague
    if [[ "$delleague" != "skip" ]]; then
        mysql -u$USER -p$PASS -h$MYSQL_HOST -P$MYSQL_PORT -N -D $DB -e "
            DELETE FROM leagueteamlinks WHERE teamid=$teamid AND leagueid=$delleague;
        "
        echo "🗑️ Équipe $teamname supprimée de la ligue $delleague."
    fi
    echo "----------------------------------------------------"
done

echo "🏁 Vérification des doublons terminée."
