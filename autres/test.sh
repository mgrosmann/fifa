#!/bin/bash
ls -d /mnt/c/github/txt/*/
read -p "voici les database dispon choisisiez votre db (entrée juste les 2 chiffres ex: 14, 15) : " 
DB="FIFA15"
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
        echo "converision $file to $target_dir/${base_name}.csv"
    fi
done
#partie csv a sql
# requete sql pour créer des tables à partir de fichiers csv dans un répertoire
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        $cmd -e "CREATE TABLE \`$table_name\` (test VARCHAR(255));"
        echo "Table $table_name créée."
    fi
done
# requete sql pour créer les colonnes dans les tables à partir de fichiers csv dans un répertoire
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        head -n1 "$file" | tr ';' '\n' | while IFS= read -r column; do
        $cmd -e "ALTER TABLE \`$table_name\` ADD COLUMN IF NOT EXISTS \`$column\` VARCHAR(255);"
        echo "Colonne $column ajoutée à la table $table_name."
        done
    fi
done
#supprimer la colonne test des tables créées
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        $cmd -e "ALTER TABLE \`$table_name\` DROP COLUMN IF EXISTS \`test\`;"
        echo "Colonne test supprimée de la table $table_name."
      fi
done
#load data pour insérer les données des fichiers csv dans les tables
for file in "$target_dir"/*.csv; do
    if [ -f "$file" ]; then
        table_name=$(basename "$file" .csv)
        $cmd -e "LOAD DATA LOCAL INFILE '$file' INTO TABLE \`$table_name\` FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' IGNORE 1 LINES;"
        echo "Données insérées dans la table $table_name à partir de $file."
      fi
done