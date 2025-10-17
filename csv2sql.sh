#!/usr/bin/env bash
set -euo pipefail

# -------- CONFIG --------
# Chemin Windows donné par toi
CSV_DIR_WIN='/mnt/c/Users/PC/Documents/FM_temp/FIFA16/csv'

# MySQL credentials
MYSQL_USER='root'
MYSQL_PASS='root'
#DB_NAME='fifatest'
DB_NAME='fifa16'
# Option : si ton dossier est déjà un chemin linux, tu peux mettre directement /mnt/...
# Le script va tenter de convertir un chemin Windows "C:\..." vers "/mnt/c/..."
# ------------------------

# Convert Windows path to WSL/Linux style if needed
convert_path() {
  local p="$1"
  # if contains backslash or drive letter, convert
  if [[ "$p" =~ ^[A-Za-z]:\\ ]]; then
    # Replace C:\something\... -> /mnt/c/something/...
    # 1) remove trailing backslashes
    p="${p%\\}"
    # 2) replace drive letter
    drive_lower=$(echo "${p:0:1}" | tr '[:upper:]' '[:lower:]')
    rest="${p:2}"
    # replace backslashes by slashes
    rest="${rest//\\//}"
    echo "/mnt/${drive_lower}/${rest}"
  else
    # assume it's already a linux path
    echo "$p"
  fi
}

CSV_DIR="$(convert_path "$CSV_DIR_WIN")"
echo "Utilisation du dossier CSV : $CSV_DIR"

# Check folder exists
if [ ! -d "$CSV_DIR" ]; then
  echo "ERREUR : dossier introuvable : $CSV_DIR"
  exit 1
fi

# Ensure mysql client allows local infile
MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS}"

# Create DB if not exists
echo "Création (si besoin) de la base ${DB_NAME}..."
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# Temporary working dir
TMPDIR="$(mktemp -d)"
trap "rm -rf \"$TMPDIR\"" EXIT

# Function to sanitize column names (make safe SQL identifiers)
sanitize_colname() {
  local col="$1"
  # trim spaces
  col="$(echo "$col" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  # replace sequences of non-alnum by underscore
  col="$(echo "$col" | sed -E 's/[^a-zA-Z0-9_]+/_/g')"
  # if starts with digit, prefix with c_
  if [[ "$col" =~ ^[0-9] ]]; then
    col="c_${col}"
  fi
  # lower-case to be consistent
  echo "${col,,}"
}

# Loop through CSV files
shopt -s nullglob
for csv in "$CSV_DIR"/*.csv "$CSV_DIR"/*.CSV; do
  echo "----------------------------------------"
  echo "Traitement du fichier : $csv"

  # Work on a cleaned copy
  basefile="$(basename "$csv")"
  tablename="$(basename "$csv" .csv)"
  tablename="$(basename "$tablename" .CSV)"   # handle uppercase ext
  # sanitize table name: replace spaces and bad chars
  tablename="$(echo "$tablename" | sed -E 's/[^a-zA-Z0-9_]+/_/g' | tr '[:upper:]' '[:lower:]')"

  clean="$TMPDIR/${basefile}.clean.txt"

  # 1) remove null bytes, convert CRLF -> LF, ensure UTF-8
  # Use dos2unix if available, otherwise sed to remove \r
  if command -v dos2unix > /dev/null 2>&1; then
    tr -d '\000' < "$csv" > "$clean"
    dos2unix "$clean" >/dev/null 2>&1 || true
  else
    # remove null bytes and CR
    tr -d '\000' < "$csv" | sed 's/\r$//' > "$clean"
  fi

  # 2) Ensure file is not empty
  if [ ! -s "$clean" ]; then
    echo "Fichier vide après nettoyage : $csv — saut."
    continue
  fi

  # 3) Read header line and build CREATE TABLE
  header_line=$(head -n 1 "$clean")
  # split by comma (CSV). If your CSV uses ; or tab, adjust here.
  # We'll attempt to auto-detect delimiter: comma, semicolon, or tab
  detected_delim=","
  if echo "$header_line" | grep -q $'\t'; then
    detected_delim=$'\t'
  elif echo "$header_line" | grep -q ';'; then
    detected_delim=';'
  else
    detected_delim=','
  fi

  # Build array of columns
  IFS="$detected_delim" read -r -a rawcols <<< "$header_line"

  cols_sql=()
  colnames=()
  for raw in "${rawcols[@]}"; do
    # remove surrounding quotes and spaces
    col=$(echo "$raw" | sed -e 's/^["'\'']//' -e 's/["'\'']$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    col_s=$(sanitize_colname "$col")
    # ensure uniqueness
    suffix=1
    orig="$col_s"
    while printf '%s\n' "${colnames[@]}" | grep -qx "$col_s"; do
      col_s="${orig}_$suffix"
      suffix=$((suffix+1))
    done
    colnames+=("$col_s")
    cols_sql+=("\`${col_s}\` TEXT")
  done

  # If header produced no columns (weird), fallback to generic
  if [ "${#cols_sql[@]}" -eq 0 ]; then
    echo "Impossible de détecter les colonnes dans $csv — création d'une table avec 1 colonne 'data'."
    cols_sql=(\`data\` TEXT)
    detected_delim=","
  fi

  create_stmt="DROP TABLE IF EXISTS \`${tablename}\`;\nCREATE TABLE \`${tablename}\` ("
  create_stmt+=$(IFS=,; echo "${cols_sql[*]}")
  create_stmt+=") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"

  echo "Création de la table \`${tablename}\`..."
  # Execute create statement
  $MYSQL_CMD -D "$DB_NAME" -e "$create_stmt"

  # 4) Import via LOAD DATA LOCAL INFILE
  # MySQL LOAD DATA expects the file path as seen by the MySQL client/server.
  # Using --local-infile=1 above and LOAD DATA LOCAL INFILE to read from client.
  echo "Import du CSV dans la table \`${tablename}\` (séparateur: $( [[ "$detected_delim" == $'\t' ]] && echo 'TAB' || echo "$detected_delim" ))..."
  # If delimiter is tab, use '\t' else the literal char
  if [ "$detected_delim" = $'\t' ]; then
    delim_escaped="\\t"
  else
    # escape backslashes and single quote for SQL
    delim_escaped=$(printf "%s" "$detected_delim" | sed -e "s/'/''/g" -e 's/\\/\\\\/g')
  fi

  # Use LOAD DATA LOCAL INFILE
  # IGNORE 1 LINES because first line is header
  # OPTIONALLY ENCLOSED BY '"' handles quoted fields
  load_sql="SET NAMES utf8mb4;\nLOAD DATA LOCAL INFILE '$(printf "%q" "$clean")' INTO TABLE \`${tablename}\` \
FIELDS TERMINATED BY '${delim_escaped}' \
OPTIONALLY ENCLOSED BY '\"' \
LINES TERMINATED BY '\n' \
IGNORE 1 LINES;"

  # Run the import (use -D to select DB)
  $MYSQL_CMD -D "$DB_NAME" -e "$load_sql"

  echo "Import terminé pour \`${tablename}\`."
done

echo "Tous les fichiers traités."
