#!/bin/bash
# 🔐 Mot de passe MySQL
DB="FIFA14"
cmd="mysql --local-infile=1 -uroot -proot -h127.0.0.1 -D $DB -P5000 -A"
TABLE1="teams"
OUTFILE1="teams.txt"
TABLE2="players"
OUTFILE2="players.txt"
add_column_if_missing() {
    local db="$1"
    local table="$2"
    local column="$3"
    local definition="$4"

    exists=$($cmd -N -e "
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA='${db}'
          AND TABLE_NAME='${table}'
          AND COLUMN_NAME='${column}';
    ")

    if [ -z "$exists" ]; then
        echo "→ Ajout de ${column} dans ${table}"
        $cmd -e "ALTER TABLE ${db}.${table} ADD COLUMN ${column} ${definition};"
    else
        echo "→ ${column} existe déjà"
    fi
}

add_column_if_missing $DB teams leftfreekicktakerid "INT DEFAULT 0"
add_column_if_missing $DB teams rightfreekicktakerid "INT DEFAULT 0"

# ✅ Export des deux tables fixes
$cmd --batch --column-names -e "SELECT * FROM \`$TABLE1\`;" > "$OUTFILE1"
$cmd --batch --column-names -e "SELECT * FROM \`$TABLE2\`;" > "$OUTFILE2"

if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE1 et $OUTFILE2"
else
    echo "❌ Erreur lors de l'export"!
    exit 1
fi

# 📦 Conversion vers format DB Master
bash /mnt/c/github/fifa/15/player15.sh
iconv -f UTF-8 -t UTF-16LE players_fifa15_format.txt > players.txt
bash /mnt/c/github/fifa/15/team15.sh
iconv -f UTF-8 -t UTF-16LE teams_fifa15_format.txt > teams.txt
mkdir -p /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/leagueteamlinks.txt /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/leagues.txt /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/playernames.txt /mnt/c/github/fifa/15/imported_files_14/
cp /mnt/c/github/txt/FIFA15/teamplayerlinks.txt /mnt/c/github/fifa/15/imported_files_14/
mv players.txt /mnt/c/github/fifa/15/imported_files_14/players.txt
mv teams.txt /mnt/c/github/fifa/15/imported_files_14/teams.txt
