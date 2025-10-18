#!/bin/bash
# 🔐 Mot de passe MySQL
pass="root"
DB="FIFA14"
TABLE1="players"
TABLE2="teams"
OUTFILE1="players.csv"
OUTFILE2="teams.csv"

# 📝 Création du fichier SQL
cat <<EOF > 14.sql
ALTER TABLE FIFA14.teams
ADD COLUMN leftfreekicktakerid INT DEFAULT 0,
ADD COLUMN rightfreekicktakerid INT DEFAULT 0;
EOF

# 🛠️ Exécution de la requête SQL
mysql -uroot -p"$pass" < 14.sql

# ✅ Export des deux tables fixes
mysql -uroot -p"$pass" -D "$DB" -e "SELECT * FROM \`$TABLE1\`;" \
--batch --column-names > "$OUTFILE1"

mysql -uroot -p"$pass" -D "$DB" -e "SELECT * FROM \`$TABLE2\`;" \
--batch --column-names > "$OUTFILE2"

if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE1 et $OUTFILE2"
else
    echo "❌ Erreur lors de l'export"
    exit 1
fi

# 📦 Conversion vers format DB Master
python3 /mnt/c/Users/PC/PATH/script/convertor/15/playerfifa15.py "./$OUTFILE1"
python3 /mnt/c/Users/PC/PATH/script/convertor/dbmaster.py players_fifa15_format.txt
python3 /mnt/c/Users/PC/PATH/script/convertor/15/teamsfifa15.py "./$OUTFILE2"
python3 /mnt/c/Users/PC/PATH/script/convertor/dbmaster.py teamplayerlinks_fifa15_format.txt