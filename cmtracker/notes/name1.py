import pandas as pd

# Fichiers
nouveaux_file = "/mnt/c/github/nouveaux_joueurs.csv"
pn_file = "/mnt/c/github/fifa/pn.csv"
output_existants_file = "/mnt/c/github/joueurs_existants.csv"

# Colonnes prénom/nom
fn_col = 'info.name.firstname'
ln_col = 'info.name.lastname'

# Lecture CSV
nouveaux_df = pd.read_csv(nouveaux_file)
pn_df = pd.read_csv(pn_file, sep=';')  # pn.csv séparé par ;

# Créer une colonne "full_name" en minuscules pour comparaison
nouveaux_df['full_name'] = (nouveaux_df[fn_col].str.lower().str.strip() + ' ' +
                            nouveaux_df[ln_col].str.lower().str.strip())
pn_df['full_name'] = (pn_df[fn_col].str.lower().str.strip() + ' ' +
                      pn_df[ln_col].str.lower().str.strip())

# Joueurs existants
existants_df = nouveaux_df[nouveaux_df['full_name'].isin(pn_df['full_name'])]

# Ajouter à joueurs_existants.csv sans écraser
try:
    anciens_existants_df = pd.read_csv(output_existants_file)
    existants_df = pd.concat([anciens_existants_df, existants_df], ignore_index=True)
except FileNotFoundError:
    pass  # le fichier n'existe pas encore, on le crée

existants_df.to_csv(output_existants_file, index=False)

# Supprimer les joueurs existants du CSV nouveaux joueurs
nouveaux_df = nouveaux_df[~nouveaux_df['full_name'].isin(pn_df['full_name'])]
nouveaux_df.to_csv(nouveaux_file, index=False)

print(f"{len(existants_df)} joueurs existants dans {output_existants_file}")
print(f"{len(nouveaux_df)} joueurs restent dans {nouveaux_file}")

