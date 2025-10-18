#!/bin/bash

# 🔐 Mot de passe MySQL
pass="root"
DB="FIFA16"
TABLE1="players"
TABLE2="teamplayerlinks"
OUTFILE1="players.csv"
OUTFILE2="teamplayerlinks.csv"

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
mysql -uroot -p"$pass" < 16.sql

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
python3 /mnt/c/Users/PC/PATH/script/convertor/dbmaster.py "./$OUTFILE1"
python3 /mnt/c/Users/PC/PATH/script/convertor/dbmaster.py "./$OUTFILE2"