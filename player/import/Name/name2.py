import csv
import unicodedata

PLAYERNAMES_DB = "/mnt/c/github/fifa/csv/playernames.csv"   # DB officielle FIFA
PLAYERS_DB = "/mnt/c/github/fifa/csv/players.csv"           # players.csv FIFA
CSV_FILE = "/mnt/c/github/playernames.csv"                  # ton CSV (Sol Campbell etc.)
OUTPUT_FILE = "/mnt/c/github/fifa/diff_joueurs.txt"

# ---------------------------------------------------------
# Utilitaire pour normaliser les noms (accents, minuscules)
# ---------------------------------------------------------
def normalize_name(name):
    name = unicodedata.normalize("NFKD", name)
    name = "".join(c for c in name if not unicodedata.combining(c))
    return name.lower().replace(" ", "")

# ---------------------------------------------------------
# Charger playernames.csv en dictionnaire : nameid -> name
# ---------------------------------------------------------
playernames = {}
with open(PLAYERNAMES_DB, encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        nid = row["nameid"].strip()
        name = row["name"].strip()
        playernames[nid] = name

print(f"Noms chargés depuis playernames.csv : {len(playernames)}")

# ---------------------------------------------------------
# Charger players.csv : playerid -> firstnameid / lastnameid
# ---------------------------------------------------------
players = {}
with open(PLAYERS_DB, encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        pid = row["playerid"].strip()
        players[pid] = {
            "firstnameid": row["firstnameid"].strip(),
            "lastnameid": row["lastnameid"].strip()
        }

print(f"Joueurs chargés depuis players.csv : {len(players)}")

# ---------------------------------------------------------
# Charger ton CSV d'entrée (Sol Campbell, etc.)
# ---------------------------------------------------------
input_players = []
with open(CSV_FILE, encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        pid = row["playerid"].strip()
        input_players.append({
            "playerid": pid,
            "csv_firstname": row["firstname"].strip(),
            "csv_lastname": row["lastname"].strip()
        })

print(f"Total joueurs dans ton CSV : {len(input_players)}")

# ---------------------------------------------------------
# Comparaison
# ---------------------------------------------------------
diff_legere = []
diff_totale = []

for p in input_players:
    pid = p["playerid"]

    if pid not in players:
        continue

    firstnameid = players[pid]["firstnameid"]
    lastnameid = players[pid]["lastnameid"]

    db_firstname = playernames.get(firstnameid, "")
    db_lastname = playernames.get(lastnameid, "")

    csv_fname_norm = normalize_name(p["csv_firstname"])
    csv_lname_norm = normalize_name(p["csv_lastname"])
    db_fname_norm = normalize_name(db_firstname)
    db_lname_norm = normalize_name(db_lastname)

    if csv_fname_norm != db_fname_norm or csv_lname_norm != db_lname_norm:
        # différence légère si un des deux correspond
        if csv_fname_norm == db_fname_norm or csv_lname_norm == db_lname_norm:
            diff_legere.append({
                **p,
                "db_firstname": db_firstname,
                "db_lastname": db_lastname
            })
        else:
            diff_totale.append({
                **p,
                "db_firstname": db_firstname,
                "db_lastname": db_lastname
            })

# ---------------------------------------------------------
# Sauvegarde résultats
# ---------------------------------------------------------
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write(f"Différences légères : {len(diff_legere)} joueurs\n")
    for j in diff_legere:
        f.write(str(j) + "\n")

    f.write("\nDifférences totales : {len(diff_totale)} joueurs\n")
    for j in diff_totale:
        f.write(str(j) + "\n")

print(f"Analyse terminée. Résultats dans : {OUTPUT_FILE}")
