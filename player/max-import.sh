#!/bin/bash
# --- import_massive.sh ---
# Import massif de joueurs depuis CSV (optimisé et lisible)

DB_NAME="FIFA16"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="3306"

PLAYERS_CSV="players.csv"                 # CSV complet des joueurs
NAMES_TEAMS_CSV="players_names_teams.csv" # CSV léger : firstname;lastname;teamid;playerid

# Vérifie les fichiers
for f in "$PLAYERS_CSV" "$NAMES_TEAMS_CSV"; do
    [[ ! -f "$f" ]] && { echo "❌ Fichier manquant : $f"; exit 1; }
done

echo "🔍 Analyse des nouveaux joueurs à importer..."
TMP_PLAYERS="players_to_import.csv"
head -n 1 "$PLAYERS_CSV" > "$TMP_PLAYERS"

new_count=0
while IFS=";" read -r firstname lastname teamid playerid; do
    [[ "$firstname" == "firstname" ]] && continue
    exists=$(mysql -N -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -se \
        "SELECT 1 FROM players WHERE playerid=$playerid LIMIT 1;")
    if [[ -z "$exists" ]]; then
        # Copier la ligne correspondant au playerid dans le CSV temporaire
        grep -E ";${playerid}$" "$PLAYERS_CSV" >> "$TMP_PLAYERS"
        ((new_count++))
    fi
done < "$NAMES_TEAMS_CSV"

if [[ $new_count -eq 0 ]]; then
    echo "ℹ️ Aucun nouveau joueur à importer."
else
    echo "✅ $new_count nouveaux joueurs trouvés. Import en cours..."
    mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
        LOAD DATA LOCAL INFILE '$TMP_PLAYERS'
        INTO TABLE players
        FIELDS TERMINATED BY ';'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES;"
    echo "📥 $new_count joueurs importés dans la table 'players'."
fi
rm -f "$TMP_PLAYERS"

echo "🔁 Mise à jour des noms et des équipes..."
while IFS=";" read -r firstname lastname teamid playerid; do
    [[ "$firstname" == "firstname" ]] && continue

    # INSERT IGNORE pour firstname et lastname afin d'éviter les SELECT multiples
    mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
        INSERT IGNORE INTO playernames (nameid, name)
        SELECT IFNULL(MAX(nameid),0)+1, '$firstname' FROM playernames;
        INSERT IGNORE INTO playernames (nameid, name)
        SELECT IFNULL(MAX(nameid),0)+1, '$lastname' FROM playernames;
        UPDATE players
        SET firstnameid=(SELECT nameid FROM playernames WHERE name='$firstname' LIMIT 1),
            lastnameid=(SELECT nameid FROM playernames WHERE name='$lastname' LIMIT 1)
        WHERE playerid=$playerid;
        INSERT IGNORE INTO teamplayerlinks (playerid, teamid, position)
        VALUES ($playerid, $teamid, 29);"
    echo "✅ $firstname $lastname (ID $playerid) associé à l'équipe $teamid"
done < "$NAMES_TEAMS_CSV"

echo "🏁 Import terminé avec succès !"
