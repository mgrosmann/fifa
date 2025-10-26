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
    # Convertir date -> loandateend
    # Supporte format DD/MM/YYYY
    days=$(( ( $(date -d "$(echo $value | awk -F/ '{print $3"-"$2"-"$1}')" +%s) - $(date -d "$BASE_DATE" +%s) ) / 86400 ))
    loandateend=$((BASE_ID + days))
    echo "$loandateend"
elif [[ "$mode" == "date" ]]; then
    # Convertir loandateend -> date
    days=$(( value - BASE_ID ))
    date -d "$BASE_DATE + $days days" +"%d/%m/%Y"
else
    echo "Usage:"
    echo "  $0 id DD/MM/YYYY      # Convertit une date en loandateend"
    echo "  $0 date LOANDATEEND   # Convertit un loandateend en date"
    exit 1
fi