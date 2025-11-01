#!/bin/bash
# convert_utf16.sh
# Usage: ./convert_utf16.sh mon_fichier.txt

if [ $# -lt 1 ]; then
    echo "Usage: $0 <fichier_source>"
    exit 1
fi

SOURCE="$1"
BASE="${SOURCE%.*}"
OUTPUT="${BASE}_utf16.txt"

# Conversion UTF-8 → UTF-16 LE
iconv -f UTF-8 -t UTF-16LE "$SOURCE" > "$OUTPUT"

echo "✅ Fichier converti en UTF-16 LE : $OUTPUT"
