import csv
import mysql.connector
import unicodedata

CSV_FILE = "/mnt/c/github/joueurs_existants.csv"
OUTPUT_FILE = "/mnt/c/github/fifa/diff_joueurs.txt"

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
joueurs_csv = []
with open(CSV_FILE, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        if "playerid" in row and row["playerid"].strip():
            joueurs_csv.append({
                "playerid": int(row["playerid"].strip()),
                "csv_firstname": row.get("firstname", "").strip(),
                "csv_lastname": row.get("lastname", "").strip()
            })

print(f"Total joueurs uniques dans CSV : {len(joueurs_csv)}")

def normalize_name(name):
    """Supprime accents et met en minuscule pour comparaison subtile"""
    name = unicodedata.normalize('NFKD', name)
    name = ''.join(c for c in name if not unicodedata.combining(c))
    return name.lower().replace(" ", "")

diff_legere = []
diff_totale = []

for joueur in joueurs_csv:
    # 1) Récupérer firstnameid et lastnameid depuis players
    cursor.execute(
        "SELECT firstnameid, lastnameid FROM players WHERE playerid=%s", 
        (joueur["playerid"],)
    )
    result = cursor.fetchone()
    if not result:
        continue

    firstnameid, lastnameid = result

    # 2) Récupérer les noms depuis playernames
    cursor.execute("SELECT name FROM playernames WHERE nameid=%s", (firstnameid,))
    db_firstname = cursor.fetchone()[0]

    cursor.execute("SELECT name FROM playernames WHERE nameid=%s", (lastnameid,))
    db_lastname = cursor.fetchone()[0]

    # 3) Comparer avec CSV
    csv_fname_norm = normalize_name(joueur["csv_firstname"])
    csv_lname_norm = normalize_name(joueur["csv_lastname"])
    db_fname_norm = normalize_name(db_firstname)
    db_lname_norm = normalize_name(db_lastname)

    if csv_fname_norm != db_fname_norm or csv_lname_norm != db_lname_norm:
        if (csv_fname_norm == db_fname_norm) or (csv_lname_norm == db_lname_norm):
            diff_legere.append(joueur | {"db_firstname": db_firstname, "db_lastname": db_lastname})
        else:
            diff_totale.append(joueur | {"db_firstname": db_firstname, "db_lastname": db_lastname})

# --- Écriture dans un fichier ---
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write(f"Différences légères : {len(diff_legere)} joueurs\n")
    for joueur in diff_legere:
        f.write(f"{joueur}\n")
    f.write(f"\nDifférences totales : {len(diff_totale)} joueurs\n")
    for joueur in diff_totale:
        f.write(f"{joueur}\n")

print(f"Résultats sauvegardés dans {OUTPUT_FILE}")

cursor.close()
conn.close()

