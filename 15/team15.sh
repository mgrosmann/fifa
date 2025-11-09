#!/bin/bash
# ltl15_teams_mysql.sh
# Export TXT réorganisé selon FIFA 15 pour la table teams depuis MySQL

DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
TABLE="teams"
OUTFILE="teams_fifa15_format.txt"

# --- Export avec here-document pour éviter les erreurs de retour à la ligne ---
$cmd -D "$DB" --batch --raw --column-names <<EOF > "$OUTFILE"
SELECT
    \`assetid\`,
    \`balltype\`,
    \`teamcolor1g\`,
    \`teamcolor1r\`,
    \`teamcolor2b\`,
    \`teamcolor2r\`,
    \`teamcolor3r\`,
    \`teamcolor1b\`,
    \`latitude\`,
    \`teamcolor3g\`,
    \`teamcolor2g\`,
    \`teamname\`,
    \`adboardid\`,
    \`teamcolor3b\`,
    \`defmentality\`,
    \`powid\`,
    \`rightfreekicktakerid\`,
    \`physioid_secondary\`,
    \`domesticprestige\`,
    \`genericint2\`,
    \`jerseytype\`,
    \`rivalteam\`,
    \`midfieldrating\`,
    \`matchdayoverallrating\`,
    \`matchdaymidfieldrating\`,
    \`attackrating\`,
    \`physioid_primary\`,
    \`longitude\`,
    \`buspassing\`,
    \`matchdaydefenserating\`,
    \`defenserating\`,
    \`defteamwidth\`,
    \`longkicktakerid\`,
    \`bodytypeid\`,
    \`trait1\`,
    \`busdribbling\`,
    \`rightcornerkicktakerid\`,
    \`suitvariationid\`,
    \`defaggression\`,
    \`ethnicity\`,
    \`leftcornerkicktakerid\`,
    \`teamid\`,
    \`fancrowdhairskintexturecode\`,
    \`suittypeid\`,
    \`numtransfersin\`,
    \`captainid\`,
    \`personalityid\`,
    \`leftfreekicktakerid\`,
    \`genericbanner\`,
    \`buspositioning\`,
    \`stafftracksuitcolorcode\`,
    \`ccpositioning\`,
    \`busbuildupspeed\`,
    \`transferbudget\`,
    \`ccshooting\`,
    \`overallrating\`,
    \`ccpassing\`,
    \`utcoffset\`,
    \`penaltytakerid\`,
    \`freekicktakerid\`,
    \`defdefenderline\`,
    \`internationalprestige\`,
    \`form\`,
    \`genericint1\`,
    \`cccrossing\`,
    \`matchdayattackrating\`
FROM \`$TABLE\`;
EOF

echo "✅ Fichier exporté : $OUTFILE"
