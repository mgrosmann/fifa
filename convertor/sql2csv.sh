#!/bin/bash

# --- Demande à l'utilisateur ---
read -p "Nom de la base de données : " DB
read -p "Nom de la table à exporter : " TABLE
read -p "Nom du fichier CSV de sortie (ex: table.csv) : " OUTFILE

# --- Identifiants MySQL ---
USER="root"
PASS="root"

# --- Vérification ---
if [ -z "$DB" ] || [ -z "$TABLE" ] || [ -z "$OUTFILE" ]; then
    echo "❌ Base, table ou fichier de sortie manquant."
    exit 1
fi

# --- Export vers CSV ---
mysql -u$USER -p$PASS -D $DB -e "SELECT * FROM $TABLE;" \
--batch --column-names > "$OUTFILE"

if [ $? -eq 0 ]; then
    echo "✅ Export terminé : $OUTFILE"
else
    echo "❌ Erreur lors de l'export"
fi

