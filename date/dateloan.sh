#!/usr/bin/env bash
# convert_loandate.sh
# Usage:
#   ./convert_loandate.sh id "01/01/2024"
#   ./convert_loandate.sh date 161151

BASE_ID=157499
BASE_DATE="2014-01-01"

mode="$1"
value="$2"

if [[ "$mode" == "id" ]]; then
    # Lire "30/06/2026" correctement et convertir en format ISO
    parsed=$(echo "$value" | awk -F/ '{printf "%04d-%02d-%02d", $3, $2, $1}')
    
    # Calcul précis en UTC pour éviter les décalages horaires
    days=$(( ( $(date -u -d "$parsed" +%s) - $(date -u -d "$BASE_DATE" +%s) ) / 86400 ))
    loandateend=$((BASE_ID + days))
    echo "$loandateend"

elif [[ "$mode" == "date" ]]; then
    # Convertir loandateend -> date JJ/MM/AAAA
    days=$(( value - BASE_ID ))
    date -u -d "$BASE_DATE + $days days" +"%d/%m/%Y"

else
    echo "Usage:"
    echo "  $0 id DD/MM/YYYY      # Convertit une date en loandateend"
    echo "  $0 date LOANDATEEND   # Convertit un loandateend en date"
    exit 1
fi