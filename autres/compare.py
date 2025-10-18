#!/usr/bin/env python3
import os
import pandas as pd

# --- 🔧 CONFIGURATION DES CHEMINS ---
FIFA_PATHS = {
    "FIFA14": "/mnt/c/Users/PC/Documents/FM_temp/FIFA14/csv",
    "FIFA15": "/mnt/c/Users/PC/Documents/FM_temp/FIFA15/csv",
    "FIFA16": "/mnt/c/Users/PC/Documents/FM_temp/FIFA16/csv",
}



def list_csv_files(base_path):
    """Retourne la liste triée des CSV dans un dossier."""
    return sorted([f for f in os.listdir(base_path) if f.endswith(".csv")])

def read_columns(csv_path):
    """Lit uniquement la première ligne d'un CSV pour extraire les colonnes."""
    try:
        df = pd.read_csv(csv_path, sep=";", nrows=0, encoding="utf-8")
        return list(df.columns)
    except Exception as e:
        return [f"❌ Erreur lecture : {e}"]

def main():
    # --- 1️⃣ Lister les fichiers disponibles ---
    table_sets = {name: set(list_csv_files(path)) for name, path in FIFA_PATHS.items()}
    all_tables = sorted(set().union(*table_sets.values()))

    print(f"📊 {len(all_tables)} tables détectées à comparer.\n")

    # --- 2️⃣ Comparaison table par table ---
    for table in all_tables:
        print("=" * 60)
        print(f"🗂️  Table : {table}")

        all_columns = {}
        for fifa_version, base_path in FIFA_PATHS.items():
            csv_path = os.path.join(base_path, table)
            if os.path.exists(csv_path):
                cols = read_columns(csv_path)
                all_columns[fifa_version] = cols
                print(f"  ✅ {fifa_version}: {len(cols)} colonnes")
            else:
                print(f"  ⚠️  {fifa_version}: table absente")

        # --- 3️⃣ Comparaison des colonnes ---
        if len(all_columns) > 1:
            ref_version = list(all_columns.keys())[0]
            ref_cols = set(all_columns[ref_version])

            for version, cols in all_columns.items():
                if version == ref_version:
                    continue
                diff_left = sorted(list(ref_cols - set(cols)))
                diff_right = sorted(list(set(cols) - ref_cols))

                if diff_left or diff_right:
                    print(f"\n  🔍 Différences entre {ref_version} et {version}:")
                    if diff_left:
                        print(f"    ➖ Colonnes absentes dans {version}: {', '.join(diff_left)}")
                    if diff_right:
                        print(f"    ➕ Colonnes nouvelles dans {version}: {', '.join(diff_right)}")
                else:
                    print(f"  ✅ Colonnes identiques entre {ref_version} et {version}")
        print("")

if __name__ == "__main__":
    main()

