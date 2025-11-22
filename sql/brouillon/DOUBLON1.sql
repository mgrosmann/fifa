use FIFA16;
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
        THEN 'YES' ELSE 'NO' 
    END AS special_club
FROM teams t
JOIN teamplayerlinks tpl ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
GROUP BY t.teamid, t.teamname
HAVING nb_players_valides > 0 OR special_club = 'YES'
ORDER BY nb_players_valides DESC, t.teamname;

SELECT p.playerid, tpl.position, p.overallrating, p.potential, t.teamname, CONCAT(pn_first.name, ' ', pn_last.name) as fullname, pn_first.nameid, pn_last.nameid
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
join players p on tpl.playerid = p.playerid
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
WHERE t.teamname LIKE '%Brazil All Star%';
#Classic XI #Brazil All Star