#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

# 📁 Dossier racine
ROOT="/mnt/c/Users/PC/Documents/FM_temp"

echo "📂 Dossiers disponibles dans $ROOT :"
select SUBDIR in "$ROOT"/*/; do
  [ -n "$SUBDIR" ] && break
done

# 🔧 Préparation des chemins
source="$SUBDIR"
basename=$(basename "$SUBDIR")
destination="${source}csv/"
DB_NAME="$basename"

echo "📁 Dossier sélectionné : $source"
echo "📄 Destination CSV : $destination"
echo "🗄️ Base MySQL : $DB_NAME"

mkdir -p "$destination"

# 🔄 Conversion TXT → CSV
for file in "$source"*.txt; do
  [ -f "$file" ] || continue
  filename=$(basename "$file" .txt)
  output="${destination}${filename}.csv"
  tmpfile="/tmp/${filename}.utf8"

  echo "🔄 Conversion de $filename ..."

  # Conversion UTF-16 → UTF-8
  if ! iconv -f UTF-16 -t UTF-8 "$file" -o "$tmpfile" 2>/dev/null; then
    cp "$file" "$tmpfile"
  fi

  # Conversion tabulations → point-virgule
  awk '{
    line=$0
    gsub(/\t/, ";", line)
    print line
  }' "$tmpfile" > "$output"

  echo "✅ Converti : $file → $output"
done

# 🔽 Import CSV → MySQL
MYSQL_USER='root'
MYSQL_PASS='root'
MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS}"

echo "🛠️ Création de la base \`$DB_NAME\` si elle n'existe pas..."
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

TMPDIR="$(mktemp -d)"
trap "rm -rf \"$TMPDIR\"" EXIT

sanitize_colname() {
  local col="$1"
  col="$(echo "$col" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  col="$(echo "$col" | sed -E 's/[^a-zA-Z0-9_]+/_/g')"
  [[ "$col" =~ ^[0-9] ]] && col="c_${col}"
  echo "${col,,}"
}

shopt -s nullglob
for csv in "$destination"/*.csv "$destination"/*.CSV; do
  echo "----------------------------------------"
  echo "📄 Traitement du fichier : $csv"

  basefile=$(basename "$csv")
  tablename=$(basename "$csv" .csv | sed -E 's/[^a-zA-Z0-9_]+/_/g' | tr '[:upper:]' '[:lower:]')
  clean="$TMPDIR/${basefile}.clean.txt"

  tr -d '\000' < "$csv" | sed 's/\r$//' > "$clean"

  if [ ! -s "$clean" ]; then
    echo "⚠️ Fichier vide : $csv — ignoré."
    continue
  fi

  header_line=$(head -n 1 "$clean")

  # Détection du délimiteur
  detected_delim=";"
  echo "$header_line" | grep -q $'\t' && detected_delim=$'\t'
  echo "$header_line" | grep -q ',' && detected_delim=','

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
    cols_sql=(\`data\` TEXT)
    detected_delim=","
  fi

  # Création de la table
  create_sql="CREATE TABLE IF NOT EXISTS \`${tablename}\` ($(IFS=,; echo "${cols_sql[*]}"));"

  $MYSQL_CMD -D "$DB_NAME" -e "$create_sql"

  # Délimiteur échappé
  if [[ "$detected_delim" == $'\t' ]]; then
    delim_escaped="\\t"
  else
    delim_escaped="$detected_delim"
  fi

  # Importation du fichier
  load_sql=$(cat <<EOF
SET NAMES utf8mb4;
LOAD DATA LOCAL INFILE '${clean}'
INTO TABLE \`${tablename}\`
FIELDS TERMINATED BY '${delim_escaped}'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
EOF
)

  echo "📥 Import dans \`${tablename}\` ..."
  echo "$load_sql" | $MYSQL_CMD -D "$DB_NAME"
  echo "✅ Import terminé pour \`${tablename}\`."
done

echo "🎉 Tous les fichiers ont été convertis et importés dans la base \`$DB_NAME\`."
