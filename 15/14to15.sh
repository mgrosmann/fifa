#!/bin/bash
# 🔐 Mot de passe MySQL
MYSQL_USER='root'
MYSQL_PASS='root'
DB="FIFA14"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000' 
TABLE1="teams"
OUTFILE1="teams.csv"
FILE="/mnt/c/Users/PC/Documents/FM_temp/FIFA14/players.txt"

# 📝 Création du fichier SQL
cat <<EOF > 14.sql
ALTER TABLE FIFA14.teams
ADD COLUMN leftfreekicktakerid INT DEFAULT 0,
ADD COLUMN rightfreekicktakerid INT DEFAULT 0;
EOF

# 🛠️ Exécution du script SQL
MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} -h${MYSQL_HOST}"
$MYSQL_CMD "$DB" < 14.sql

# ✅ Export des deux tables fixes
$MYSQL_CMD -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE1\`;" > "$OUTFILE1"
$MYSQL_CMD -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE2\`;" > "$OUTFILE2"

if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE1 et $OUTFILE2"
else
    echo "❌ Erreur lors de l'export"!
    exit 1
fi

# 📦 Conversion vers format DB Master
cp $FILE players.txt
python3 /mnt/c/Users/PC/PATH/script/convertor/15/playersfifa15.py
python3 /mnt/c/Users/PC/PATH/script/convertor/dbmaster.py players_fifa15_format.txt
python3 /mnt/c/Users/PC/PATH/script/convertor/15/teamsfifa15.py
python3 /mnt/c/Users/PC/PATH/script/convertor/dbmaster.py team_fifa15_format.txt