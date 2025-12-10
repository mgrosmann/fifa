#!/bin/bash
set -euo pipefail

MYSQL_CMD="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA1518 -N -s"
CSV_NAMES="/mnt/c/github/fifa/player/import/playernames.csv"
CSV_PLAYERS="/mnt/c/github/fifa/player/import/players.csv"

echo "=== IMPORT ULTRA-RAPIDE: playernames & players ==="

# ---------------------------------------------------------
# 0) Harmonisation des collations
# ---------------------------------------------------------
$MYSQL_CMD -e "
ALTER TABLE playernames MODIFY name VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE players MODIFY firstnameid INT, MODIFY lastnameid INT, MODIFY commonnameid INT, MODIFY playerjerseynameid INT;
DROP TABLE IF EXISTS tmp_names;
"

echo "⚡ Collations harmonisées"

# ---------------------------------------------------------
# 1) TABLE TEMPORAIRE POUR LES NOMS
# ---------------------------------------------------------
$MYSQL_CMD -e "
CREATE TABLE tmp_names (
    playerid INT,
    firstname VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    lastname VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    commonname VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    playerjerseyname VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
);
LOAD DATA LOCAL INFILE '$CSV_NAMES'
INTO TABLE tmp_names
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

echo "✔ tmp_names importé"

# ---------------------------------------------------------
# 2) CREATION DES INDEX SI ABSENTS
# ---------------------------------------------------------
create_index_if_missing() {
  local table="$1"
  local index="$2"
  local columns="$3"
  exists=$($MYSQL_CMD -e "SELECT 1 FROM information_schema.STATISTICS WHERE table_schema='FIFA1518' AND table_name='$table' AND index_name='$index' LIMIT 1;")
  if [[ -z "$exists" ]]; then
      echo "→ Création index $index sur $table($columns)"
      $MYSQL_CMD -e "ALTER TABLE $table ADD INDEX $index ($columns);"
  else
      echo "→ Index $index déjà existant sur $table"
  fi
}

# Index tmp_names
create_index_if_missing "tmp_names" "idx_firstname" "firstname"
create_index_if_missing "tmp_names" "idx_lastname" "lastname"
create_index_if_missing "tmp_names" "idx_common" "commonname"
create_index_if_missing "tmp_names" "idx_jname" "playerjerseyname"

# Index playernames
create_index_if_missing "playernames" "idx_name" "name(100)"

# Index players
create_index_if_missing "players" "idx_pid" "playerid"

echo "⚡ Vérification/Création des index terminée"

# ---------------------------------------------------------
# 3) PRÉPARER LES NAMEID LIBRES DANS UNE TABLE TEMPORAIRE
# ---------------------------------------------------------
$MYSQL_CMD -e "
DROP TEMPORARY TABLE IF EXISTS tmp_free_nameid;
CREATE TEMPORARY TABLE tmp_free_nameid (nameid INT PRIMARY KEY);

-- Génère les nameid libres à partir de 1 jusqu'au max existant + nombre de noms CSV
INSERT INTO tmp_free_nameid (nameid)
SELECT n
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1) t1
    CROSS JOIN (SELECT 0 UNION ALL SELECT 1) t2
    CROSS JOIN (SELECT 0 UNION ALL SELECT 1) t3
    CROSS JOIN (SELECT @row := 0) r
) numbers
WHERE n NOT IN (SELECT nameid FROM playernames);
"

echo "⚡ Table temporaire des nameid libres créée"

# ---------------------------------------------------------
# 4) INSERTION DES NOUVEAUX NOMS AVEC NAMEID MINIMAL
# ---------------------------------------------------------
$MYSQL_CMD -e "
INSERT INTO playernames (name, nameid, commentaryid)
SELECT n.name, f.nameid, 900000
FROM (
    SELECT DISTINCT firstname AS name FROM tmp_names WHERE firstname IS NOT NULL AND firstname != '' AND firstname != 'NULL'
    UNION
    SELECT DISTINCT lastname FROM tmp_names WHERE lastname IS NOT NULL AND lastname != '' AND lastname != 'NULL'
    UNION
    SELECT DISTINCT commonname FROM tmp_names WHERE commonname IS NOT NULL AND commonname != '' AND commonname != 'NULL'
    UNION
    SELECT DISTINCT playerjerseyname FROM tmp_names WHERE playerjerseyname IS NOT NULL AND playerjerseyname != '' AND playerjerseyname != 'NULL'
) n
LEFT JOIN playernames pn ON pn.name COLLATE utf8mb4_general_ci = n.name COLLATE utf8mb4_general_ci
JOIN tmp_free_nameid f ON f.nameid > 0
WHERE pn.name IS NULL
LIMIT 1000000;
"

echo "✔ Noms insérés avec le plus petit nameid disponible"

# ---------------------------------------------------------
# 5) SUPPRESSION MASSIVE DES PLAYERS EXISTANTS
# ---------------------------------------------------------
$MYSQL_CMD -e "
DELETE p
FROM players p
JOIN tmp_names n ON n.playerid = p.playerid;
"

echo "✔ Suppression terminée"

# ---------------------------------------------------------
# 6) IMPORT MASSIF DES PLAYERS
# ---------------------------------------------------------
$MYSQL_CMD -e "
LOAD DATA LOCAL INFILE '$CSV_PLAYERS'
INTO TABLE players
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"

echo "✔ players importé"

# ---------------------------------------------------------
# 7) MISE À JOUR MASSIVE DES nameid VIA JOIN
# ---------------------------------------------------------
$MYSQL_CMD -e "
UPDATE players p
JOIN tmp_names t ON t.playerid = p.playerid
LEFT JOIN playernames fn ON fn.name COLLATE utf8mb4_general_ci = t.firstname COLLATE utf8mb4_general_ci
LEFT JOIN playernames ln ON ln.name COLLATE utf8mb4_general_ci = t.lastname COLLATE utf8mb4_general_ci
LEFT JOIN playernames cn ON cn.name COLLATE utf8mb4_general_ci = t.commonname COLLATE utf8mb4_general_ci
LEFT JOIN playernames jn ON jn.name COLLATE utf8mb4_general_ci = t.playerjerseyname COLLATE utf8mb4_general_ci
SET
  p.firstnameid = COALESCE(fn.nameid, 0),
  p.lastnameid = COALESCE(ln.nameid, 0),
  p.commonnameid = COALESCE(cn.nameid, 0),
  p.playerjerseynameid = COALESCE(jn.nameid, 0);
"

echo "✔ nameid mis à jour pour tous les players"
echo "🎉 IMPORT ULTRA-RAPIDE TERMINÉ (collations harmonisées, index vérifiés, nameid minimal)"
