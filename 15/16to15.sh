#!/bin/bash
# 🔐 Mot de passe MySQL
MYSQL_USER='root'
MYSQL_PASS='root'
DB="FIFA16"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000' 
TABLE1="players"
TABLE2="teamplayerlinks"
OUTFILE1="players.csv"
OUTFILE2="teamplayerlinks.csv"
TABLE3="leagueteamlinks"
OUTFILE3="leagueteamlinks.csv"


# 📝 Création du fichier SQL
cat <<EOF > 16.sql
DELETE FROM FIFA16.players
WHERE gender = 1;

ALTER TABLE FIFA16.players
DROP COLUMN gender,
DROP COLUMN emotion;

ALTER TABLE FIFA16.teamplayerlinks
DROP COLUMN leaguegoalsprevmatch,
DROP COLUMN leaguegoalsprevthreematches;
EOF

# 🛠️ Exécution du script SQL
MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} -h${MYSQL_HOST}"
$MYSQL_CMD "$DB" < 16.sql

# ✅ Export des deux tables fixes
$MYSQL_CMD -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE1\`;" > "$OUTFILE1"
$MYSQL_CMD -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE2\`;" > "$OUTFILE2"
$MYSQL_CMD -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE3\`;" > "$OUTFILE3"


if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE1,$OUTFILE2 et $OUTFILE3"
else
    echo "❌ Erreur lors de l'export"
    exit 1
fi

# 📦 Conversion vers format DB Master
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py "./$OUTFILE1"
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py "./$OUTFILE2"
python3 /mnt/c/Users/PC/PATH/fifa/15/ltl15.py
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py leagueteamlinks_fifa15_format.txt