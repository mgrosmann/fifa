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
 OR t.teamname LIKE '%all-star%'
) OR ltl.leagueid = 78"
AND NOT (
      $exclude_condition
  );

les scrits qui lisent une équipe 1 par 1:
previousteam|set-previousteam|overall|set-datejointeam

les scripts qui lisent un joueur individuellement:
transfer.sh|set-datejointeam|cancel-loan|player-loan|change-nationality
<<<<<<< HEAD

countryid;pays
14,18,21,27,45
angleterre;france;allemagne italie espagne
=======
