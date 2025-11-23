#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
convert_cm_to_fifa15.py
Convertit un CSV CM Tracker -> plusieurs CSV compatibles FIFA15 :
 - players.csv
 - playernames.csv
 - playerloans.csv
 - teamplayerlinks.csv

Utilise dateloan.sh si présent pour convertir dates -> loandate id (fifa numeric id).
"""

import csv
import subprocess
import os
from datetime import datetime

# --- Configuration ---
CM_CSV = "cm_tracker.csv"                # input CM Tracker CSV
OUTPUT_PLAYERS = "players.csv"
OUTPUT_PLAYERNAMES = "playernames.csv"
OUTPUT_PLAYERLOANS = "playerloans.csv"
OUTPUT_TEAMPLAYERLINKS = "teamplayerlinks.csv"

DATE_SCRIPT = "/mnt/c/github/fifa/dateloan.sh"  # chemin vers dateloan.sh (modifie si besoin)

# BASE used by dateloan.sh fallback
BASE_ID = 157499
BASE_DATE = datetime(2014, 1, 1)

# Starting nameid (arbitraire pour éviter collisions)
name_id_counter = 2000000

# Position mapping abbreviations -> FIFA codes
ABBR_TO_CODE = {
    "GK": 0,
    "RWB": 2,  # Right Wing Back
    "RWF": 2,
    "RB": 3,
    "CB": 5,
    "LB": 7,
    "LWB": 8,
    "LWF": 8,
    "CDM": 10,
    "CM": 14,
    "LM": 12,
    "RM": 16,
    "CAM": 18,
    "CF": 21,
    "ST": 25,
    "CF/SS": 21,
    "RW": 23,
    "LW": 27,
    # fallback numeric strings sometimes present (like "14" etc.) will be handled
}

# Allow numeric keys via same mapping for convenience (if primary given as number)
# (position codes that we accept as-is)
VALID_NUMERIC_CODES = {0,2,3,5,7,8,10,12,14,16,18,21,23,25,27,28,29}

# Attributes mapping (CM Tracker -> players.csv field name)
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
    # composure ignored
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
    """Convertit YYYY-MM-DD... ou ISO timestamp en DD/MM/YYYY. Si échec retourne ''."""
    if not iso_str:
        return ""
    try:
        if "T" in iso_str:
            # "1992-06-15T00:00:00.000Z"
            dt = datetime.strptime(iso_str.split("T")[0], "%Y-%m-%d")
            return dt.strftime("%d/%m/%Y")
        # Already dd/mm/YYYY?
        try:
            datetime.strptime(iso_str, "%d/%m/%Y")
            return iso_str
        except Exception:
            dt = datetime.strptime(iso_str, "%Y-%m-%d")
            return dt.strftime("%d/%m/%Y")
    except Exception:
        return ""

def date_to_loandate_with_script(date_str):
    """
    Utilise dateloan.sh pour convertir une date (DD/MM/YYYY ou ISO) en ID FIFA (ex: 162062).
    Si le script échoue ou est absent, on calcule localement de la même façon.
    """
    if not date_str:
        return ""
    ddmmy = iso_to_ddmmyyyy(date_str)
    if not ddmmy:
        return ""
    # appel script si présent
    if os.path.isfile(DATE_SCRIPT) and os.access(DATE_SCRIPT, os.X_OK):
        try:
            res = subprocess.run([DATE_SCRIPT, "id", ddmmy], capture_output=True, text=True, check=True)
            return res.stdout.strip()
        except Exception:
            pass
    # fallback interne (même logique que dateloan.sh)
    try:
        d = datetime.strptime(ddmmy, "%d/%m/%Y")
        days = (d - BASE_DATE).days
        return str(BASE_ID + days)
    except Exception:
        return ""

def date_to_year_only(date_str):
    """
    contractvaliduntil -> renvoie uniquement l'année (string) si possible.
    Accepte ISO ou DD/MM/YYYY.
    """
    if not date_str:
        return ""
    try:
        if "T" in date_str:
            return date_str.split("T")[0].split("-")[0]
        try:
            dt = datetime.strptime(date_str, "%d/%m/%Y")
            return str(dt.year)
        except Exception:
            dt = datetime.strptime(date_str, "%Y-%m-%d")
            return str(dt.year)
    except Exception:
        return ""

# === playernames manager (avoid duplicates) ===
playernames = []   # list of dict {nameid, name, commentaryid}
name_to_id = {}    # dedupe map
def add_name(name_value):
    """Retourne nameid (nouveau ou existant) pour name_value."""
    global name_id_counter, playernames, name_to_id
    if name_value is None:
        name_value = ""
    name_value = str(name_value).strip()
    if name_value in name_to_id:
        return name_to_id[name_value]
    nid = name_id_counter
    name_id_counter += 1
    playernames.append({
        "nameid": nid,
        "name": name_value,
        "commentaryid": 900000
    })
    name_to_id[name_value] = nid
    return nid

# === Positions conversion ===
def map_primary_to_code(primary_raw):
    """Supporte valeurs type 'GK', 'ST', numeric strings '14', or already code ints."""
    if primary_raw is None:
        return -1
    s = str(primary_raw).strip()
    if not s:
        return -1
    # numeric?
    if s.isdigit():
        try:
            n = int(s)
            if n in VALID_NUMERIC_CODES:
                return n
            # If numeric but not in valid set, return -1
            return -1
        except:
            pass
    # uppercase token mapping
    key = s.upper()
    # sometimes values like 'GK ' or ' gk' -> strip
    key = key.strip()
    return ABBR_TO_CODE.get(key, -1)

def convert_positions(primary_raw, other_raw):
    """
    Retourne preferredposition1..4 (FIFA codes)
    preferredposition2..4 = -1 si non renseigné.
    """
    p1 = map_primary_to_code(primary_raw)
    # handle other positions: separators possible: '|', ',', ';'
    others_list = []
    if other_raw:
        txt = str(other_raw)
        # some CSV use "RM | LW" or "RM, LW" or "RM|LW"
        for sep in ["|", ",", ";"]:
            if sep in txt:
                parts = [p.strip() for p in txt.split(sep)]
                break
        else:
            parts = [txt.strip()]
        for token in parts:
            if not token or token == "-" or token == "--":
                continue
            code = map_primary_to_code(token)
            if code != -1:
                others_list.append(code)
    # build p2..p4 with -1 default
    p2 = others_list[0] if len(others_list) >= 1 else -1
    p3 = others_list[1] if len(others_list) >= 2 else -1
    p4 = others_list[2] if len(others_list) >= 3 else -1
    # if primary missing, set to -1
    if p1 == -1:
        p1 = -1
    return p1, p2, p3, p4

# === Read input and produce outputs ===
players = []
playerloans = []
teamplayerlinks = []

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

        # positions
        # primary_position in CM CSV may be text (e.g. "ST") or already a code; other_positions may be "RM | LW" or "-"
        primary_raw = row.get("primary_position", "") or row.get("primaryposition", "") or row.get("primary", "")
        other_raw = row.get("other_positions", "") or row.get("other_positions", "") or row.get("preferredposition2-4", "")
        p1, p2, p3, p4 = convert_positions(primary_raw, other_raw)

        # playernames
        firstname = row.get("info.name.firstname", "").strip()
        lastname = row.get("info.name.lastname", "").strip()
        jerseyname = row.get("info.name.playerjerseyname", "").strip() or firstname
        knownas = row.get("info.name.knownas", "").strip() or ""

        firstnameid = add_name(firstname)
        lastnameid = add_name(lastname)
        jerseynameid = add_name(jerseyname)
        commonnameid = add_name(knownas)

        # Build player dict with requested fields + attributes
        player = {
            "playerid": playerid,
            "firstnameid": firstnameid,
            "lastnameid": lastnameid,
            "playerjerseynameid": jerseynameid,
            "commonnameid": commonnameid,
            "overallrating": row.get("info.overallrating", ""),
            "potential": row.get("info.potential", ""),
            "birthdate": birthdate_id,                 # converted via dateloan.sh fallback
            "playerjointeamdate": jointeamdate_id,
            "contractvaliduntil": contract_year,      # year only
            # appearance / physical
            "haircolorcode": row.get("info.haircolor", ""),
            "eyecolorcode": row.get("info.eyecolor", ""),
            "skintonecode": row.get("info.skintone", ""),
            "headtypecode": row.get("info.headtype", ""),
            "bodytypecode": row.get("info.bodytype", ""),
            "height": row.get("info.height", ""),
            "weight": row.get("info.weight", ""),
            "preferredfoot": 1 if str(row.get("info.preferredfoot","")).strip().lower().startswith("r") else (2 if str(row.get("info.preferredfoot","")).strip().lower().startswith("l") else ""),
            "skillmoves": row.get("info.skillmoves", ""),
            "weakfootabilitytypecode": row.get("info.weafoot", ""),
            "internationalrep": row.get("info.internationalrep", ""),
            "hashighqualityhead": row.get("info.real_face", ""),
            "isretiring": row.get("info.isretiring", ""),
            "trait1": row.get("info.traits.trait1", ""),
            "trait2": row.get("info.traits.trait2", ""),
            # nation
            "nationid": row.get("info.nation.id", "") or row.get("info.nationid", ""),
            # preferred positions (p1..p4) - use -1 for missing secondaries
            "preferredposition1": p1,
            "preferredposition2": p2,
            "preferredposition3": p3,
            "preferredposition4": p4,
        }

        # Add all attribute fields from ATTRIBUTE_MAP
        for src, dest in ATTRIBUTE_MAP.items():
            player[dest] = row.get(src, "")

        # Add card attributes (if present)
        player["card_pac"] = row.get("card_attrs.pac", "")
        player["card_sho"] = row.get("card_attrs.sho", "")
        player["card_pas"] = row.get("card_attrs.pas", "")
        player["card_dri"] = row.get("card_attrs.dri", "")
        player["card_def"] = row.get("card_attrs.def", "")
        player["card_phy"] = row.get("card_attrs.phy", "")

        # optional useful info
        player["playerjointeamid_team"] = row.get("info.teams.club_team.id", "")  # team id where player is
        player["jerseynumber_in_team"] = row.get("info.teams.club_team.jerseynumber", "")

        players.append(player)

        # playerloans (if loaned)
        if loandateend_id:
            playerloans.append({
                "playerid": playerid,
                # teamid: CM Tracker doesn't give destination of loan; per spec use current team or 0
                "teamid": row.get("info.teams.club_team.id", "0") or "0",
                "loandateend": loandateend_id
            })

        # teamplayerlinks (always position = 29 as requested)
        tpl = {
            "teamid": row.get("info.teams.club_team.id", ""),
            "playerid": playerid,
            "jerseynumber": row.get("info.teams.club_team.jerseynumber", ""),
            "position": 29
        }
        teamplayerlinks.append(tpl)

# === Write CSV outputs (delimiter ;) ===
def write_csv(path, list_of_dicts, delimiter=';'):
    if not list_of_dicts:
        print(f"[warn] pas de lignes pour {path}, fichier non créé.")
        return
    # unify fieldnames across all rows: gather union to avoid missing columns
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

# write
write_csv(OUTPUT_PLAYERS, players)
write_csv(OUTPUT_PLAYERNAMES, playernames)
write_csv(OUTPUT_PLAYERLOANS, playerloans)
write_csv(OUTPUT_TEAMPLAYERLINKS, teamplayerlinks)

print("✅ Conversion terminée.")
