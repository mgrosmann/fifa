#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
convert_cm_to_fifa15.py
Convertit un CSV CM Tracker -> plusieurs CSV compatibles FIFA15 :
 - players.csv
 - playernames.csv
 - playerloans.csv
 - teamplayerlinks.csv

Utilise dateloan.sh si présent pour convertir dates -> loandate id (FIFA numeric id).
"""

import csv
import subprocess
import os
from datetime import datetime

# --- Configuration ---
CM_CSV = "nouveaux_joueurs.csv"                # input CM Tracker CSV
OUTPUT_PLAYERS = "players.csv"
OUTPUT_PLAYERNAMES = "playernames.csv"
OUTPUT_PLAYERLOANS = "playerloans.csv"
OUTPUT_TEAMPLAYERLINKS = "teamplayerlinks.csv"

DATE_SCRIPT = "/mnt/c/github/fifa/dateloan.sh"  # chemin vers dateloan.sh (modifie si besoin)

# BASE used by dateloan.sh fallback
BASE_ID = 157499
BASE_DATE = datetime(2014, 1, 1)

# Position mapping abbreviations -> FIFA codes
ABBR_TO_CODE = {
    "GK": 0, "RWB": 2, "RWF": 2, "RB": 3, "CB": 5,
    "LB": 7, "LWB": 8, "LWF": 8, "CDM": 10, "CM": 14,
    "LM": 12, "RM": 16, "CAM": 18, "CF": 21, "ST": 25,
    "CF/SS": 21, "RW": 23, "LW": 27,
}

VALID_NUMERIC_CODES = {0,2,3,5,7,8,10,12,14,16,18,21,23,25,27,28,29}

ATTRIBUTE_MAP = {
    "attributes.acceleration": "acceleration",
    "attributes.sprintspeed": "sprintspeed",
    "attributes.agility": "agility",
    "attributes.balance": "balance",
    "attributes.jumping": "jumping",
    "attributes.stamina": "stamina",
    "attributes.strength": "strength",
    "attributes.reactions": "reactions",
    "attributes.aggression": "aggression",
    "attributes.interceptions": "interceptions",
    "attributes.positioning": "positioning",
    "attributes.vision": "vision",
    "attributes.ballcontrol": "ballcontrol",
    "attributes.crossing": "crossing",
    "attributes.dribbling": "dribbling",
    "attributes.finishing": "finishing",
    "attributes.freekickaccuracy": "freekickaccuracy",
    "attributes.headingaccuracy": "headingaccuracy",
    "attributes.longpassing": "longpassing",
    "attributes.shortpassing": "shortpassing",
    "attributes.marking": "marking",
    "attributes.shotpower": "shotpower",
    "attributes.longshots": "longshots",
    "attributes.standingtackle": "standingtackle",
    "attributes.slidingtackle": "slidingtackle",
    "attributes.volleys": "volleys",
    "attributes.curve": "curve",
    "attributes.penalties": "penalties",
    "attributes.gkdiving": "gkdiving",
    "attributes.gkhandling": "gkhandling",
    "attributes.gkkicking": "gkkicking",
    "attributes.gkreflexes": "gkreflexes",
    "attributes.gkpositioning": "gkpositioning",
}

# === Helpers date conversion ===
def iso_to_ddmmyyyy(iso_str):
    if not iso_str:
        return ""
    try:
        if "T" in iso_str:
            dt = datetime.strptime(iso_str.split("T")[0], "%Y-%m-%d")
            return dt.strftime("%d/%m/%Y")
        try:
            datetime.strptime(iso_str, "%d/%m/%Y")
            return iso_str
        except:
            dt = datetime.strptime(iso_str, "%Y-%m-%d")
            return dt.strftime("%d/%m/%Y")
    except:
        return ""

def date_to_loandate_with_script(date_str):
    if not date_str:
        return ""
    ddmmy = iso_to_ddmmyyyy(date_str)
    if not ddmmy:
        return ""
    if os.path.isfile(DATE_SCRIPT) and os.access(DATE_SCRIPT, os.X_OK):
        try:
            res = subprocess.run([DATE_SCRIPT, "id", ddmmy], capture_output=True, text=True, check=True)
            return res.stdout.strip()
        except:
            pass
    try:
        d = datetime.strptime(ddmmy, "%d/%m/%Y")
        days = (d - BASE_DATE).days
        return str(BASE_ID + days)
    except:
        return ""

def date_to_year_only(date_str):
    if not date_str:
        return ""
    try:
        if "T" in date_str:
            return date_str.split("T")[0].split("-")[0]
        try:
            dt = datetime.strptime(date_str, "%d/%m/%Y")
            return str(dt.year)
        except:
            dt = datetime.strptime(date_str, "%Y-%m-%d")
            return str(dt.year)
    except:
        return ""

# === Positions conversion ===
def map_primary_to_code(primary_raw):
    if primary_raw is None:
        return -1
    s = str(primary_raw).strip()
    if not s:
        return -1
    if s.isdigit():
        n = int(s)
        return n if n in VALID_NUMERIC_CODES else -1
    key = s.upper().strip()
    return ABBR_TO_CODE.get(key, -1)

def convert_positions(primary_raw, other_raw):
    p1 = map_primary_to_code(primary_raw)
    others_list = []
    if other_raw:
        txt = str(other_raw)
        for sep in ["|", ",", ";"]:
            if sep in txt:
                parts = [p.strip() for p in txt.split(sep)]
                break
        else:
            parts = [txt.strip()]
        for token in parts:
            if token and token != "-" and token != "--":
                code = map_primary_to_code(token)
                if code != -1:
                    others_list.append(code)
    p2 = others_list[0] if len(others_list) >= 1 else -1
    p3 = others_list[1] if len(others_list) >= 2 else -1
    p4 = others_list[2] if len(others_list) >= 3 else -1
    return p1, p2, p3, p4

# === Read input CSV and process ===
players = []
playerloans = []
teamplayerlinks = []
playernames_set = set()
playernames_list = []

with open(CM_CSV, newline='', encoding='utf-8') as fh:
    reader = csv.DictReader(fh)
    for row in reader:
        playerid = row.get("info.playerid") or row.get("playerid")
        if not playerid:
            continue

        # Dates
        birthdate_id = date_to_loandate_with_script(row.get("info.birthdate", ""))
        jointeamdate_id = date_to_loandate_with_script(row.get("info.contract.jointeamdate", ""))
        loandateend_id = ""
        if str(row.get("info.contract.isloanedout", "")).strip().lower() in ("1", "true", "yes"):
            loandateend_id = date_to_loandate_with_script(row.get("info.contract.enddate", ""))
        contract_year = date_to_year_only(row.get("info.contract.enddate", ""))

        # Positions
        primary_raw = row.get("primary_position", "") or row.get("primaryposition", "") or row.get("primary", "")
        other_raw = row.get("other_positions", "") or row.get("preferredposition2-4", "")
        p1, p2, p3, p4 = convert_positions(primary_raw, other_raw)

        # Playernames simplified
        firstname = row.get("info.name.firstname", "").strip()
        lastname = row.get("info.name.lastname", "").strip()
        key = (firstname, lastname)
        if key not in playernames_set:
            playernames_set.add(key)
            playernames_list.append({
                "playerid": playerid,
                "firstname": firstname,
                "lastname": lastname
            })
            # Normalisation de isretiring
            is_retiring_raw = str(row.get("info.isretiring","")).strip().lower()
            if is_retiring_raw in ("1", "true", "yes"):
                is_retiring = 1
            else:
                is_retiring = 0
            hq_raw = str(row.get("info.real_face","")).strip().lower()
            if hq_raw in ("1", "true", "yes"):
                hashighqualityhead = 1
            else:
                hashighqualityhead = 0
        # Build player dict for FIFA15
        player = {
            "playerid": playerid,
            "overallrating": row.get("info.overallrating", ""),
            "potential": row.get("info.potential", ""),
            "birthdate": birthdate_id,
            "playerjointeamdate": jointeamdate_id,
            "contractvaliduntil": contract_year,
            "haircolorcode": row.get("info.haircolor", ""),
            "eyecolorcode": row.get("info.eyecolor", ""),
            "skintonecode": row.get("info.skintone", ""),
            "headtypecode": row.get("info.headtype", ""),
            "bodytypecode": row.get("info.bodytype", ""),
            "height": row.get("info.height", ""),
            "weight": row.get("info.weight", ""),
            "preferredfoot": 1 if str(row.get("info.preferredfoot","")).strip().lower().startswith("r") else (2 if str(row.get("info.preferredfoot","")).strip().lower().startswith("l") else ""),
            "skillmoves": row.get("info.skillmoves", ""),
            "internationalrep": row.get("info.internationalrep", ""),
            "hashighqualityhead": hashighqualityhead,
            "isretiring": is_retiring,
            "nationid": row.get("info.nation.id", "") or row.get("info.nationid", ""),
            "preferredposition1": p1,
            "preferredposition2": p2,
            "preferredposition3": p3,
            "preferredposition4": p4,
            "firstname": firstname,
            "lastname": lastname,

            
        }
        for src, dest in ATTRIBUTE_MAP.items():
            player[dest] = row.get(src, "")

        players.append(player)

        # playerloans
        if loandateend_id:
            playerloans.append({
                "playerid": playerid,
                "teamid": row.get("info.teams.club_team.id", "0") or "0",
                "loandateend": loandateend_id
            })

        # teamplayerlinks
        tpl = {
            "teamid": row.get("info.teams.club_team.id", ""),
            "playerid": playerid
        }
        teamplayerlinks.append(tpl)

# === Write CSV outputs ===
def write_csv(path, list_of_dicts, delimiter=';'):
    if not list_of_dicts:
        print(f"[warn] pas de lignes pour {path}, fichier non créé.")
        return
    fieldnames = []
    for d in list_of_dicts:
        for k in d.keys():
            if k not in fieldnames:
                fieldnames.append(k)
    with open(path, "w", newline='', encoding="utf-8") as outf:
        writer = csv.DictWriter(outf, fieldnames=fieldnames, delimiter=delimiter, extrasaction='ignore')
        writer.writeheader()
        for r in list_of_dicts:
            writer.writerow(r)
    print(f"[ok] {path} ({len(list_of_dicts)} lignes)")

write_csv(OUTPUT_PLAYERS, players)
write_csv(OUTPUT_PLAYERNAMES, playernames_list, delimiter=';')
write_csv(OUTPUT_PLAYERLOANS, playerloans)
write_csv(OUTPUT_TEAMPLAYERLINKS, teamplayerlinks)

print("✅ Conversion terminée.")
