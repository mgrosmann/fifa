-- ============================================
-- SCRIPT SQL : conversion ID + PRIMARY KEY + INDEX optimisés
-- ============================================
-- ⚠️ Sauvegarde recommandée avant exécution
-- ============================================

-- ---------- 1️⃣ TABLE : players ----------
ALTER TABLE players
MODIFY COLUMN playerid INT UNSIGNED NOT NULL,
MODIFY COLUMN firstnameid INT UNSIGNED NULL,
MODIFY COLUMN lastnameid INT UNSIGNED NULL;

-- Ajout PK si inexistante
SET @pk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'players'
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);
SET @sql := IF(@pk_exists = 0,
  'ALTER TABLE players ADD PRIMARY KEY (playerid);',
  'SELECT "PK already exists for players";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Index pour accélérer les jointures sur les noms
CREATE INDEX IF NOT EXISTS idx_players_firstnameid ON players(firstnameid);
CREATE INDEX IF NOT EXISTS idx_players_lastnameid  ON players(lastnameid);
CREATE INDEX IF NOT EXISTS idx_players_playerid  ON players(playerid);


-- ---------- 2️⃣ TABLE : playernames ----------
ALTER TABLE playernames
MODIFY COLUMN nameid INT UNSIGNED NOT NULL;

-- Ajout PK si inexistante
SET @pk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'playernames'
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);
SET @sql := IF(@pk_exists = 0,
  'ALTER TABLE playernames ADD PRIMARY KEY (nameid);',
  'SELECT "PK already exists for playernames";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- ---------- 3️⃣ TABLE : teamplayerlinks ----------
ALTER TABLE teamplayerlinks
MODIFY COLUMN playerid INT UNSIGNED NOT NULL,
MODIFY COLUMN teamid   INT UNSIGNED NOT NULL,
MODIFY COLUMN jerseynumber INT UNSIGNED NULL;

-- PK composite si absente
SET @pk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'teamplayerlinks'
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);
SET @sql := IF(@pk_exists = 0,
  'ALTER TABLE teamplayerlinks ADD PRIMARY KEY (playerid, teamid);',
  'SELECT "PK already exists for teamplayerlinks";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Index secondaires pour jointures fréquentes
CREATE INDEX IF NOT EXISTS idx_tpl_playerid ON teamplayerlinks(playerid);
CREATE INDEX IF NOT EXISTS idx_tpl_teamid   ON teamplayerlinks(teamid);


-- ---------- 4️⃣ TABLE : leagues ----------
ALTER TABLE leagues
MODIFY COLUMN leagueid INT UNSIGNED NOT NULL;

-- Ajout PK si inexistante
SET @pk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'leagues'
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);
SET @sql := IF(@pk_exists = 0,
  'ALTER TABLE leagues ADD PRIMARY KEY (leagueid);',
  'SELECT "PK already exists for leagues";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- ---------- 5️⃣ TABLE : leagueteamlinks ----------
ALTER TABLE leagueteamlinks
MODIFY COLUMN teamid   INT UNSIGNED NOT NULL,
MODIFY COLUMN leagueid INT UNSIGNED NOT NULL;

-- PK composite si absente
SET @pk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'leagueteamlinks'
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);
SET @sql := IF(@pk_exists = 0,
  'ALTER TABLE leagueteamlinks ADD PRIMARY KEY (teamid, leagueid);',
  'SELECT "PK already exists for leagueteamlinks";');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Index secondaires utiles
CREATE INDEX IF NOT EXISTS idx_ltl_teamid   ON leagueteamlinks(teamid);
CREATE INDEX IF NOT EXISTS idx_ltl_leagueid ON leagueteamlinks(leagueid);


-- ---------- 6️⃣ Vérification finale ----------
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('players','playernames','teamplayerlinks','leagueteamlinks','leagues')
  AND COLUMN_NAME RLIKE 'id';

SELECT '✅ Colonnes converties en INT UNSIGNED, PK et index secondaires créés avec succès' AS status;
