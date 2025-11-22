SELECT *
FROM FIFA14.teamplayerlinks1_csv
WHERE (playerid, teamid) IN (
    SELECT playerid, teamid
    FROM FIFA14.teamplayerlinks1_csv
    GROUP BY playerid, teamid
    HAVING COUNT(*) > 1
)
ORDER BY playerid, teamid;


ALTER TABLE TEST_FIFA15.teamplayerlinks_csv
ADD COLUMN tmp_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
DELETE tpl
FROM TEST_FIFA15.teamplayerlinks_csv tpl
INNER JOIN (
    SELECT MIN(tmp_id) AS keep_id, playerid, teamid
    FROM TEST_FIFA15.teamplayerlinks_csv
    GROUP BY playerid, teamid
    HAVING COUNT(*) > 1
) t ON tpl.playerid = t.playerid AND tpl.teamid = t.teamid
WHERE tpl.tmp_id <> t.keep_id;
ALTER TABLE TEST_FIFA15.teamplayerlinks_csv 
DROP COLUMN tmp_id;
--TEST_FIFA15.teamplayerlinks_csv 
select * from TEST_FIFA15.teamplayerlinks_csv  where playerid in (18122) and teamid in (130506) or playerid in (191848) and teamid in (130506)
or playerid in (209911) and teamid in (111489); 