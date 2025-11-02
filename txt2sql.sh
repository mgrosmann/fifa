#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

BASE_DIR="/mnt/c/github/txt"
MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="5000"
DB_NAME="$(basename "$BASE_DIR")"

mysqlcmd="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} -P${MYSQL_PORT}"

echo "📁 Dossier de travail : $BASE_DIR"
echo "🗄️  Base de données : $DB_NAME"
echo "------------------------------------"

# Création base si elle n'existe pas
$mysqlcmd -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

for file in "$BASE_DIR"/*.txt; do
    [[ -e "$file" ]] || { echo "Aucun fichier .txt trouvé."; exit 0; }

    base=$(basename "$file" .txt)
    utf8="${BASE_DIR}/${base}_utf8.txt"
    csv="${BASE_DIR}/${base}.csv"
    sql="${BASE_DIR}/${base}.sql"

    echo "------------------------------------"
    echo "🔤 Conversion en UTF-8 : $file → $utf8"
    iconv -f UTF-16 -t UTF-8 "$file" -o "$utf8" 2>/dev/null || cp "$file" "$utf8"

    echo "📄 Conversion en CSV : $utf8 → $csv"
    perl -lpe 's/"/""/g; s/^|$/"/g; s/\t/";"/g' "$utf8" > "$csv"

    echo "🧱 Génération SQL avec csv2sql.sh : $csv"
    bash csv2sql.sh "$csv"

    echo "💾 Import dans MySQL : $sql"
    $mysqlcmd -D "$DB_NAME" < "$sql"

    echo "✅ Fichier importé : $base"
done

echo "🎯 Tous les fichiers TXT ont été convertis et importés avec succès."
