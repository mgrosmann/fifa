#!/bin/bash
# ltl16_teamplayerlinks_mysql.sh
# Export TXT réorganisé selon FIFA 16 pour la table teamplayerlinks depuis MySQL

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000"
DB="FIFA15"
TABLE="teamplayerlinks"
OUTFILE="teamplayerlinks_fifa16_format.txt"

# --- Export avec here-document pour éviter les erreurs de retour à la ligne ---
$MYSQL_CMD -D "$DB" --batch --raw --column-names <<EOF > "$OUTFILE"
SELECT
    \`leaguegoals\`,
    \`isamongtopscorers\`,
    \`yellows\`,
    \`isamongtopscorersinteam\`,
    \`jerseynumber\`,
    \`position\`,
    \`artificialkey\`,
    \`teamid\`,
    \`leaguegoalsprevmatch\`,
    \`injury\`,
    \`leagueappearances\`,
    \`prevform\`,
    \`istopscorer\`,
    \`leaguegoalsprevthreematches\`,
    \`playerid\`,
    \`form\`,
    \`reds\`
FROM \`$TABLE\`;
EOF

echo "✅ Fichier exporté : $OUTFILE"
