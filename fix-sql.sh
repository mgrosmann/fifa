#ERROR 1062 (23000) at line 58: Duplicate entry '900000' for key 'playernames.PRIMARY'
#playernames 90000 3 fois playerid
#ERROR 1062 (23000) at line 78: Duplicate entry '209911-111489' for key 'teamplayerlinks.PRIMARY'
#3 ligne doublon dans teamplayerlinks
#ERROR 1062 (23000) at line 107: Duplicate entry '1' for key 'leagues.PRIMARY'
#plusieurs doublons dans leagues 
#fifa 14 = Argentina Primera División Germany 2. Bundesliga
#fifa15 Segunda A Liga MX (1) Argentina Primera División (1)
#fifa16  21	Germany 2. Bundesliga 52	Argentina Primera División
#mauvais leagueid (les '()' devrait etre dans leaguename)
#+-----------+-----------------------------+-------+----------+-----------------+------------------------+
| countryid | leaguename                  | level | leagueid | leaguetimeslice | iswithintransferwindow |
+-----------+-----------------------------+-------+----------+-----------------+------------------------+
| 21        | Germany 2. Bundesliga       | (2)   | 20       | 20              | 6                      |
| 52        | Argentina Primera División  | (1)   | 1        | 353             | 6                      |
+-----------+-----------------------------+-------+----------+-----------------+------------------------+
2 rows in set (0.001 sec)

MySQL [FIFA14]> SELECT * FROM FIFA15.leagues where level in ('(1)','(2)') or level like '%l%';
+-----------+-----------------------------+-------------+----------+-----------------+------------------------+
| countryid | leaguename                  | level       | leagueid | leaguetimeslice | iswithintransferwindow |    
+-----------+-----------------------------+-------------+----------+-----------------+------------------------+    
| 83        | Segunda A                   | Liga MX (1) | 1        | 341             | 7                      |    
| 52        | Argentina Primera División  | (1)         | 1        | 353             | 3                      |    
+-----------+-----------------------------+-------------+----------+-----------------+------------------------+    
2 rows in set (0.001 sec)

MySQL [FIFA14]> SELECT * FROM FIFA16.leagues where level in ('(1)','(2)') or level like '%l%';
+-----------+-----------------------------+-------+----------+-----------------+------------------------+
| countryid | leaguename                  | level | leagueid | leaguetimeslice | iswithintransferwindow |
+-----------+-----------------------------+-------+----------+-----------------+------------------------+
| 21        | Germany 2. Bundesliga       | (2)   |       20 | 20              | 5                      |
| 52        | Argentina Primera División  | (1)   |        1 | 353             | 8                      |
+-----------+-----------------------------+-------+----------+-----------------+------------------------+
2 rows in set (0.002 sec)

selon la premiere ligne "countryid;	leaguename;	level;	leagueid;	leaguetimeslice;	iswithintransferwindow"
pour fifa14:
bundes: 21;	Germany 2. Bundesliga  (2);	2;	20;	6;	1
argentina: 52;	Argentina Primera División  (1);	1;	353;	6;	0
pour fifa15:
liga mx : 83;	Segunda A  Liga MX (1);	1	;341;	7;  0
argentina: 52;	Argentina Primera División  (1);	1;	353;	3;	0
pour fifa16:
bundes: 21;	Germany 2. Bundesliga  (2);	2;    20;	5;	1
argentina: 52;	Argentina Primera División  (1);	1;	353;	8;	0