#!/bin/bash
# ============================================
# SCRIPT : Handle duplicates & fix playernames
# ============================================

DB14="FIFA14"
DB15="FIFA15"
DB18="FIFA1518"
MYSQL="mysql -uroot -proot -h127.0.0.1 -P5000 --local-infile=1"

# ---------- 1️⃣ FIFA15.teamplayerlinks ----------
echo "📌 $DB15.teamplayerlinks : handle duplicates"

$MYSQL -D $DB15 -e "
ALTER TABLE teamplayerlinks
ADD COLUMN tmp_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

DELETE tpl
FROM teamplayerlinks tpl
INNER JOIN (
    SELECT MIN(tmp_id) AS keep_id, playerid, teamid
    FROM teamplayerlinks
    GROUP BY playerid, teamid
    HAVING COUNT(*) > 1
) t ON tpl.playerid = t.playerid AND tpl.teamid = t.teamid
WHERE tpl.tmp_id <> t.keep_id;

ALTER TABLE teamplayerlinks
DROP COLUMN tmp_id;
"

echo "✅ $DB15.teamplayerlinks duplicates handled"


# ---------- 2️⃣ FIFA14.playernames ----------
echo "💾 $DB14.playernames : fix lines with nameid = 900000"

# Supprimer les lignes problématiques
$MYSQL -D $DB14 -e "
DELETE FROM playernames
WHERE nameid = 900000;
"

# Réécriture du CSV corrigé
cat > /tmp/fix_csv14.csv <<EOL
A. Cole;900000;2
De Rose;900000;4904
Jesús Armando;900000;9786
EOL

# Réinsertion
$MYSQL -D $DB14 -e "
LOAD DATA LOCAL INFILE '/tmp/fix_csv14.csv'
INTO TABLE playernames
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
(name, commentaryid, nameid);
"

echo "✅ $DB14.playernames fixed"


# ---------- 3️⃣ FIFA1518.playernames ----------
echo "💾 $DB18.playernames : fix lines with nameid = 900000"

# Supprimer les lignes problématiques
$MYSQL -D $DB18 -e "
DELETE FROM playernames
WHERE nameid = 900000;
"

# Réécriture du CSV corrigé
cat > /tmp/fix_csv18.csv <<EOL
Kubán ;900000;14555
Niraj;900000;9892
Gabriel;900000;7928
EOL

# Réinsertion
$MYSQL -D $DB18 -e "
LOAD DATA LOCAL INFILE '/tmp/fix_csv18.csv'
INTO TABLE playernames
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
(name, commentaryid, nameid);
"

echo "✅ $DB18.playernames fixed"
