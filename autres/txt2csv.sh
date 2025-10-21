#!/bin/bash
export LC_ALL=C.UTF-8
source="/mnt/c/github/txt/FIFA16/"
destination="/mnt/c/github/txt/FIFA16/csv/"
#source="/mnt/c/Users/mgrosmann/Documents/DB Master/fifa16/"
#destination="/mnt/c/Users/mgrosmann/Documents/DB Master/fifa16/csv/"

mkdir -p "$destination"

for file in "$source"*.txt; do
    filename=$(basename "$file" .txt)
    output="${destination}${filename}.csv"

    # Convertit en UTF-8 si besoin (Windows → Linux)
    tmpfile="/tmp/${filename}.utf8"
    iconv -f UTF-16 -t UTF-8 "$file" -o "$tmpfile" 2>/dev/null || cp "$file" "$tmpfile"

    # Transformation : plusieurs espaces ou tabs → ';'
    # mais un seul espace entre mots reste inchangé
    awk '{
        line=$0
        # remplace les tabulations ou au moins deux espaces par un point-virgule
        gsub(/\t+/, ";", line)
        gsub(/  +/, ";", line)
        print line
    }' "$tmpfile" > "$output"

    echo "✅ Converti : $file → $output"
done
