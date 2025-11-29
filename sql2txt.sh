#!/bin/bash

# --------------------------
# SQL to TXT exporter for FIFA DB
# --------------------------


DB="FIFA14"
cmd="mysql -uroot -proot -P 5000 -h127.0.0.1 -D $DB"
DEST_DIR="/mnt/c/github/fifa/15/forfifa15/"
mkdir -p "$DEST_DIR"

echo "Quel module a été modifié ?"
echo "1) Transfer"
echo "2) Loan"
echo "3) Player"
echo "4) League"
echo "5) Import"
read -p "Enter number: " module

# Determine tables to export
tables=()

case "$module" in
  1)
    tables=("teamplayerlinks")  # Transfer
    ;;
  2)
    tables=("teamplayerlinks" "playerloans")  # Loan
    ;;
  3)
    tables=("players" "previousteam")  # Player
    ;;
  4)
    tables=("leagueteamlinks")  # League
    ;;
  5)
    tables=("players" "playernames" "teamplayerlinks")  #import 
    ;;
  *)
    echo "❌ Invalid option."
    exit 1
    ;;
esac

# Export each table
for tbl in "${tables[@]}"; do
    OUTFILE="${tbl}temp.txt"
    echo "Exporting table: $tbl → $OUTFILE"
    
    $cmd -D "$DB" --batch  -e "SELECT * FROM \`$tbl\`;" > "$OUTFILE"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ $tbl exported successfully"
        
        # Convert with txt2utf16.sh
        sed -i 's/\r//g' "$OUTFILE"
        iconv -f UTF-8 -t UTF-16LE "$OUTFILE" > "${OUTFILE%.*}_utf16.txt"

# Move the converted file to DEST_DIR with the final name
mv "${OUTFILE%.*}_utf16.txt" "$DEST_DIR/${tbl}.txt"

# Optional: remove temp file
rm -f "$OUTFILE"
echo "📂 Converted UTF-16 file moved to $DEST_DIR/${tbl}.txt"
    else
        echo "❌ Failed to export $tbl"
    fi
done

echo "🎉 Export fini pour le module sélectionné."
