import csv
import mysql.connector

#CSV_FILE = "/mnt/c/github/joueurs_existants.csv"
CSV_FILE = "/mnt/c/github/nouveaux_joueurs.csv"
# --- Connexion MySQL ---
conn = mysql.connector.connect(
    host="127.0.0.1",
    port=5000,
    user="root",
    password="root",
    database="FIFA16"
)
cursor = conn.cursor()

# --- Lecture CSV ---
noms = set()
with open(CSV_FILE, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        if "firstname" in row and row["firstname"].strip():
            noms.add(row["firstname"].strip())
        if "lastname" in row and row["lastname"].strip():
            noms.add(row["lastname"].strip())
        #if "playerjerseyname" in row and row["playerjerseyname"].strip():
        #    noms.add(row["playerjerseyname"].strip())
        #if "knownas" in row and row["knownas"].strip():
        #    noms.add(row["knownas"].strip())

print(f"Total noms uniques trouvés dans CSV : {len(noms)}")

# --- Vérification dans la DB ---
deja = 0
nouveaux = 0

for nom in noms:
    cursor.execute("SELECT nameid FROM playernames WHERE LOWER(name) = LOWER(%s);", (nom,))
    result = cursor.fetchall()
    if result:
        deja += 1
    else:
        nouveaux += 1

print("===== RÉSULTATS =====")
print(f"Noms déjà présents  : {deja}")
print(f"Noms manquants      : {nouveaux}")
print("======================")
print(f"Slots nécessaires   : {nouveaux}")

cursor.close()
conn.close()

