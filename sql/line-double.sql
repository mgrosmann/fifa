#!/bin/bash
# ============================================
# SCRIPT : Handle duplicates FIFA14/FIFA15
# ============================================

# Configurations
F14_DB="FIFA14"
F15_DB="FIFA15"
MYSQL="mysql -uroot -proot -h127.0.0.1 -P5000"

# ---------- 1️⃣ FIFA14.playernames ----------
echo "💾 $F14_DB.playernames : backup and remove duplicates"

# Supprime fichier CSV existant
rm -f /tmp/playernames_duplicates.csv

# Backup des doublons
$MYSQL $F14_DB -e "
SELECT nameid, name
INTO OUTFILE '/tmp/playernames_duplicates.csv'
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
FROM playernames
WHERE nameid IN (
    SELECT nameid
    FROM playernames
    GROUP BY nameid
    HAVING COUNT(*) > 1
);
"

# Ajout colonne temporaire pour identifier les doublons
$MYSQL $F14_DB -e "
ALTER TABLE playernames
ADD COLUMN tmp_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY FIRST;
"

# Suppression des doublons
$MYSQL $F14_DB -e "
DELETE p
FROM playernames p
INNER JOIN (
    SELECT nameid, MIN(tmp_id) AS min_id
    FROM playernames
    GROUP BY nameid
    HAVING COUNT(*) > 1
) t ON p.nameid = t.nameid
WHERE p.tmp_id > t.min_id;
"

# Supprime la colonne temporaire
$MYSQL $F14_DB -e "
ALTER TABLE playernames
DROP COLUMN tmp_id;
"

echo "✅ $F14_DB.playernames duplicates handled"


# ---------- 2️⃣ FIFA15.teamplayerlinks ----------
echo "📌 $F15_DB.teamplayerlinks : backup and remove duplicates"

# Supprime fichier CSV existant
rm -f /tmp/teamplayerlinks_duplicates.csv

# Backup des doublons
$MYSQL $F15_DB -e "
SELECT playerid, teamid, position, jerseynumber
INTO OUTFILE '/tmp/teamplayerlinks_duplicates.csv'
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
FROM teamplayerlinks
WHERE (playerid, teamid) IN (
    SELECT playerid, teamid
    FROM teamplayerlinks
    GROUP BY playerid, teamid
    HAVING COUNT(*) > 1
);
"

# Ajout colonne temporaire pour identifier les doublons
$MYSQL $F15_DB -e "
ALTER TABLE teamplayerlinks
ADD COLUMN tmp_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY FIRST;
"

# Suppression des doublons
$MYSQL $F15_DB -e "
DELETE tpl
FROM teamplayerlinks tpl
INNER JOIN (
    SELECT playerid, teamid, MIN(tmp_id) AS min_id
    FROM teamplayerlinks
    GROUP BY playerid, teamid
    HAVING COUNT(*) > 1
) t ON tpl.playerid = t.playerid AND tpl.teamid = t.teamid
WHERE tpl.tmp_id > t.min_id;
"

# Supprime la colonne temporaire
$MYSQL $F15_DB -e "
ALTER TABLE teamplayerlinks
DROP COLUMN tmp_id;
"

echo "✅ $F15_DB.teamplayerlinks duplicates handled"
