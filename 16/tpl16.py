import pandas as pd

# --- fichiers ---
source_csv = "teamplayerlinks.csv"          # ton fichier FIFA 15
output_txt = "teamplayerlinks_fifa16_format.txt"   # sortie FIFA 16 compatible

# --- ordre exact des colonnes FIFA 16 ---
fifa16_order = """leaguegoals;isamongtopscorers;yellows;isamongtopscorersinteam;jerseynumber;position;artificialkey;teamid;leaguegoalsprevmatch;injury;leagueappearances;prevform;istopscorer;leaguegoalsprevthreematches;playerid;form;reds""".replace("\n", "").split(";")

# --- chargement du CSV FIFA 15 ---
df = pd.read_csv(source_csv, sep="\\t", engine='python')

# --- sélection et réorganisation ---
columns_in_common = [col for col in fifa16_order if col in df.columns]
missing = [col for col in fifa16_order if col not in df.columns]
extra = [col for col in df.columns if col not in fifa16_order]

print("✅ Colonnes communes :", len(columns_in_common))
print("⚠️ Colonnes manquantes :", missing)
print("ℹ️ Colonnes supplémentaires ignorées :", extra)

# réorganisation
df_reordered = df[columns_in_common]

# sauvegarde
df_reordered.to_csv(output_txt, sep="\t", index=False, lineterminator="\n", encoding="utf-8")
print(f"💾 Fichier converti enregistré dans {output_txt}")

