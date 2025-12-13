#!/bin/bash
# 🔐 Mot de passe MySQL
DB="FIFA14"
cmd="mysql --local-infile=1 -uroot -proot -h127.0.0.1 -D $DB -P5000 -A"
TABLE1="players"
TABLE2="teamplayerlinks"
OUTFILE1="players.txt"
OUTFILE2="teamplayerlinks.txt"
TABLE3="leagueteamlinks"
OUTFILE3="leagueteamlinks.txt"

# 📝 Création du fichier SQL
cat <<EOF > ${DB}.sql
ALTER TABLE ${DB}.players
ADD COLUMN gender INT DEFAULT 0,
ADD COLUMN emotion INT DEFAULT 1;

ALTER TABLE ${DB}.teamplayerlinks
ADD COLUMN leaguegoalsprevmatch INT DEFAULT 0,
ADD COLUMN leaguegoalsprevthreematches INT DEFAULT 0;
EOF

# 🛠️ Exécution du script SQL
$cmd < ${DB}.sql

# ✅ Export des deux tables fixes
$cmd --batch --column-names -e "SELECT * FROM \`$TABLE1\`;" > "$OUTFILE1"
$cmd --batch --column-names -e "SELECT * FROM \`$TABLE2\`;" > "$OUTFILE2"
$cmd --batch --column-names -e "SELECT * FROM \`$TABLE3\`;" > "$OUTFILE3"


if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE1,$OUTFILE2 et $OUTFILE3"
else
    echo "❌ Erreur lors de l'export"
    exit 1
fi

# 📦 Conversion vers format DB Master
bash /mnt/c/github/fifa/16/tpl16.sh
iconv -f UTF-8 -t UTF-16LE teamplayerlinks_fifa16_format.txt > teamplayerlinks.txt
bash /mnt/c/github/fifa/16/ltl16.sh
iconv -f UTF-8 -t UTF-16LE leagueteamlinks_fifa16_format.txt > leagueteamlinks.txt
bash /mnt/c/github/fifa/16/player16.sh
iconv -f UTF-8 -t UTF-16LE players_fifa16_format.txt > players.txt
mkdir -p /mnt/c/github/fifa/16/imported_files_15/
cp /mnt/c/github/txt/FIFA16/leagues.txt /mnt/c/github/fifa/16/imported_files_15/
cp /mnt/c/github/txt/FIFA16/playernames.txt /mnt/c/github/fifa/16/imported_files_15/
cp /mnt/c/github/txt/FIFA16/teams.txt /mnt/c/github/fifa/16/imported_files_15/
mv players.txt /mnt/c/github/fifa/16/imported_files_15/players.txt
mv teamplayerlinks.txt /mnt/c/github/fifa/16/imported_files_15/teamplayerlinks.txt
mv leagueteamlinks.txt /mnt/c/github/fifa/16/imported_files_15/leagueteamlinks.txt
