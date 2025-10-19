#!/bin/bash
# 🔐 Mot de passe MySQL
MYSQL_USER='root'
MYSQL_PASS='root'
DB="FIFA14"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000' 
TABLE1="teams"
OUTFILE1="teams.csv"
TABLE2="players"
OUTFILE2="players.csv"

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
python3 /mnt/c/Users/PC/PATH/fifa/15/player15.py
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py players_fifa15_format.txt
python3 /mnt/c/Users/PC/PATH/fifa/15/team15.py
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py team_fifa15_format.txt