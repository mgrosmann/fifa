import csv
import subprocess

CSV_FILE = "/mnt/c/Users/PC/Downloads/arsenal.csv"
LOG_FILE = "log.txt"

DB_USER = "root"
DB_PASS = "root"
DB_HOST = "127.0.0.1"
DB_PORT = "5000"
DB_NAME = "FIFA15"


def run_mysql_query(playerid):
    """Exécute la commande MySQL et renvoie le teamid trouvé."""
    cmd = [
        "mysql",
        f"-u{DB_USER}",
        f"-p{DB_PASS}",
        f"-h{DB_HOST}",
        f"-P{DB_PORT}",
        DB_NAME,
        "--skip-column-names",
        "-e",
        f"""SELECT t.teamid
            FROM teams t
            INNER JOIN teamplayerlinks tpl ON t.teamid = tpl.teamid
            WHERE tpl.playerid = '{playerid}'
            ORDER BY t.teamid ASC
            LIMIT 1;"""
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip()


def get_player_name(row):
    """Construit une chaine d'identité du joueur pour les logs."""
    firstname = (row.get("info.name.firstname") or "").strip()
    lastname = (row.get("info.name.lastname") or "").strip()
    jersey = (row.get("info.name.playerjerseyname") or "").strip()
    knownas = (row.get("info.name.knownas") or "").strip()

    full = f"{firstname} {lastname}".strip()

    return f"{full} | jersey='{jersey}' | knownas='{knownas}'"


with open(LOG_FILE, "w") as log, open(CSV_FILE, encoding="utf-8") as f:

    reader = csv.DictReader(f)

    for row in reader:

        csv_teamid = (row.get("info.teams.club_team.id") or "").strip()
        playerid = (row.get("info.playerid") or "").strip()
        player_name = get_player_name(row)

        if not playerid or not csv_teamid:
            log.write(f"[INVALIDE] {player_name} (playerid={playerid}) → données CSV incomplètes\n")
            continue

        db_teamid = run_mysql_query(playerid)

        if db_teamid == "":
            log.write(
                f"[AUCUN TEAM ID] {player_name} (playerid={playerid}) → "
                f"DB='NULL' | CSV={csv_teamid}\n"
            )
        elif db_teamid != csv_teamid:
            log.write(
                f"[MISMATCH] {player_name} (playerid={playerid}) → "
                f"DB={db_teamid} | CSV={csv_teamid}\n"
            )

print(f"Vérification terminée. Résultats dans {LOG_FILE}")
