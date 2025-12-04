--13 : Premier League, 14 : Championship, 60 : League One, 61 : League Two, 
--16 ligue 1, 17 : ligue 2, 19 : Bundesliga, 20 : 2. Bundesliga,
--31 : Serie A, 32 : Serie B, 53 : Liga BBVA, 54 : Liga Adelante
--countryid 14 : Angleterre, 18 : France, 21 : Allemagne, 27 : Italie, 45 : Espagne
--place 20 et 20 france, 18 et 18 allemagne, italy 20 et 22, espagne 20 et 22, angleterre 20, 24 24 24
------------------------------------------------------------------
-- Afficher le nombre d'équipes pour chaque championnat ciblé
SELECT l.leagueid, l.level, COUNT(ltl.teamid) AS nb_equipes
FROM leagues l
LEFT JOIN leagueteamlinks ltl ON l.leagueid = ltl.leagueid
WHERE l.leagueid IN (13,14,60,61,16,17,19,20,31,32,53,54)
GROUP BY l.leagueid, l.level
ORDER BY l.leagueid;
-- Afficher les clubs sans championnat
SELECT t.teamid, t.teamname
FROM teams t
LEFT JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.teamid IS NULL
ORDER BY t.teamid ASC;
------------------------------------------------------------------
--afficher doublon + nb d'equipe avec doublon
SELECT 
    t.teamid,
    t.teamname,
    GROUP_CONCAT(CONCAT(ltl.leagueid, ' (', l.leaguename, ', nb: ', COUNT_lt.nb_equipes, ')') ORDER BY l.level ASC SEPARATOR ', ') AS leagues_info
FROM teams t
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
JOIN (
    SELECT l2.leagueid, COUNT(lt2.teamid) AS nb_equipes
    FROM leagues l2
    LEFT JOIN leagueteamlinks lt2 ON l2.leagueid = lt2.leagueid
    GROUP BY l2.leagueid
) AS COUNT_lt ON COUNT_lt.leagueid = l.leagueid
WHERE l.countryid IN (34,14,18,21,27,45,38)
GROUP BY t.teamid, t.teamname
HAVING COUNT(DISTINCT ltl.leagueid) > 1
ORDER BY t.teamname;
----------------------------------------------------------------
--supprimer une équipe en trop
delete from leagueteamlinks where teamid = 0  AND leagueid = 0;
--remplacer l'équipe <OLD_TEAMID> par <NEW_TEAMID> dans la ligue <LEAGUEID>
UPDATE leagueteamlinks
SET teamid = <NEW_TEAMID> --equipe libre
WHERE teamid = <OLD_TEAMID>  AND leagueid = <LEAGUEID>;
--ajouter une équipe manquante
INSERT INTO leagueteamlinks (leagueid, teamid)
VALUES (<LEAGUEID>, <TEAMID>);