#!/bin/bash
OUTFILE="playernames_export.txt"
DB="fifa14"
cmd="mysql -uroot -proot -h127.0.0.1 -D $DB -A -e"

echo "=== ⚙️ Préparation de l'export avec nameid=0 ==="

$cmd "
-- 1️⃣ Désactiver temporairement l'AUTO_INCREMENT
ALTER TABLE playernames MODIFY COLUMN nameid INT;

-- 2️⃣ Recréer la ligne vide si supprimée
INSERT IGNORE INTO playernames (nameid, name, commentaryid) VALUES (0, '', 900000);
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
#SET nameid = (SELECT MAX(nameid) + 1 FROM (SELECT nameid FROM playernames) AS sub)
#WHERE name = '';