--13 : Premier League, 14 : Championship, 60 : League One, 61 : League Two, 
--16 ligue 1, 17 : ligue 2, 19 : Bundesliga, 20 : 2. Bundesliga,
--31 : Serie A, 32 : Serie B, 53 : Liga BBVA, 54 : Liga Adelante
--countryid 14 : Angleterre, 18 : France, 21 : Allemagne, 27 : Italie, 45 : Espagne
------------------------------------------------------------------
-- Afficher le nombre d'équipes pour chaque championnat ciblé
SELECT l.leagueid, l.level, COUNT(ltl.teamid) AS nb_equipes
FROM leagues l
LEFT JOIN leagueteamlinks ltl ON l.leagueid = ltl.leagueid
WHERE l.leagueid IN (13,14,60,61,16,17,19,20,31,32,53,54)
GROUP BY l.leagueid, l.level
ORDER BY l.leagueid;
-- Liste des équipes présentes dans plus d’un championnat
SELECT t.teamid, t.teamname, GROUP_CONCAT(ltl.leagueid ORDER BY l.level ASC SEPARATOR ',') AS leagues
FROM teams t
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
WHERE l.countryid IN (34,14,18,21,27,45,38)
GROUP BY t.teamid, t.teamname
HAVING COUNT(DISTINCT ltl.leagueid) > 1;
-- Afficher les clubs sans championnat
SELECT t.teamid, t.teamname
FROM teams t
LEFT JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.teamid IS NULL
ORDER BY t.teamid ASC;
-- Remplacer l'équipe <OLD_TEAMID> par <NEW_TEAMID> dans la ligue <LEAGUEID>
UPDATE leagueteamlinks
SET teamid = <NEW_TEAMID> --equipe libre
WHERE teamid = <OLD_TEAMID>  AND leagueid = <LEAGUEID>;
-- equipe doublon ⬆️