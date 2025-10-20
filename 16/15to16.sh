#!/bin/bash
# 🔐 Mot de passe MySQL
MYSQL_USER='root'
MYSQL_PASS='root'
DB="FIFA15"
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000' 
TABLE1="players"
TABLE2="teamplayerlinks"
OUTFILE1="players.csv"
OUTFILE2="teamplayerlinks.csv"
TABLE3="leagueteamlinks"
OUTFILE3="leagueteamlinks.csv"

# 📝 Création du fichier SQL
cat <<EOF > 15.sql
ALTER TABLE FIFA15.players
ADD COLUMN gender INT DEFAULT 0,
ADD COLUMN emotion INT DEFAULT 1;

ALTER TABLE FIFA15.teamplayerlinks
ADD COLUMN leaguegoalsprevmatch INT DEFAULT 0,
ADD COLUMN leaguegoalsprevthreematches INT DEFAULT 0;
EOF

# 🛠️ Exécution du script SQL
MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} -h${MYSQL_HOST}"
$MYSQL_CMD "$DB" < 15.sql

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
python3 /mnt/c/Users/PC/PATH/fifa/16/player16.py
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py players_fifa16_format.txt
python3 /mnt/c/Users/PC/PATH/fifa/16/tpl16.py
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py teamplayerlinks_fifa16_format.txt
python3 /mnt/c/Users/PC/PATH/fifa/16/ltl16.py
python3 /mnt/c/Users/PC/PATH/fifa/dbmaster.py leagueteamlinks_fifa15_format.txt