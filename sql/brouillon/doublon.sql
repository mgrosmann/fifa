USE FIFA15;
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
-------------------------------------------------------------------------
SELECT DISTINCT t.teamname, CONCAT(pn_first.name, ' ', pn_last.name) AS fullname
FROM players p
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
WHERE p.playerid IN (
    SELECT tpl2.playerid
    FROM teamplayerlinks tpl2
    JOIN leagueteamlinks ltl2 ON tpl2.teamid = ltl2.teamid
    WHERE ltl2.leagueid <> 78
    GROUP BY tpl2.playerid
    HAVING COUNT(DISTINCT tpl2.teamid) > 1
)
AND l.leagueid <> 78
ORDER BY fullname, t.teamname;







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
    THEN tpl.playerid END) AS nb_players_valides,
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
HAVING nb_players_valides > 0 OR special_club = 'YES'
ORDER BY nb_players_valides DESC, t.teamname;



