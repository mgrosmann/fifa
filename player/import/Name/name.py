import csv
import mysql.connector

CSV_FILE = "/mnt/c/github/fifa/player/import/playernames.csv"

# --- Connexion MySQL ---
conn = mysql.connector.connect(
    host="127.0.0.1",
    port=5000,
    user="root",
    password="root",
    database="FIFA15"
)
cursor = conn.cursor()

# --- Lecture CSV ---
noms = set()
with open(CSV_FILE, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter=";")  # <-- IMPORTANT
    for row in reader:

        firstname = row.get("firstname", "").strip()
        lastname = row.get("lastname", "").strip()

        if firstname:
            noms.add(firstname)
        if lastname:
            noms.add(lastname)

print(f"Total noms uniques trouvés dans CSV : {len(noms)}")

# --- Vérification dans la DB ---
deja = 0
nouveaux = 0

for nom in noms:
    cursor.execute(
        "SELECT nameid FROM playernames WHERE LOWER(name) = LOWER(%s);",
        (nom,)
    )
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
