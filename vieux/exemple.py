import pandas as pd

# --- fichiers ---
source_csv = "players.csv"          # ton fichier FIFA 14
output_csv = "players_fifa15_format.csv"   # sortie FIFA 15 compatible

# --- ordre exact des colonnes FIFA 15 ---
fifa15_order = """""".replace("\n", "").split(";")

# --- chargement du CSV FIFA 14 ---
df = pd.read_csv(source_csv, sep=";")

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
df_reordered.to_csv(output_csv, sep=";", index=False)
print(f"💾 Fichier converti enregistré dans {output_csv}")

