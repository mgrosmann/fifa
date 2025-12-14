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

drop_column_if_exists() {
    local db="$1"
    local table="$2"
    local column="$3"

    exists=$($cmd -N -s -e "
        SELECT 1
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA='${db}'
          AND TABLE_NAME='${table}'
          AND COLUMN_NAME='${column}';
    ")

    if [ -n "$exists" ]; then
        echo "→ DROP COLUMN ${column} dans ${table}"
        $cmd -e "ALTER TABLE ${db}.${table} DROP COLUMN ${column};"
    else
        echo "→ ${column} n'existe pas dans ${table}"
    fi
}
$cmd -e "delete from ${DB}.players where gender=1"
drop_column_if_exists $DB players gender
drop_column_if_exists $DB players emotion
drop_column_if_exists $DB teamplayerlinks leaguegoalsprevmatch
drop_column_if_exists $DB teamplayerlinks leaguegoalsprevthreematches

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
iconv -f UTF-8 -t UTF-16LE players.txt > 1players.txt
iconv -f UTF-8 -t UTF-16LE teamplayerlinks.txt > 1teamplayerlinks.txt
bash /mnt/c/github/fifa/15/ltl15.sh
iconv -f UTF-8 -t UTF-16LE leagueteamlinks_fifa15_format.txt > leagueteamlinks.txt
mkdir -p /mnt/c/github/fifa/15/imported_files_16/
cp /mnt/c/github/txt/FIFA16/leagues.txt /mnt/c/github/fifa/15/imported_files_16/
cp /mnt/c/github/txt/FIFA16/playernames.txt /mnt/c/github/fifa/15/imported_files_16/
cp /mnt/c/github/txt/FIFA16/teams.txt /mnt/c/github/fifa/15/imported_files_16/
mv 1players.txt /mnt/c/github/fifa/15/imported_files_16/players.txt
mv 1teamplayerlinks.txt /mnt/c/github/fifa/15/imported_files_16/teamplayerlinks.txt
mv leagueteamlinks.txt /mnt/c/github/fifa/15/imported_files_16/leagueteamlinks.txt
