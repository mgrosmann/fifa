import pandas as pd
import os

# --- CONFIG ---
csv_file = "/mnt/c/github/fifa/player/import/players.csv"  # chemin du CSV unique
fifa_csv = "/mnt/c/github/txt/FIFA15/csv/players.csv"
output_new_file = "/mnt/c/github/fifa/cmtracker/import/nouveaux_joueurs.csv"
output_existing_file = "/mnt/c/github/fifa/cmtracker/import/joueurs_existants.csv"

# --- Charger DB FIFA ---
fifa_db = pd.read_csv(fifa_csv, sep=";")
if "playerid" not in fifa_db.columns:
    raise ValueError(f"La colonne 'playerid' est introuvable dans {fifa_csv}. Colonnes disponibles : {fifa_db.columns.tolist()}")

fifa_ids = set(fifa_db["playerid"].astype(str))

# --- Stats ---
total_joueurs = 0
joueurs_deja = 0
joueurs_nouveaux = 0
nouveaux = []
existants = []

# --- Charger le CSV unique ---
df = pd.read_csv(csv_file, sep=",", quotechar='"')

if "playerid" not in df.columns:
    raise ValueError(f"La colonne 'playerid' est introuvable dans {csv_file}. Colonnes disponibles : {df.columns.tolist()}")

for _, row in df.iterrows():
    pid = row.get("playerid")
    if pid is None:
        continue
    pid = str(pid).strip()
    total_joueurs += 1

    row["source"] = os.path.basename(csv_file)  # on peut garder le nom du fichier comme source
    if pid in fifa_ids:
        joueurs_deja += 1
        existants.append(row)
    else:
        joueurs_nouveaux += 1
        nouveaux.append(row)

# --- Export CSV ---
pd.DataFrame(nouveaux).to_csv(output_new_file, index=False)
pd.DataFrame(existants).to_csv(output_existing_file, index=False)

# --- Affichage stats ---
print("===== STATISTIQUES =====")
print(f"Total joueurs analysés : {total_joueurs}")
print(f"Déjà présents dans FIFA : {joueurs_deja}")
print(f"Nouveaux joueurs : {joueurs_nouveaux}")
print("========================")
print(f"CSV des nouveaux joueurs → {output_new_file}")
print(f"CSV des joueurs existants → {output_existing_file}")
