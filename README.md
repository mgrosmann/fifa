pour convertir une db fifa 14/15/16 vers 14/15/16 (les rendres compatibles entre elles)
exporter en .txt avec db master, convertir txt en csv, importer en sql les csv, créer/supprimmer les tables/colonnes
exporter en csv les tables concernées, convertir dans le fifa choisi avec l'ordre des colonnes adapté, puis encoder en utf-16 pour db master afin d'importer
###utilisation des différents scripts:
analyze.py: prend en paramètre un fichier texte pour trouver son encodage(utilisé pour les .txt de db master pour trouver leur encodage (utf-16)
compare.py: analyse tous les csv de db fifa 14 15 16 et indique les différences (quel colonnes/tables sont absentes/nouvelles d'un fifa à l'autre)
csv2sql.sh: importe du csv sur le serveur sql
sql2csv.sh: exporte une table d'une base de donnée en csv
txt2csv.sh: exporte du txt en csv
