import pandas as pd

# --- fichiers ---
source_csv = "leagueteamlinks.csv"          # ton fichier FIFA 16
output_txt = "leagueteamlinks_fifa15_format.txt"   # sortie FIFA 15 compatible

# --- ordre exact des colonnes FIFA 15 ---
fifa15_order = """homega;homegf;points;awaygf;awayga;teamshortform;hasachievedobjective;secondarytable;yettowin;unbeatenallcomps;unbeatenleague;champion;leagueid;prevleagueid;previousyeartableposition;highestpossible;teamform;highestprobable;homewins;artificialkey;nummatchesplayed;teamid;gapresult;grouping;currenttableposition;awaywins;objective;actualvsexpectations;homelosses;unbeatenhome;lastgameresult;unbeatenaway;awaylosses;awaydraws;homedraws;teamlongform""".replace("\n", "").split(";")

# --- chargement du CSV FIFA 16 ---
df = pd.read_csv(source_csv, sep="\\t", engine='python')

# --- sélection et réorganisation ---
columns_in_common = [col for col in fifa15_order if col in df.columns]
missing = [col for col in fifa15_order if col not in df.columns]
extra = [col for col in df.columns if col not in fifa15_order]

print("✅ Colonnes communes :", len(columns_in_common))
print("⚠️ Colonnes manquantes :", missing)
print("ℹ️ Colonnes supplémentaires ignorées :", extra)

# réorganisation
df_reordered = df[columns_in_common]

# sauvegarde
df_reordered.to_csv(output_txt, sep="\t", index=False, lineterminator="\n", encoding="utf-8")
print(f"💾 Fichier converti enregistré dans {output_txt}")