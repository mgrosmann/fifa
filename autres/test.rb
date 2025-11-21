mysql -uroot -proot -P 5000 -h 127.0.0.1
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='5000' -P${MYSQL_PORT} -h${MYSQL_HOST}
pour chercher sur github -> git clone https://github.com/mgrosmann/fifa.git
pour mettre à jour de github vers local -> cd repository git pull origin main (git stash pour supprimer les modifs locales)
pour mettre à jour de local vers github -> git add .  git commit -m "update"  git push origin main


0 gardien
3 dd
5 dc 
7 dg 
8 dlg
10 mdc 
12 mg
14 mc
16 mg
18 moc 
21 AT/CF
23 allier droit
25 BUTEUR 
27 allier gauche
28 remplacant
29 reserviste
les tables importantes:
players, playernames
↕️↕ relié par teamplayerlinks (relié par playerid pour player a teams, et teamid pour teams a players)
teams    
↕️ relié par leagueteamlinks (relié par teamid pour teams a leagues, et leagueid pour leagues a teams)
leagues  
exclure selection nationale des resultats et équipe all star=
#JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
exclude_condition="(
    t.teamname LIKE '%All star%'
 OR t.teamname LIKE '%Adidas%'
 OR t.teamname LIKE '%Nike%'
 OR t.teamname LIKE '% xi%'
 OR t.teamname LIKE '%allstar%'
) OR ltl.leagueid = 78"
 Where playerid = $playerid  AND NOT (
      $exclude_condition
  );

les scrits qui lisent une équipe 1 par 1:
previousteam|set-previousteam|overall|set-datejointeam

les scripts qui lisent un joueur individuellement:
transfer.sh|set-datejointeam|cancel-loan|player-loan|change-nationality

# requete sql utile
rechercher un joueur 
SELECT p.playerid, p.overallrating, t.teamname, CONCAT(pn_first.name, ' ', pn_last.name) as fullname, pn_first.nameid, pn_last.nameid
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
join players p on tpl.playerid = p.playerid
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
WHERE CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%kompany%';
#afficher tous les joueurs d'un club
SELECT p.playerid, tpl.position, p.overallrating, p.potential, t.teamname, CONCAT(pn_first.name, ' ', pn_last.name) as fullname, pn_first.nameid, pn_last.nameid
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
join players p on tpl.playerid = p.playerid
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
WHERE t.teamname LIKE '%real madrid%';
#lister nombre de joueurs dans les 7 championnats majeurs
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
#nombre de clubs par championnat
SELECT l.leagueid, l.leaguename, COUNT(DISTINCT t.teamid) AS nb_clubs
FROM leagueteamlinks ltl
JOIN teams t ON ltl.teamid = t.teamid
JOIN leagues l ON ltl.leagueid = l.leagueid
WHERE l.leagueid IN (13, 16, 19, 31, 10, 53, 308)
GROUP BY l.leagueid, l.leaguename
ORDER BY l.leagueid;
#lister nombre total de joueurs dans les 7 championnats majeurs
SELECT COUNT(DISTINCT tpl.playerid) AS total_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
WHERE ltl.leagueid IN (13, 16, 19, 31, 10, 53, 308);
#nombre de joueur par club
SELECT 
    t.teamid,
    t.teamname,
    COUNT(DISTINCT tpl.playerid) AS nb_joueurs
FROM teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
GROUP BY t.teamid, t.teamname
ORDER BY nb_joueurs DESC;
#classé les joueurs par player id
SELECT tpl.playerid, CONCAT(pn_first.name, ' ', pn_last.name) as fullname, p.overallrating, t.teamname
from FIFA14.teamplayerlinks tpl
JOIN teams t ON tpl.teamid = t.teamid
JOIN players p on tpl.playerid = p.playerid
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
ORDER BY CAST(tpl.playerid AS UNSIGNED);
#lister les équipes d'un championnat
SELECT t.teamid, t.teamname, l.leaguename
FROM leagueteamlinks ltl
JOIN teams t ON ltl.teamid = t.teamid
Join leagues l ON ltl.leagueid = l.leagueid
WHERE l.leaguename like '%Ligue 1%'; #bundesliga '%bundesliga (1)%' liga = '%spain p%'

comment convertir un fichier tab en csv:
perl -lpe 's/"/""/g; s/^|$/"/g; s/\t/","/g' < input.tab > output.csv               #|||||||||| (passer de tab au csv avec guillemets)
tr '\t' ';' < tmp.csv > output.csv                                                 #||||||||| (passer de tab a point virgule sans guillemets)
head -n 1                                                                           ##||||||| (extraire la 1ere ligne seulement)
tail --lines=+2 tmp.csv #skip la 1ere ligne
basename test.py .py | ls sample.txt |cut -d"." -f 1                                 ##||||||| (extraire le nom du fichier sans extension)
iconv -f UTF-16 -t UTF-8 "players.txt" -o "test.txt" 2>/dev/null || cp players.txt test.txt #||||| (convertir utf16 vers utf8)
iconv -f UTF-8 -t UTF-16 "test.txt" -o "1players.txt" 2>/dev/null || cp test.txt 1players.txt  #(convertir utf8 vers utf16)




#trouver des doublons
#Doublons dans une colonne (exemple : playernames.name)
SELECT nameid, COUNT(*) AS occurrences
FROM FIFA1525.teamplayerlinks
GROUP BY nameid
HAVING COUNT(*) > 1;
#Doublons sur un couple de colonnes (ex: teamid et playerid sur tpl)
SELECT playerid, teamid, COUNT(*) AS nb
FROM teamplayerlinks
GROUP BY playerid, teamid
HAVING COUNT(*) > 1;