import csv
CSV_FILE = "cm_tracker.csv"
OUTPUT_FILE = "player_headshots.csv"

with open(CSV_FILE, newline="", encoding="utf-8") as f_in, \
     open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f_out:

    reader = csv.DictReader(f_in)
    writer = csv.writer(f_out)
    writer.writerow(["playerid", "headshot"])

    for row in reader:
        playerid = row.get("info.playerid", "").strip()
        headshot = row.get("info.headshot", "").strip()
        if playerid and headshot:
            writer.writerow([playerid, headshot])

print(f"[INFO] Fichier généré : {OUTPUT_FILE}")