#!/bin/bash

# --------------------------
# SQL to TXT exporter for FIFA DB
# --------------------------

DB="FIFA14"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="5000"

MYSQL_CMD="mysql -u $USER -p$PASSWORD -h $HOST -P $PORT"

# Dossier de destination pour FIFA15
DEST_DIR="/mnt/c/github/fifa/15/forfifa15/"
mkdir -p "$DEST_DIR"

echo "Quel module a été modifié ?"
echo "1) Transfer"
echo "2) Loan"
echo "3) Player"
echo "4) League"
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
  *)
    echo "❌ Invalid option."
    exit 1
    ;;
esac

# Export each table
for tbl in "${tables[@]}"; do
    OUTFILE="${tbl}.txt"
    echo "Exporting table: $tbl → $OUTFILE"
    
    $MYSQL_CMD -D "$DB" --batch --skip-column-names -e "SELECT * FROM \`$tbl\`;" > "$OUTFILE"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ $tbl exported successfully"
        
        # Convert with dbmaster.py to .txt format (UTF-16)
        python3 /mnt/c/github/fifa/dbmaster.py "$OUTFILE"
        
        # Move TXT to FIFA15 folder
        mv "$OUTFILE" "$DEST_DIR"
        echo "📂 $OUTFILE moved to $DEST_DIR"
    else
        echo "❌ Failed to export $tbl"
    fi
done

echo "🎉 Export fini pour le module sélectionné."
