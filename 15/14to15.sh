#!/bin/bash
# 🔐 Mot de passe MySQL
DB="FIFA14"
cmd="mysql --local-infile=1 -uroot -proot -h127.0.0.1 -D $DB -P5000 -A"
TABLE1="teams"
OUTFILE1="teams.txt"
TABLE2="players"
OUTFILE2="players.txt"

# 📝 Création du fichier SQL
cat <<EOF > 14.sql
ALTER TABLE FIFA14.teams
ADD COLUMN leftfreekicktakerid INT DEFAULT 0,
ADD COLUMN rightfreekicktakerid INT DEFAULT 0;
EOF

# 🛠️ Exécution du script SQL
$cmd "$DB" < 14.sql

# ✅ Export des deux tables fixes
$cmd -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE1\`;" > "$OUTFILE1"
$cmd -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE2\`;" > "$OUTFILE2"

if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE1 et $OUTFILE2"
else
    echo "❌ Erreur lors de l'export"!
    exit 1
fi

# 📦 Conversion vers format DB Master
bash /mnt/c/github/fifa/15/player15.sh
bash /mnt/c/github/fifa/txt2utf16.sh  players_fifa15_format.txt
bash /mnt/c/github/fifa/15/team15.sh
bash /mnt/c/github/fifa/txt2utf16.sh  teams_fifa15_format.txt
mkdir -p /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/leagueteamlinks.txt /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/leagues.txt /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/playernames.txt /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/teamplayerlinks.txt /mnt/c/github/fifa/15/imported_files_14/
mv players_fifa15_format_utf16.txt /mnt/c/github/fifa/15/imported_files_14/players.txt
mv teams_fifa15_format_utf16.txt /mnt/c/github/fifa/15/imported_files_14/teams.txt