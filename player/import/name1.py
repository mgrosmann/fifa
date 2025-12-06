import pandas as pd
import os
import unicodedata

# Fichiers
nouveaux_file = "/mnt/c/github/nouveaux_joueurs.csv"
pn_file = "/mnt/c/github/fifa/pn.csv"
output_existants_file = "/mnt/c/github/joueurs_existants.csv"

# Colonnes prénom/nom
fn_col = 'info.name.firstname'
ln_col = 'info.name.lastname'
knownas_col = 'info.name.knownas'
jersey_col = 'info.name.playerjerseyname'

# Lecture CSV
nouveaux_df = pd.read_csv(nouveaux_file)
pn_df = pd.read_csv(pn_file, sep=';')  # pn.csv séparé par ;

# Normalisation
def normalize_name(name):
    if pd.isna(name):
        return ''
    name = str(name).lower().strip()
    # Supprimer accents et points
    name = ''.join(c for c in unicodedata.normalize('NFD', name)
                   if unicodedata.category(c) != 'Mn' and c != '.')
    return name

# Normaliser colonnes
nouveaux_df['full_name'] = (nouveaux_df[fn_col].map(normalize_name) + ' ' +
                            nouveaux_df[ln_col].map(normalize_name))
nouveaux_df['knownas_norm'] = nouveaux_df.get(knownas_col, '').map(normalize_name)

pn_df['full_name'] = (pn_df[fn_col].map(normalize_name) + ' ' +
                      pn_df[ln_col].map(normalize_name))
pn_df['knownas_norm'] = pn_df.get(knownas_col, '').map(normalize_name)
pn_df['jersey_norm'] = pn_df.get(jersey_col, '').map(normalize_name)

# Créer sets pour recherche rapide
pn_knownas_set = set(pn_df[pn_df['knownas_norm'] != '']['knownas_norm'])
pn_firstlast_set = set(pn_df['full_name'])
pn_jersey_set = set(pn_df['jersey_norm'])

# Détecter les joueurs existants
existants_mask = (
    nouveaux_df['full_name'].isin(pn_firstlast_set) |
    nouveaux_df['full_name'].isin(pn_jersey_set) |
    nouveaux_df['knownas_norm'].isin(pn_knownas_set) |
    nouveaux_df['knownas_norm'].isin(pn_jersey_set)
)

existants_df = nouveaux_df[existants_mask].copy()
nouveaux_df = nouveaux_df[~existants_mask].copy()

# Ajouter seulement ces nouveaux existants à joueurs_existants.csv
if not existants_df.empty:
    if os.path.exists(output_existants_file):
        existants_df.to_csv(output_existants_file, mode='a', header=False, index=False)
    else:
        existants_df.to_csv(output_existants_file, index=False)

# Réécrire le CSV des nouveaux joueurs restant
nouveaux_df.to_csv(nouveaux_file, index=False)

print(f"{len(existants_df)} joueurs détectés comme existants et ajoutés à {output_existants_file}")
print(f"{len(nouveaux_df)} joueurs restent dans {nouveaux_file}")

