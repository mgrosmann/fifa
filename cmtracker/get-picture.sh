#!/bin/bash
set -e
set -o pipefail

# --------------------------
# Config
# --------------------------
CSV_FILE="/mnt/c/github/fifa/cmtracker/player_headshots.csv"
FIFA_FOLDER="/mnt/c/Users/mgrosmann/Documents/FIFA 15/data/ui/imgAssets/heads"
TMP_DIR="/tmp/fifa_headshots"
OLD_DIR="$TMP_DIR/pictures"
WIDTH=128
HEIGHT=128

mkdir -p "$FIFA_FOLDER"
mkdir -p "$TMP_DIR"
mkdir -p "$OLD_DIR"

# --------------------------
# Boucle sur chaque joueur
# --------------------------
tail -n +2 "$CSV_FILE" | while IFS=',' read -r playerid headshot
do
    # Suppression des guillemets
    playerid=$(echo "$playerid" | tr -d '"')
    headshot=$(echo "$headshot" | tr -d '"')

    # Skip si vide
    [[ -z "$playerid" || -z "$headshot" ]] && continue

    OUT="${FIFA_FOLDER}/p${playerid}.dds"
    TMP="${TMP_DIR}/headshot_${playerid}.png"

    # Si existe → déplacer dans tmp/pictures
    if [[ -f "$OUT" ]]; then
        echo "[MOVE] $OUT → $OLD_DIR/"
        mv "$OUT" "$OLD_DIR/"
        # Ne pas continue, on doit remplacer l'image par la nouvelle version
    fi

    # Télécharger la nouvelle image
    if wget -q --no-check-certificate -O "$TMP" "$headshot"; then
        
        # Convertir en DDS
        if convert "$TMP" -resize ${WIDTH}x${HEIGHT}\! "$OUT"; then
            echo "[OK] Créé $OUT"
        else
            echo "[ERROR] convert $TMP"
        fi

    else
        echo "[ERROR] wget $headshot"
    fi

    rm -f "$TMP"

done
