#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8
IFS=$'\n\t'

# ===================================================================
# 🏆 Script universel : Import FIFA TXT → MySQL
# ===================================================================

ROOT="/mnt/c/Users/PC/Documents/FM_temp"

echo "📂 Dossiers FIFA disponibles dans $ROOT :"
select SUBDIR in "$ROOT"/*/; do
  [ -n "$SUBDIR" ] && break
done

DB_NAME=$(basename "$SUBDIR")
SOURCE="$SUBDIR"
echo "📁 Dossier sélectionné : $SOURCE"
echo "🗄️  Base MySQL : $DB_NAME"

# --- Config MySQL ---
read -s -p "Mot de passe MySQL root : " MYSQL_PASS
echo
MYSQL_USER="root"
MYSQL_CMD="mysql --local-infile=1 -u${MYSQL_USER} -p${MYSQL_PASS}"

# --- Création de la base ---
echo "🔧 Création de la base \`$DB_NAME\` si elle n'existe pas..."
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

TMPDIR="$(mktemp -d)"
trap "rm -rf \"$TMPDIR\"" EXIT

# --- Fonction de nettoyage des noms de colonnes ---
sanitize_colname() {
  local col="$1"
  col="$(echo "$col" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  col="$(echo "$col" | sed -E 's/[^a-zA-Z0-9_]+/_/g')"
  [[ "$col" =~ ^[0-9] ]] && col="c_${col}"
  echo "${col,,}"
}

# ===================================================================
# 🔁 Boucle sur les fichiers TXT du dossier
# ===================================================================
shopt -s nullglob
for file in "$SOURCE"/*.txt; do
  echo "----------------------------------------"
  echo "📄 Traitement : $file"
  basefile=$(basename "$file" .txt)
  tablename=$(echo "$basefile" | sed -E 's/[^a-zA-Z0-9_]+/_/g' | tr '[:upper:]' '[:lower:]')

  tmp_utf8="$TMPDIR/${basefile}.utf8"
  # Conversion UTF-16 → UTF-8 (DB Master exporte souvent en UTF-16LE)
  iconv -f UTF-16 -t UTF-8 "$file" -o "$tmp_utf8" 2>/dev/null || cp "$file" "$tmp_utf8"

  # Nettoyage (CRLF → LF, suppression NUL)
  tr -d '\000' < "$tmp_utf8" | sed 's/\r$//' > "${tmp_utf8}.clean"

  # Vérifie que le fichier n'est pas vide
  if [ ! -s "${tmp_utf8}.clean" ]; then
    echo "⚠️ Fichier vide, ignoré : $file"
    continue
  fi

  # Lecture de la première ligne (entêtes)
  header_line=$(head -n 1 "${tmp_utf8}.clean")

  # Détection du séparateur (tab, point-virgule, espace multiple)
  detected_delim=$'\t'
  if echo "$header_line" | grep -q ';'; then
    detected_delim=';'
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
    echo "⚠️ Aucune colonne trouvée dans $file, création table générique."
    cols_sql=(\`data\` TEXT)
  fi

  create_stmt="DROP TABLE IF EXISTS \`${tablename}\`;"
  create_stmt+="CREATE TABLE \`${tablename}\` ($(IFS=,; echo "${cols_sql[*]}")) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"

  echo "🧱 Création de la table \`${tablename}\`..."
  $MYSQL_CMD -D "$DB_NAME" -e "$create_stmt"

  # Import des données
  echo "📥 Import des données depuis $file..."
  if [ "$detected_delim" = $'\t' ]; then
    delim_escaped="\\t"
  else
    delim_escaped=$(printf "%s" "$detected_delim" | sed "s/'/''/g")
  fi

  load_sql="SET NAMES utf8mb4;
LOAD DATA LOCAL INFILE '$(printf "%q" "${tmp_utf8}.clean")'
INTO TABLE \`${tablename}\`
FIELDS TERMINATED BY '${delim_escaped}'
OPTIONALLY ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;"

  if ! $MYSQL_CMD -D "$DB_NAME" -e "$load_sql"; then
    echo "⚠️ Erreur d’import pour $file (probablement format irrégulier)."
  else
    echo "✅ Import réussi pour \`${tablename}\`."
  fi
done

echo "🎉 Import terminé pour la base \`$DB_NAME\`."