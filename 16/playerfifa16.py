import pandas as pd

# --- fichiers ---
source_csv = "players.csv"          # ton fichier FIFA 14
output_txt = "players_fifa16_format.txt"   # sortie FIFA 15 compatible

# --- ordre exact des colonnes FIFA 15 ---
fifa15_order = """shoetypecode;haircolorcode;facialhairtypecode;curve;jerseystylecode;agility;accessorycode4;gksavetype;positioning;hairtypecode;standingtackle;faceposercode;preferredposition3;longpassing;penalties;animfreekickstartposcode;animpenaltieskickstylecode;isretiring;longshots;gkdiving;interceptions;shoecolorcode2;crossing;potential;gkreflexes;finishingcode1;reactions;vision;contractvaliduntil;finishing;dribbling;slidingtackle;accessorycode3;accessorycolourcode1;headtypecode;firstnameid;sprintspeed;height;hasseasonaljersey;preferredposition2;strength;birthdate;preferredposition1;ballcontrol;shotpower;trait1;socklengthcode;weight;hashighqualityhead;gkglovetypecode;balance;gender;gkkicking;lastnameid;internationalrep;animpenaltiesmotionstylecode;shortpassing;freekickaccuracy;skillmoves;usercaneditname;attackingworkrate;finishingcode2;aggression;acceleration;headingaccuracy;eyebrowcode;runningcode2;gkhandling;eyecolorcode;jerseysleevelengthcode;accessorycolourcode3;accessorycode1;playerjointeamdate;headclasscode;defensiveworkrate;nationality;preferredfoot;sideburnscode;weakfootabilitytypecode;jumping;skintypecode;gkkickstyle;stamina;playerid;marking;accessorycolourcode4;gkpositioning;trait2;skintonecode;shortstyle;overallrating;emotion;jerseyfit;accessorycode2;shoedesigncode;playerjerseynameid;shoecolorcode1;commonnameid;bodytypecode;animpenaltiesstartposcode;runningcode1;preferredposition4;volleys;accessorycolourcode2;facialhaircolorcode""".replace("\n", "").split(";")

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

