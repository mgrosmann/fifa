import pandas as pd
import glob
import os

# --- CONFIG ---
base_dir = "/mnt/c/github/csv/"
folders = ["wonderkid", "old wonderkid", "very old"]
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

# --- Parcourir tous les CSV CM Tracker ---
for folder in folders:
    path = os.path.join(base_dir, folder, "*.csv")
    for file in glob.glob(path):
        # CSV CM Tracker utilise , et " comme quotechar
        df = pd.read_csv(file, sep=",", quotechar='"')

        if "info.playerid" not in df.columns:
            print(f"⚠️  Fichier {file} : colonne 'info.playerid' introuvable. Colonnes : {df.columns.tolist()}")
            continue

        for _, row in df.iterrows():
            pid = row.get("info.playerid")
            if pid is None:
                continue
            pid = str(pid).strip()
            total_joueurs += 1

            row["source"] = folder
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

