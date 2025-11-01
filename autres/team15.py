import pandas as pd

# --- fichiers ---
source_csv = "teams.csv"          # ton fichier FIFA 14
output_txt = "teams_fifa15_format.txt"   # sortie FIFA 15 compatible

# --- ordre exact des colonnes FIFA 15 ---
fifa15_order = """assetid;balltype;teamcolor1g;teamcolor1r;teamcolor2b;teamcolor2r;teamcolor3r;teamcolor1b;latitude;teamcolor3g;teamcolor2g;teamname;adboardid;teamcolor3b;defmentality;powid;rightfreekicktakerid;physioid_secondary;domesticprestige;genericint2;jerseytype;rivalteam;midfieldrating;matchdayoverallrating;matchdaymidfieldrating;attackrating;physioid_primary;longitude;buspassing;matchdaydefenserating;defenserating;defteamwidth;longkicktakerid;bodytypeid;trait1;busdribbling;rightcornerkicktakerid;suitvariationid;defaggression;ethnicity;leftcornerkicktakerid;teamid;fancrowdhairskintexturecode;suittypeid;numtransfersin;captainid;personalityid;leftfreekicktakerid;genericbanner;buspositioning;stafftracksuitcolorcode;ccpositioning;busbuildupspeed;transferbudget;ccshooting;overallrating;ccpassing;utcoffset;penaltytakerid;freekicktakerid;defdefenderline;internationalprestige;form;genericint1;cccrossing;matchdayattackrating""".replace("\n", "").split(";")

# --- chargement du CSV FIFA 14 ---
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

