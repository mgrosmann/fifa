#!/bin/bash

INPUT_DIR="/mnt/c/github/txt/FIFA15/csv"
OUTPUT_FILE="column_FIFA15.csv"

# Vider le fichier de sortie
> "$OUTPUT_FILE"

for file in "$INPUT_DIR"/*.csv; do
    filename=$(basename "$file")
    table="${filename%.*}"

    echo "📄 Traitement : $filename"

    {
        echo "$table"
        head -n 1 "$file"
        echo ""     # Ligne vide pour séparer
    } >> "$OUTPUT_FILE"

done

echo "✅ Extraction terminée : entêtes enregistrées dans $OUTPUT_FILE"
