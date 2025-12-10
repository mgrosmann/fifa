#!/bin/bash
set -euo pipefail

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -Dtest1 -N -s"

CSV_NAMES="/mnt/c/github/fifa/player/import/playernames.csv"
CSV_PLAYERS="/mnt/c/github/fifa/player/import/players.csv"

echo "=== ULTRA IMPORT: playernames & players ==="

# ---------------------------------------------------------
# 1) CRÉATION TABLE TEMP POUR NOMS
# ---------------------------------------------------------
$MYSQL_CMD -e "
DROP TABLE IF EXISTS tmp_names;
CREATE TABLE tmp_names (
    playerid INT,
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    commonname VARCHAR(200),
    playerjerseyname VARCHAR(200)
);
LOAD DATA LOCAL INFILE '$CSV_NAMES'
INTO TABLE tmp_names
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

echo "✔ tmp_names importé"

# ---------------------------------------------------------
# 2) CRÉATION INDEX POUR RAPIDITÉ
# ---------------------------------------------------------
$MYSQL_CMD -e "
ALTER TABLE tmp_names ADD INDEX idx_firstname (firstname);
ALTER TABLE tmp_names ADD INDEX idx_lastname (lastname);
ALTER TABLE tmp_names ADD INDEX idx_common (commonname);
ALTER TABLE tmp_names ADD INDEX idx_jname (playerjerseyname);
ALTER TABLE playernames ADD INDEX idx_name (name(100));
ALTER TABLE players ADD INDEX idx_pid (playerid);
"

echo "⚡ Index créés"

# ---------------------------------------------------------
# 3) INSERTION DES NOUVEAUX NOMS DANS playernames
# ---------------------------------------------------------
echo "📥 Insertion massive des nouveaux noms"

$MYSQL_CMD -e "
INSERT INTO playernames (name, commentaryid)
SELECT DISTINCT n.name, 900000
FROM (
    SELECT firstname AS name FROM tmp_names WHERE firstname IS NOT NULL AND firstname!='' AND firstname!='NULL'
    UNION
    SELECT lastname FROM tmp_names WHERE lastname IS NOT NULL AND lastname!='' AND lastname!='NULL'
    UNION
    SELECT commonname FROM tmp_names WHERE commonname IS NOT NULL AND commonname!='' AND commonname!='NULL'
    UNION
    SELECT playerjerseyname FROM tmp_names WHERE playerjerseyname IS NOT NULL AND playerjerseyname!='' AND playerjerseyname!='NULL'
) n
LEFT JOIN playernames pn ON pn.name = n.name
WHERE pn.name IS NULL;
"

echo "✔ Noms insérés si absents"

# ---------------------------------------------------------
# 4) SUPPRESSION MASSIVE DES PLAYERS EXISTANTS
# ---------------------------------------------------------
echo "🗑 Suppression massive des players existants"

$MYSQL_CMD -e "
DELETE p
FROM players p
JOIN tmp_names n ON n.playerid = p.playerid;
"

echo "✔ Suppression terminée"

# ---------------------------------------------------------
# 5) LOAD DATA PLAYERS DIRECTEMENT
# ---------------------------------------------------------
echo "📥 Import players.csv → players"

$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_PLAYERS'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

echo "✔ players importé"

# ---------------------------------------------------------
# 6) UPDATE MASSIVE DES nameid
# ---------------------------------------------------------
echo "🧠 Mise à jour massive des nameid via JOIN"

$MYSQL_CMD -e "
UPDATE players p
JOIN tmp_names t ON t.playerid = p.playerid
LEFT JOIN playernames fn ON fn.name = t.firstname
LEFT JOIN playernames ln ON ln.name = t.lastname
LEFT JOIN playernames cn ON cn.name = t.commonname
LEFT JOIN playernames jn ON jn.name = t.playerjerseyname
SET
  p.firstnameid = COALESCE(fn.nameid, 0),
  p.lastnameid = COALESCE(ln.nameid, 0),
  p.commonnameid = COALESCE(cn.nameid, 0),
  p.playerjerseynameid = COALESCE(jn.nameid, 0);
"

echo "✔ nameid mis à jour pour tous les players"

echo "🎉 IMPORT ULTRA-RAPIDE TERMINÉ"
