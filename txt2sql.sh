#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

BASE_DIR="/mnt/c/github/txt/"

echo "📁 Dossiers disponibles dans : $BASE_DIR"
select folder in "$BASE_DIR"*/; do
  if [ -n "$folder" ]; then
    source="${folder%/}/"
    break
  else
    echo "❌ Sélection invalide. Réessaie."
  fi
done

# Nom de dossier (ex: FIFA15 → utilisé pour la DB)
DB_NAME="$(basename "$source")"
destination="${source}csv/"

echo "----------------------------------------"
echo "📂 Dossier source     : $source"
echo "📂 Dossier destination: $destination"
echo "🗄️  Base de données   : $DB_NAME"
echo "----------------------------------------"

mkdir -p "$destination"

########################################
# PHASE 1 : Conversion TXT → CSV
########################################

for file in "$source"*.txt; do
    filename=$(basename "$file" .txt)
    output="${destination}${filename}.csv"

    tmpfile="/tmp/${filename}.utf8"
    iconv -f UTF-16 -t UTF-8 "$file" -o "$tmpfile" 2>/dev/null || cp "$file" "$tmpfile"

    awk '{
        line=$0
        gsub(/\t+/, ";", line)
        gsub(/  +/, ";", line)
        print line
    }' "$tmpfile" > "$output"

    echo "✅ Converti : $file → $output"
done

########################################
# PHASE 2 : Import CSV → MySQL
########################################

MYSQL_USER='root'
MYSQL_PASS='root'
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'

CSV_DIR="$destination"

MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} -h${MYSQL_HOST}"

echo "Création (si besoin) de la base ${DB_NAME}..."
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

TMPDIR="$(mktemp -d)"
trap "rm -rf \"$TMPDIR\"" EXIT

sanitize_colname() {
  local col="$1"
  col="$(echo "$col" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  col="$(echo "$col" | sed -E 's/[^a-zA-Z0-9_]+/_/g')"
  if [[ "$col" =~ ^[0-9] ]]; then
    col="c_${col}"
  fi
  echo "${col,,}"
}

shopt -s nullglob
for csv in "$CSV_DIR"/*.csv "$CSV_DIR"/*.CSV; do
  echo "----------------------------------------"
  echo "Traitement du fichier : $csv"

  basefile="$(basename "$csv")"
  tablename="$(basename "$csv" .csv)"
  tablename="$(basename "$tablename" .CSV)"
  tablename="$(echo "$tablename" | sed -E 's/[^a-zA-Z0-9_]+/_/g' | tr '[:upper:]' '[:lower:]')"

  clean="$TMPDIR/${basefile}.clean.txt"

  if command -v dos2unix > /dev/null 2>&1; then
    tr -d '\000' < "$csv" > "$clean"
    dos2unix "$clean" >/dev/null 2>&1 || true
  else
    tr -d '\000' < "$csv" | sed 's/\r$//' > "$clean"
  fi

  if [ ! -s "$clean" ]; then
    echo "Fichier vide après nettoyage : $csv — saut."
    continue
  fi

  header_line=$(head -n 1 "$clean")

  detected_delim=","
  if echo "$header_line" | grep -q $'\t'; then
    detected_delim=$'\t'
  elif echo "$header_line" | grep -q ';'; then
    detected_delim=';'
  else
    detected_delim=','
  fi

  IFS="$detected_delim" read -r -a rawcols <<< "$header_line"

  cols_sql=()
  colnames=()
  for raw in "${rawcols[@]}"; do
    col=$(echo "$raw" | sed -e 's/^["'\'']//' -e 's/["'\'']$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    col_s=$(sanitize_colname "$col")
    suffix=1
    orig="$col_s"
    while printf '%s\n' "${colnames[@]}" | grep -qx "$col_s"; do
      col_s="${orig}_$suffix"
      suffix=$((suffix+1))
    done
    colnames+=("$col_s")
    cols_sql+=("\`${col_s}\` TEXT")
  done

  if [ "${#cols_sql[@]}" -eq 0 ]; then
    echo "Impossible de détecter les colonnes dans $csv — création d'une table avec 1 colonne 'data'."
    cols_sql=(\`data\` TEXT)
    detected_delim=","
  fi

  create_stmt="DROP TABLE IF EXISTS \`${tablename}\`;\nCREATE TABLE \`${tablename}\` ("
  create_stmt+=$(IFS=,; echo "${cols_sql[*]}")
  create_stmt+=") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"

  echo "Création de la table \`${tablename}\`..."
  $MYSQL_CMD -D "$DB_NAME" -e "$create_stmt"

  echo "Import du CSV dans la table \`${tablename}\` (séparateur: $( [[ "$detected_delim" == $'\t' ]] && echo 'TAB' || echo "$detected_delim" ))..."
  if [ "$detected_delim" = $'\t' ]; then
    delim_escaped="\\t"
  else
    delim_escaped=$(printf "%s" "$detected_delim" | sed -e "s/'/''/g" -e 's/\\/\\\\/g')
  fi

  load_sql="SET NAMES utf8mb4;\nLOAD DATA LOCAL INFILE '$(printf "%q" "$clean")' INTO TABLE \`${tablename}\` \
FIELDS TERMINATED BY '${delim_escaped}' \
OPTIONALLY ENCLOSED BY '\"' \
LINES TERMINATED BY '\n' \
IGNORE 1 LINES;"

  $MYSQL_CMD -D "$DB_NAME" -e "$load_sql"

  echo "✅ Import terminé pour \`${tablename}\`."
done

echo "🎯 Tous les fichiers de '$DB_NAME' ont été convertis et importés avec succès."

echo "passage en int"
mysql -uroot -proot -h127.0.0.1 -P5000 -DFC26 > sql/int.sql