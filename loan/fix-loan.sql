UPDATE FIFA15.playerloans
SET loandateend = 162062
WHERE loandateend < 161728;
-----------------------------------
--suppression des prêts à soi-même
DELETE pl
FROM playerloans pl
JOIN teamplayerlinks tpl ON pl.playerid = tpl.playerid
WHERE pl.teamidloanedfrom = tpl.teamid;
--pour debug quand preter à soi-même
SELECT pl.playerid,
       CONCAT(IFNULL(pn_first.name,''),' ',IFNULL(pn_last.name,'')) AS fullname,
       pl.teamidloanedfrom,
       tpl.teamid AS current_team,
       t.teamname AS current_team_name
FROM playerloans pl
JOIN teamplayerlinks tpl ON pl.playerid = tpl.playerid
JOIN teams t ON tpl.teamid = t.teamid
LEFT JOIN players p ON p.playerid = pl.playerid
LEFT JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
LEFT JOIN playernames pn_last  ON p.lastnameid = pn_last.nameid
WHERE pl.teamidloanedfrom = tpl.teamid;
