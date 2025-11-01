#!/bin/bash
# ------------------------------------------
# Convert a UTF-8 text file to UTF-16 encoding
# Usage: ./utf8_to_utf16.sh file.txt
# ------------------------------------------

if [[ -z "$1" ]]; then
    echo "❌ Usage: $0 <input_file.txt>"
    exit 1
fi

input="$1"

if [[ ! -f "$input" ]]; then
    echo "❌ File not found: $input"
    exit 1
fi

# Get base name and output file path
base="${input%.*}"
output="${base}_utf16.txt"

# Convert from UTF-8 to UTF-16
iconv -f UTF-8 -t UTF-16 "$input" -o "$output" 2>/dev/null

if [[ $? -eq 0 ]]; then
    echo "✅ Converted: $input → $output"
else
    echo "⚠️ Conversion failed — copying original instead."
    cp "$input" "$output"
fi
