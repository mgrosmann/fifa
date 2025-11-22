SELECT l.leagueid,
       l.leaguename,
       COUNT(DISTINCT tpl.playerid) AS nb_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
join leagueteamlinks ltl on t.teamid = ltl.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
WHERE l.leagueid IN (13, 16, 19, 31, 10, 53, 308)
GROUP BY l.leagueid, l.leaguename
ORDER BY l.leagueid;

SELECT COUNT(DISTINCT tpl.playerid) AS total_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.leagueid IN (13, 16, 19, 31, 10, 53, 308);


SELECT 
    COUNT(DISTINCT tpl.playerid) AS nb_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
ORDER BY nb_joueurs DESC;

SELECT teamid, teamname 
FROM teams
WHERE teamname LIKE '%Juventus%'
   OR teamname LIKE '%Milan%'
   OR teamname LIKE '%Inter%' and teamid in (44)
   OR teamname LIKE '%Lazio%'
   OR teamname LIKE '%Roma%' and teamid in (52)
   OR teamname LIKE '%Fiorentina%'
   OR teamname LIKE '%Napoli%'
   OR teamname LIKE '%Paris s%'
   OR teamname LIKE '%Lyon%'
   OR teamname LIKE '%Losc%'
   OR teamname LIKE '%Real mad%'
   OR teamname LIKE '%Barcelon%'
   OR teamname LIKE '%Atletico de m%'
   OR teamname LIKE '%Villarreal%'
   OR teamname LIKE '%Valencia%'
   OR teamname LIKE '%Bayern%'
   OR teamname LIKE '%Dortmund%'
   OR teamname LIKE '%Bayer 0%'
   OR teamname LIKE '%Schalke%';
