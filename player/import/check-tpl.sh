#!/bin/bash
cmd="mysql -uroot -proot -h127.0.0.1 -P5000 -DFIFA1518"
id=$1
$cmd -e "SELECT 
    CASE 
        WHEN 
            (SELECT COUNT(*) 
             FROM teamplayerlinks 
             WHERE teamid = $id AND position BETWEEN 0 AND 27) = 11
        AND
            (SELECT COUNT(*) 
             FROM teamplayerlinks 
             WHERE teamid = $id AND position = 28) = 7
        AND
            (SELECT COUNT(*) 
             FROM teamplayerlinks 
             WHERE teamid = $id AND position = 29)
            =
            (
                (SELECT COUNT(*) 
                 FROM teamplayerlinks 
                 WHERE teamid = $id) - 18
            )
        THEN 1
        ELSE 0
    END AS team_valid;"
