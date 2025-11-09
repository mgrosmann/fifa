#!/bin/bash
# ltl16_mysql.sh
# Export TXT réorganisé selon l'ordre FIFA 16 depuis MySQL avec colonnes protégées par backticks

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
TABLE="leagueteamlinks"
OUTFILE="leagueteamlinks_fifa16_format.txt"

# --- Export avec here-document pour éviter les erreurs de retour à la ligne ---
$cmd -D "$DB" --batch --raw --column-names <<EOF > "$OUTFILE"
SELECT
    \`homega\`,
    \`previousyeartableposition\`,
    \`homegf\`,
    \`currenttableposition\`,
    \`awaygf\`,
    \`awayga\`,
    \`teamshortform\`,
    \`hasachievedobjective\`,
    \`secondarytable\`,
    \`yettowin\`,
    \`unbeatenallcomps\`,
    \`unbeatenleague\`,
    \`champion\`,
    \`leagueid\`,
    \`prevleagueid\`,
    \`highestpossible\`,
    \`teamform\`,
    \`highestprobable\`,
    \`homewins\`,
    \`artificialkey\`,
    \`nummatchesplayed\`,
    \`teamid\`,
    \`gapresult\`,
    \`grouping\`,
    \`awaywins\`,
    \`objective\`,
    \`points\`,
    \`actualvsexpectations\`,
    \`homelosses\`,
    \`unbeatenhome\`,
    \`lastgameresult\`,
    \`unbeatenaway\`,
    \`awaylosses\`,
    \`awaydraws\`,
    \`homedraws\`,
    \`teamlongform\`
FROM \`$TABLE\`;
EOF

echo "✅ Fichier exporté : $OUTFILE"
!
