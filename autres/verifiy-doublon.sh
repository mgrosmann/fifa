#
SELECT col, COUNT(*) AS nb
FROM table
GROUP BY col
HAVING nb > 1;

-- Exemple 2 : doublons sur plusieurs colonnes (composite)
SELECT playerid, teamid, COUNT(*) AS nb
FROM teamplayerlinks
GROUP BY playerid, teamid
HAVING nb > 1;