--requete sql utile
--sommaire 
--1 : rechercher un joueur
--2 : afficher tous les joueurs d'un club
--3 : lister nombre de joueurs dans les 7 championnats majeurs
--4 : nombre de clubs par championnat
--5 : lister nombre total de joueurs dans les 7 championnats majeurs
--6 : nombre de joueur par club
--7 : classé les joueurs par player id
--8 : lister les équipes d'un championnat
--9 : Doublons dans une colonne (exemple : playernames.name)
--10 : Doublons sur un couple de colonnes (ex: teamid et playerid sur tpl)
--11 : afficher joueur selon critière (pour max export)
--12 : nombre de joueurs par club selon critère (pour max export)
--13 : afficher club avec joueurs doublons (equipe spéciale ou erreur db)
--14 : afficher club avec joueurs doublons et comparer avec taille effectif total
--15: transformer une colonne en int pour les chiffres (ex: playerid)
--------------------------------------------------------------------------------------------------------------------
--1 rechercher un joueur
SELECT p.playerid, p.overallrating, t.teamname, CONCAT(pn_first.name, ' ', pn_last.name) as fullname, pn_first.nameid, pn_last.nameid
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
join players p on tpl.playerid = p.playerid
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
WHERE CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%kompany%';
--2 afficher tous les joueurs d'un club
SELECT p.playerid, tpl.position, p.overallrating, p.potential, t.teamname, CONCAT(pn_first.name, ' ', pn_last.name) as fullname, pn_first.nameid, pn_last.nameid
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
join players p on tpl.playerid = p.playerid
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
WHERE t.teamname LIKE '%real madrid%';
--3 lister nombre de joueurs dans les 7 championnats majeurs
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
--4 nombre de clubs par championnat
SELECT l.leagueid, l.leaguename, COUNT(DISTINCT t.teamid) AS nb_clubs
FROM leagueteamlinks ltl
JOIN teams t ON ltl.teamid = t.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
WHERE l.leagueid IN (13, 16, 19, 31, 10, 53, 308)
GROUP BY l.leagueid, l.leaguename
ORDER BY l.leagueid;
--5 lister nombre total de joueurs dans les 7 championnats majeurs
SELECT COUNT(DISTINCT tpl.playerid) AS total_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.leagueid IN (13, 16, 19, 31, 10, 53, 308);
--6 nombre de joueur par club
SELECT 
    t.teamid,
    t.teamname,
    COUNT(DISTINCT tpl.playerid) AS nb_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
GROUP BY t.teamid, t.teamname
ORDER BY nb_joueurs DESC;
--filtrer
SELECT
    t.teamid,
    t.teamname,
    COUNT(DISTINCT tpl.playerid) AS nb_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
GROUP BY t.teamid, t.teamname
HAVING COUNT(DISTINCT tpl.playerid) > 37
ORDER BY nb_joueurs DESC;
--7 classé les joueurs par player id
SELECT tpl.playerid, CONCAT(pn_first.name, ' ', pn_last.name) as fullname, p.overallrating, t.teamname
from FIFA14.teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
JOIN players p on tpl.playerid = p.playerid
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
ORDER BY CAST(tpl.playerid AS UNSIGNED);
--8 lister les équipes d'un championnat
SELECT t.teamid, t.teamname, l.leaguename
FROM leagueteamlinks ltl
JOIN teams t ON ltl.teamid = t.teamid
Join leagues l ON ltl.leagueid = l.leagueid
WHERE l.leaguename like '%Ligue 1%'; --bundesliga '%bundesliga (1)%' liga = '%spain p%'
--9 Doublons dans une colonne (exemple : playernames.name)
SELECT nameid, COUNT(*) AS occurrences
FROM FIFA1525.teamplayerlinks
GROUP BY nameid
HAVING COUNT(*) > 1;
--10 Doublons sur un couple de colonnes (ex: teamid et playerid sur tpl)
SELECT playerid, teamid, COUNT(*) AS nb
FROM teamplayerlinks
GROUP BY playerid, teamid
HAVING COUNT(*) > 1;
--11 afficher joueur selon critière (pour max export)
SELECT p.playerid, p.firstnameid, p.lastnameid, tpl.teamid, p.overallrating, p.potential
FROM players p
JOIN teamplayerlinks tpl ON tpl.playerid = p.playerid
JOIN leagueteamlinks ltl on tpl.teamid = ltl.teamid
WHERE tpl.teamid IN (
    21, 22, 32, 34, 44, 45, 46, 47, 48, 52, 65, 66, 73, 240, 241, 243, 461, 483, 110374
)
OR ltl.leagueid = 13
OR (
    p.overallrating >= 85 
    OR p.potential >= 85 
    OR (p.potential - p.overallrating) >= 15 
    
) AND tpl.teamid NOT IN (
974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190, 111205
      );

--12 nombre de joueurs par club selon critère (pour max export)
SELECT tpl.teamid,
       COUNT(DISTINCT p.playerid) AS nb_joueurs
FROM players p
JOIN teamplayerlinks tpl ON tpl.playerid = p.playerid
JOIN leagueteamlinks ltl ON tpl.teamid = ltl.teamid
WHERE tpl.teamid NOT IN (21, 22, 32, 34, 44, 45, 46, 47, 48, 52, 65, 66, 73, 240, 241, 243, 461, 483, 110374)
  AND ltl.leagueid != 13
  AND (
        p.overallrating >= 85
     OR p.potential >= 85
     OR (p.potential - p.overallrating) >= 15
  ) AND tpl.teamid NOT IN (
974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190, 111205
      )
GROUP BY tpl.teamid
ORDER BY nb_joueurs DESC;
--13 afficher club avec joueurs doublons (equipe spéciale ou erreur db)
SELECT 
    t.teamname, 
    COUNT(DISTINCT tpl.playerid) AS nb_players
FROM teams t
JOIN teamplayerlinks tpl ON t.teamid = tpl.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
WHERE l.leagueid <> 78
  AND l.countryid NOT IN (14, 18, 21, 27, 45, 95)
  AND tpl.playerid IN (
      SELECT tpl2.playerid
      FROM teamplayerlinks tpl2
      JOIN leagueteamlinks ltl2 ON tpl2.teamid = ltl2.teamid
      WHERE ltl2.leagueid <> 78
      GROUP BY tpl2.playerid
      HAVING COUNT(DISTINCT tpl2.teamid) > 1
  )
GROUP BY t.teamid, t.teamname
ORDER BY nb_players DESC, t.teamname;
--14 afficher club avec joueurs doublons et comparer avec taille effectif total
SELECT 
    t.teamid,
    t.teamname,
    COUNT(DISTINCT tpl.playerid) AS nb_joueurs,
    COUNT(DISTINCT CASE 
        WHEN tpl.playerid IN (
            SELECT tpl2.playerid
            FROM teamplayerlinks tpl2
            JOIN leagueteamlinks ltl2 ON tpl2.teamid = ltl2.teamid
            WHERE ltl2.leagueid <> 78
            GROUP BY tpl2.playerid
            HAVING COUNT(DISTINCT tpl2.teamid) > 1
        )
        AND l.leagueid <> 78
        AND l.countryid NOT IN (14, 18, 21, 27, 45, 95)
    THEN tpl.playerid END) AS nb_players_doublons,
    CASE 
        WHEN t.teamname LIKE '%All star%'
          OR t.teamname LIKE '%Adidas%'
          OR t.teamname LIKE '%Nike%'
          OR t.teamname LIKE '% xi%'
          OR t.teamname LIKE '%allstar%'
          OR t.teamname LIKE '%all-star%'
          OR t.teamname LIKE '%stars%'
        THEN 'YES' ELSE 'NO' 
    END AS special_club
FROM teams t
JOIN teamplayerlinks tpl ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
GROUP BY t.teamid, t.teamname
HAVING nb_players_doublons > 0 OR special_club = 'YES'
ORDER BY nb_players_doublons DESC, t.teamname;
--15: transformer une colonne en int pour les chiffres (ex: playerid)
alter table players MODIFY COLUMN playerid INT UNSIGNED;