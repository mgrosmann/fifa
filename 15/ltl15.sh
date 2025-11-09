#!/bin/bash
# ltl15_mysql.sh
# Export TXT réorganisé selon FIFA 15 depuis MySQL avec colonnes protégées par backticks

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
TABLE="leagueteamlinks"
OUTFILE="leagueteamlinks_fifa15_format.txt"

# --- Export avec here-document pour éviter les erreurs de retour à la ligne ---
$cmd -D "$DB" --batch --raw --column-names <<EOF > "$OUTFILE"
SELECT
    \`homega\`,
    \`homegf\`,
    \`points\`,
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
    \`previousyeartableposition\`,
    \`highestpossible\`,
    \`teamform\`,
    \`highestprobable\`,
    \`homewins\`,
    \`artificialkey\`,
    \`nummatchesplayed\`,
    \`teamid\`,
    \`gapresult\`,
    \`grouping\`,
    \`currenttableposition\`,
    \`awaywins\`,
    \`objective\`,
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
