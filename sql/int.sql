--table players
alter table players MODIFY COLUMN playerid INT UNSIGNED;
alter table players MODIFY COLUMN overallrating INT UNSIGNED;
alter table players MODIFY COLUMN potential INT UNSIGNED;
alter table players MODIFY COLUMN nationality INT UNSIGNED;
alter table players MODIFY COLUMN firstnameid INT UNSIGNED;
alter table players MODIFY COLUMN lastnameid INT UNSIGNED;
alter table players MODIFY COLUMN commonameid INT UNSIGNED;
--table playernames
alter table playernames MODIFY COLUMN nameid INT UNSIGNED;
alter table playernames MODIFY COLUMN commentaryid INT UNSIGNED;
--table teams
alter table teams MODIFY COLUMN teamid INT UNSIGNED;
--table teamplayerlinks
alter table teamplayerlinks MODIFY COLUMN playerid INT UNSIGNED;
alter table teamplayerlinks MODIFY COLUMN teamid INT UNSIGNED;
alter table teamplayerlinks MODIFY COLUMN artificialkey INT UNSIGNED;
alter table teamplayerlinks MODIFY COLUMN jerseynumber INT UNSIGNED;
--table leagueteamlinks
alter table leagueteamlinks MODIFY COLUMN teamid INT UNSIGNED;
alter table leagueteamlinks MODIFY COLUMN leagueid INT UNSIGNED;
--table leagues
alter table leagues MODIFY COLUMN leagueid INT UNSIGNED;
--table playerloans
alter table playerloans MODIFY COLUMN playerid INT UNSIGNED;
