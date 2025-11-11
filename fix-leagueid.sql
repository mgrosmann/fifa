-- ============================================
-- Script SQL : Correction leagues FIFA14/15/16
-- ============================================

-- ---------- FIFA14 ----------
-- Germany 2. Bundesliga
UPDATE FIFA14.leagues
SET 
    leaguename = 'Germany 2. Bundesliga (2)',
    level = 2,
    leagueid = 20,
    leaguetimeslice = 6,
    iswithintransferwindow = 1
WHERE countryid = 21 AND level NOT IN (1);

-- Argentina Primera División
UPDATE FIFA14.leagues
SET 
    leaguename = 'Argentina Primera División (1)',
    level = 1,
    leagueid = 353,
    leaguetimeslice = 6,
    iswithintransferwindow = 0
WHERE countryid = 52;

-- ---------- FIFA15 ----------
-- Argentina Primera División
UPDATE FIFA15.leagues
SET 
    leaguename = 'Argentina Primera División (1)',
    level = 1,
    leagueid = 353,
    leaguetimeslice = 3,
    iswithintransferwindow = 0
WHERE countryid = 52;

-- Segunda A / Liga MX
UPDATE FIFA15.leagues
SET 
    leaguename = 'Segunda A Liga MX (1)',
    level = 1,
    leagueid = 341,
    leaguetimeslice = 7,
    iswithintransferwindow = 0
WHERE countryid = 83;

-- ---------- FIFA16 ----------
-- Germany 2. Bundesliga
UPDATE FIFA16.leagues
SET 
    leaguename = 'Germany 2. Bundesliga (2)',
    level = 2,
    leagueid = 20,
    leaguetimeslice = 5,
    iswithintransferwindow = 1
WHERE countryid = 21 AND level NOT IN (1);

-- Argentina Primera División
UPDATE FIFA16.leagues
SET 
    leaguename = 'Argentina Primera División (1)',
    level = 1,
    leagueid = 353,
    leaguetimeslice = 8,
    iswithintransferwindow = 0
WHERE countryid = 52;

-- ---------- Vérification ----------
SELECT countryid, leaguename, level, leagueid, leaguetimeslice, iswithintransferwindow
FROM FIFA14.leagues
WHERE countryid IN (52) or leaguename like 'Germany 2. Bundesliga%';

SELECT countryid, leaguename, level, leagueid, leaguetimeslice, iswithintransferwindow
FROM FIFA15.leagues
WHERE countryid IN (52,83);

SELECT countryid, leaguename, level, leagueid, leaguetimeslice, iswithintransferwindow
FROM FIFA16.leagues
WHERE countryid IN (52) or leaguename like 'Germany 2. Bundesliga%';

-- ✅ Toutes les ligues corrigées
