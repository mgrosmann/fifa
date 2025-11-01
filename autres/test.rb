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
les fichiers a importer:
teams teamplayerlinks player playernames leagues leagueteamlinks


exclure selection nationale des resultats et équipe all star=
"AND t_loanedto.teamid NOT IN (
974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190
      )"

"AND t.teamid NOT IN (
974,1318,1319,1321,1322,1324,1325,1327,1328,1329,1330,1331,1332,1334,1335,1336,1337,1338,
1341,1342,1343,1352,1353,1354,1355,1356,1357,1359,1360,1361,1362,1363,1364,1365,1366,1367,
1369,1370,1375,1377,1383,1386,1387,1391,1393,1395,1411,1413,1415,1667,1886,105013,105022,
105035,110081,110082,111099,111107,111108,111109,111111,111112,111114,111115,111130,111448,
111451,111455,111456,111459,111461,111462,111465,111466,111473,111475,111481,111483,111487,
111489,111527,111545,111548,111550,111740,112048,111596,112606,112828,112190
      )"

les scrits qui lisent une équipe 1 par 1:
previousteam|set-previousteam|overall|set-datejointeam

les scripts qui lisent un joueur individuellement:
transfer.sh|set-datejointeam|cancel-loan|player-loan|change-nationality