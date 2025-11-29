USE FC26;
delete from teamplayerlinks where playerid = 254022;
delete from players where playerid = 254022;
delete from playernames where name like '%nick wolte%' or name like '%woltem%';
--test
select firstnameid, lastnameid, commonnameid, playerjerseynameid from players where playerid = 254022;
select * from teamplayerlinks where playerid = 254022;
select * from playernames where name like '%nick wolte%' or name like '%woltem%';