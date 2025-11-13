#!/bin/bash
OUTFILE="playernames_export.txt"
DB="fifa14"
cmd="mysql -uroot -proot -h127.0.0.1 -D $DB -A -e"
query="INSERT IGNORE INTO playernames (nameid, name, commentaryid) VALUES (0, '', 900000);"
query="SET nameid = 0 FROM playernames WHERE name = '';"
echo "=== ⚙️ Préparation de l'export avec nameid=0 ==="
read -p "la valeur de nameid=0 a été supprimer (1) ou modifiée (2) ? " choice
if choice == "1"; then
    echo "✅ La ligne vide a été supprimée, on la recrée"
    query="INSERT IGNORE INTO playernames (nameid, name, commentaryid) VALUES (0, '', 900000);"
elif choice == "2"; then
    echo "✅ La ligne vide existe mais la valeur de nameid a été modifiée, on la remet à 0"
    query="SET nameid = 0 FROM playernames WHERE name = '';"
else
    echo "❌ Choix invalide, quittez et recommencez"
    exit 1
fi
$cmd "
-- 1️⃣ Désactiver temporairement l'AUTO_INCREMENT
ALTER TABLE playernames MODIFY COLUMN nameid INT;

-- 2️⃣ Recréer la ligne vide si supprimée ou modifié
$query
"

# 3️⃣ Export simple
$cmd "SELECT * FROM playernames;" > "$OUTFILE"

# 4️⃣ Conversion en UTF-16 si besoin
iconv -f UTF-8 -t UTF-16LE "$OUTFILE" > "${OUTFILE%.*}_utf16.txt"

# 5️⃣ Restauration du champ AUTO_INCREMENT
$cmd "ALTER TABLE playernames MODIFY COLUMN nameid INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY;"

echo "✅ Export terminé proprement avec nameid=0 dans le dump"
#pour table.sql
#ALTER TABLE playernames MODIFY COLUMN nameid INT;
#UPDATE playernames
#SET nameid = (SELECT MAX(nameid) + 1 FROM (SELECT nameid FROM playernames) AS sub) WHERE name = '';