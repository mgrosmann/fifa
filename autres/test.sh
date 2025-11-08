#!/bin/bash
read -p "Nom de la base de données (juste les 2 chiffres ex: 14, 15) : " DB
cmd="mysql -uroot -proot -h127.0.0.1 -DFIFA${DB} -P5000 -A"
txt_dir="/mnt/c/github/txt/FIFA${DB}/"
target_dir="/mnt/c/github/txt/FIFA${DB}/csv/"
#partie convertir utf16 en utf8 et txt en csv
mkdir -p "$target_dir"
for file in "$txt_dir"/*.txt; do
    if [ -f "$file" ]; then
        base_name=$(basename "$file" .txt)
        tmp_csv="/tmp/${base_name}.csv"
        iconv -f UTF-16 -t UTF-8 "$file" -o "$tmp_csv" 2>/dev/null || cp "$file" "$tmp_csv"
        dos2unix "$tmp_csv"
        tr '\t' ';' < "$tmp_csv" > "$target_dir/${base_name}.csv"
        rm "$tmp_csv"
    fi
done
#partie csv a sql
# requete sql pour créer des tables à partir de fichiers csv dans un répertoire
create_table_sql="create_table.sql"
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        echo "CREATE TABLE \`$table_name\` (test VARCHAR(255));" >> "$create_table_sql"
    fi
done
$cmd < "$create_table_sql"
# requete sql pour créer les colonnes dans les tables à partir de fichiers csv dans un répertoire
create_columns_sql="create_columns.sql"
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        head -n1 "$file" | tr ';' '\n' | while IFS= read -r column; do
            echo "ALTER TABLE \`$table_name\` ADD COLUMN IF NOT EXISTS \`$column\` VARCHAR(255);" >> "$create_columns_sql"
        done
    fi
done
$cmd < "$create_columns_sql"
#supprimer la colonne test des tables créées
delete_columns_sql="delete_columns.sql"
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        echo "ALTER TABLE \`$table_name\` DROP COLUMN IF EXISTS \`test\`;" >> "$delete_columns_sql"
      fi
done
$cmd < "$delete_columns_sql"
#load data pour insérer les données des fichiers csv dans les tables
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        $cmd -e "LOAD DATA LOCAL INFILE '$file' INTO TABLE \`$table_name\` FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' IGNORE 1 LINES;"
      fi
done
