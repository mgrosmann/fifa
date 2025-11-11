-- ============================================
-- Script SQL : conversion ID en INT + PK + INDEX
-- Sauvegarde recommandée avant exécution
-- ============================================

-- ---------- 1️⃣ players ----------
ALTER TABLE players
MODIFY COLUMN playerid INT UNSIGNED NOT NULL;

-- Ajouter PK si inexistante
SET @pk_exists := (SELECT COUNT(*) 
                   FROM information_schema.TABLE_CONSTRAINTS 
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'players'
                     AND CONSTRAINT_TYPE = 'PRIMARY KEY');

SET @sql := IF(@pk_exists = 0, 
               'ALTER TABLE players ADD PRIMARY KEY (playerid);', 
               'SELECT "PK already exists for players";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------- 2️⃣ teamplayerlinks ----------
ALTER TABLE teamplayerlinks
MODIFY COLUMN playerid INT UNSIGNED NOT NULL,
MODIFY COLUMN teamid   INT UNSIGNED NOT NULL;

-- Clé primaire composite (playerid + teamid)
SET @pk_exists := (SELECT COUNT(*) 
                   FROM information_schema.TABLE_CONSTRAINTS 
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'teamplayerlinks'
                     AND CONSTRAINT_TYPE = 'PRIMARY KEY');

SET @sql := IF(@pk_exists = 0, 
               'ALTER TABLE teamplayerlinks ADD PRIMARY KEY (playerid, teamid);', 
               'SELECT "PK already exists for teamplayerlinks";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Index supplémentaire sur teamid seul pour accès rapide
SET @idx_exists := (SELECT COUNT(*) 
                    FROM information_schema.STATISTICS 
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'teamplayerlinks'
                      AND INDEX_NAME = 'idx_teamid');
SET @sql := IF(@idx_exists = 0, 
               'CREATE INDEX idx_teamid ON teamplayerlinks(teamid);',
               'SELECT "Index idx_teamid already exists";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------- 3️⃣ leagueteamlinks ----------
ALTER TABLE leagueteamlinks
MODIFY COLUMN teamid   INT UNSIGNED NOT NULL,
MODIFY COLUMN leagueid INT UNSIGNED NOT NULL;

-- Clé primaire composite (teamid + leagueid)
SET @pk_exists := (SELECT COUNT(*) 
                   FROM information_schema.TABLE_CONSTRAINTS 
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'leagueteamlinks'
                     AND CONSTRAINT_TYPE = 'PRIMARY KEY');

SET @sql := IF(@pk_exists = 0, 
               'ALTER TABLE leagueteamlinks ADD PRIMARY KEY (teamid, leagueid);', 
               'SELECT "PK already exists for leagueteamlinks";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Index supplémentaire sur teamid seul
SET @idx_exists := (SELECT COUNT(*) 
                    FROM information_schema.STATISTICS 
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'leagueteamlinks'
                      AND INDEX_NAME = 'idx_ltl_teamid');
SET @sql := IF(@idx_exists = 0, 
               'CREATE INDEX idx_ltl_teamid ON leagueteamlinks(teamid);',
               'SELECT "Index idx_ltl_teamid already exists";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------- 4️⃣ Vérification ----------
SELECT 'players' AS table_name, COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'players'
  AND COLUMN_NAME IN ('playerid');

SELECT 'teamplayerlinks' AS table_name, COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teamplayerlinks'
  AND COLUMN_NAME IN ('playerid', 'teamid');

SELECT 'leagueteamlinks' AS table_name, COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'leagueteamlinks'
  AND COLUMN_NAME IN ('teamid', 'leagueid');

SELECT '✅ Toutes les colonnes converties en INT UNSIGNED, PK appliquées et index ajoutés' AS status;
