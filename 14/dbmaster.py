#!/usr/bin/env python3
# make_dbmaster_txt.py
# Convertit un CSV ou un TXT normal (UTF-8, ; ou tab) vers le format DB Master (UTF-16 LE + tabulations)

import pandas as pd
import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python make_dbmaster_txt.py <fichier_source>")
        sys.exit(1)

    source = sys.argv[1]
    base, ext = os.path.splitext(source)
    output = f"{base}_dbmaster.txt"

    # --- Détection du séparateur probable
    with open(source, "r", encoding="utf-8", errors="ignore") as f:
        sample = f.read(2000)
    sep = ";" if sample.count(";") > sample.count("\t") else "\t"

    print(f"Lecture du fichier : {source}")
    print(f"Séparateur détecté : {'point-virgule' if sep == ';' else 'tabulation'}")

    # --- Lecture du CSV / TXT d’entrée
    try:
        df = pd.read_csv(source, sep=sep, encoding="utf-8", engine="python")
    except Exception as e:
        print(f"Erreur de lecture : {e}")
        sys.exit(1)

    print(f"✓ {len(df)} lignes et {len(df.columns)} colonnes détectées")
    print("Exemple de colonnes :", list(df.columns)[:10])

    # --- Nettoyage des colonnes
    df.columns = [str(c).strip().replace('\ufeff', '') for c in df.columns]

    # --- Sauvegarde au format DB Master (UTF-16 LE, tabulations, fin \r\n)
    df.to_csv(
        output,
        sep="\t",
        encoding="utf-16",    # ajoute automatiquement le BOM UTF-16 LE
        index=False,
        lineterminator="\r\n",
        quoting=3             # pas de guillemets
    )

    print(f"\n✅ Fichier prêt pour DB Master : {output}")
    print("Format : UTF-16 LE + \\t + \\r\\n")
    print("Tu peux maintenant l'importer directement via DB Master → Import Table → players.txt")

if __name__ == "__main__":
    main()

