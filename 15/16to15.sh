#!/bin/bash
# 🔐 Mot de passe MySQL
DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
TABLE1="players"
TABLE2="teamplayerlinks"
OUTFILE1="players.txt"
OUTFILE2="teamplayerlinks.txt"
TABLE3="leagueteamlinks"
OUTFILE3="leagueteamlinks.txt"


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
$cmd "$DB" < 16.sql

# ✅ Export des deux tables fixes
$cmd -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE1\`;" > "$OUTFILE1"
$cmd -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE2\`;" > "$OUTFILE2"
$cmd -D "$DB" --batch --column-names -e "SELECT * FROM \`$TABLE3\`;" > "$OUTFILE3"


if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE1,$OUTFILE2 et $OUTFILE3"
else
    echo "❌ Erreur lors de l'export"
    exit 1
fi

# 📦 Conversion vers format DB Master
bash /mnt/c/github/fifa/txt2utf16.sh  "./$OUTFILE1"
bash /mnt/c/github/fifa/txt2utf16.sh  "./$OUTFILE2"
bash /mnt/c/github/fifa/15/ltl15.sh
bash /mnt/c/github/fifa/txt2utf16.sh  leagueteamlinks_fifa15_format.txt
mkdir -p /mnt/c/github/fifa/15/imported_files_16/
cp /mnt/c/github/txt/FIFA16/leagues.txt /mnt/c/github/fifa/15/imported_files_16/
cp /mnt/c/github/txt/FIFA16/playernames.txt /mnt/c/github/fifa/15/imported_files_16/
cp /mnt/c/github/txt/FIFA16/teams.txt /mnt/c/github/fifa/15/imported_files_16/
mv players_dbmaster.txt /mnt/c/github/fifa/15/imported_files_16/players.txt
mv teamplayerlinks_dbmaster.txt /mnt/c/github/fifa/15/imported_files_16/teamplayerlinks.txt
mv leagueteamlinks_fifa15_format_utf16.txt /mnt/c/github/fifa/15/imported_files_16/leagueteamlinks.txt