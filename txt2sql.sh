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
SOURCE="$SUBDIR"
BASENAME=$(basename "$SUBDIR")
DB_NAME="$BASENAME"

echo "📁 Dossier sélectionné : $SOURCE"
echo "🗄️ Base MySQL : $DB_NAME"

# ⚙️ Paramètres MySQL (Docker)
MYSQL_USER='root'
MYSQL_PASS='root'
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000'

MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} -P${MYSQL_PORT}"

# 🛠️ Création base
echo "🧱 Création de la base \`${DB_NAME}\` si elle n'existe pas..."
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# 🔧 Temp dir
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
for file in "$SOURCE"*.txt; do
  echo "----------------------------------------"
  echo "📄 Traitement du fichier : $file"

  tablename="$(basename "$file" .txt | sed -E 's/[^a-zA-Z0-9_]+/_/g' | tr '[:upper:]' '[:lower:]')"
  clean="$TMPDIR/${tablename}.utf8"

  # Convert UTF-16 → UTF-8 si besoin
  iconv -f UTF-16 -t UTF-8 "$file" -o "$clean" 2>/dev/null || cp "$file" "$clean"
  tr -d '\000' < "$clean" | sed 's/\r$//' > "${clean}.tmp"
  mv "${clean}.tmp" "$clean"

  [ ! -s "$clean" ] && echo "⚠️ Fichier vide : $file — ignoré." && continue

  header_line=$(head -n 1 "$clean")
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

  [ "${#cols_sql[@]}" -eq 0 ] && cols_sql=(\`data\` TEXT)

  create_stmt="DROP TABLE IF EXISTS \`${tablename}\`;
CREATE TABLE \`${tablename}\` ($(IFS=,; echo "${cols_sql[*]}")) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"

  echo "🧩 Création table : \`${tablename}\`..."
  $MYSQL_CMD -D "$DB_NAME" -e "$create_stmt"

  if [[ "$detected_delim" == $'\t' ]]; then
    delim_escaped="\\t"
  else
    delim_escaped=$(printf "%s" "$detected_delim" | sed "s/'/''/g" | sed 's/\\/\\\\/g')
  fi

  load_sql="SET NAMES utf8mb4;
LOAD DATA LOCAL INFILE '$(printf "%q" "$clean")'
INTO TABLE \`${tablename}\`
FIELDS TERMINATED BY '${delim_escaped}'
OPTIONALLY ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;"

  echo "📥 Import de $file → table \`${tablename}\`..."
  $MYSQL_CMD -D "$DB_NAME" -e "$load_sql"

  echo "✅ Import terminé pour \`${tablename}\`."
done

echo "🎉 Tous les fichiers TXT importés dans la base \`${DB_NAME}\`."
