#!/bin/bash
# --- import_massive.sh ---
# Import massif de joueurs depuis CSV (optimisé et lisible)
# Si playerid existe déjà ET firstname/lastname identiques, update. Sinon insert.
# Met à jour position et jerseynumber pour teamplayerlinks

DB_NAME="FIFA14"
USER="root"
PASSWORD="root"
HOST="127.0.0.1"
PORT="3306"

PLAYERS_CSV="players.csv"                 # CSV complet des joueurs
NAMES_TEAMS_CSV="players_names_teams.csv" # CSV léger : firstname;lastname;teamid;playerid
TEAMPLAYERLINKS_EXPORT="teamplayerlinks_export.csv"

# --- Étape 0 : Nettoyage / déplacement des joueurs des gros clubs ---
echo "🧹 Déplacement des joueurs de clubs majeurs et de Premier League vers agent libre (111592)..."
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
UPDATE teamplayerlinks tpl
JOIN players p ON p.playerid = tpl.playerid
JOIN teams t ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
SET tpl.teamid = 111592,
    tpl.position = 29
WHERE 
    t.teamid IN (
        21, 22, 32, 34, 44, 45, 46, 47, 48, 52,
        65, 66, 73, 240, 241, 243, 461, 483, 110374
    )
 OR ltl.leagueid = 13;
"
echo "✅ Nettoyage terminé — les joueurs des clubs cibles ont été déplacés."

# --- Étape 1 : Vérification des fichiers ---
for f in "$PLAYERS_CSV" "$NAMES_TEAMS_CSV"; do
    [[ ! -f "$f" ]] && { echo "❌ Fichier manquant : $f"; exit 1; }
done

# --- Étape 2 : Construction du CSV temporaire pour import/update ---
echo "🔍 Analyse des joueurs à importer..."
TMP_PLAYERS="players_to_import.csv"
head -n 1 "$PLAYERS_CSV" > "$TMP_PLAYERS"

new_count=0
declare -A seen_ids

while IFS=";" read -r firstname lastname teamid playerid; do
    [[ "$firstname" == "firstname" ]] && continue
    [[ -n "${seen_ids[$playerid]}" ]] && continue  # évite doublons
    seen_ids[$playerid]=1

    # Échappement des apostrophes
    firstname_esc=$(echo "$firstname" | sed "s/'/''/g")
    lastname_esc=$(echo "$lastname" | sed "s/'/''/g")

    # Vérifie si playerid existe avec le même nom/prénom (LIKE pour noms composés)
    match=$(mysql -N -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -se "
        SELECT 1 FROM players p
        JOIN playernames pf ON p.firstnameid = pf.nameid
        JOIN playernames pl ON p.lastnameid = pl.nameid
        WHERE p.playerid=$playerid
          AND CONCAT(pf.name,' ',pl.name) LIKE '%$firstname_esc%'
          AND CONCAT(pf.name,' ',pl.name) LIKE '%$lastname_esc%';
    ")

    if [[ -z "$match" ]]; then
        # Nouveau joueur ou conflit → ajout au CSV temporaire pour REPLACE
        grep -E ";${playerid}$" "$PLAYERS_CSV" >> "$TMP_PLAYERS"
        ((new_count++))
        if [[ -n "$match" ]]; then
            echo "⚡ PlayerID $playerid ($firstname $lastname) existant — mise à jour prévue."
        else
            echo "✅ PlayerID $playerid ($firstname $lastname) absent — insertion prévue."
        fi
    else
        echo "⚠️ PlayerID $playerid ($firstname $lastname) existe déjà — aucune action sur players."
    fi
done < "$NAMES_TEAMS_CSV"

# --- Étape 3 : Import massif avec REPLACE ---
if [[ $new_count -eq 0 ]]; then
    echo "ℹ️ Aucun joueur à importer ou mettre à jour."
else
    echo "✅ $new_count joueurs à importer/mise à jour. Import en cours..."
    mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
        LOAD DATA LOCAL INFILE '$TMP_PLAYERS'
        REPLACE INTO TABLE players
        FIELDS TERMINATED BY ';'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES;
    "
    echo "📥 Import terminé pour $new_count joueurs."
fi
rm -f "$TMP_PLAYERS"

# --- Étape 4 : Mise à jour des noms et liens équipes, position et jerseynumber ---
echo "🔁 Mise à jour des noms, équipes, position et jerseynumber..."
while IFS=";" read -r firstname lastname teamid playerid; do
    [[ "$firstname" == "firstname" ]] && continue

    mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D"$DB_NAME" -e "
        INSERT IGNORE INTO playernames (nameid, name)
        SELECT IFNULL(MAX(nameid),0)+1, '$firstname' FROM playernames;
        INSERT IGNORE INTO playernames (nameid, name)
        SELECT IFNULL(MAX(nameid),0)+1, '$lastname' FROM playernames;

        UPDATE players
        SET firstnameid=(SELECT nameid FROM playernames WHERE name='$firstname' LIMIT 1),
            lastnameid=(SELECT nameid FROM playernames WHERE name='$lastname' LIMIT 1)
        WHERE playerid=$playerid;

        INSERT INTO teamplayerlinks (playerid, teamid, position, jerseynumber)
        VALUES ($playerid, $teamid, 29, NULL)
        ON DUPLICATE KEY UPDATE 
            position=VALUES(position),
            jerseynumber=IFNULL(VALUES(jerseynumber), jerseynumber);
    "
    echo "✅ $firstname $lastname (ID $playerid) associé à l'équipe $teamid avec position et jerseynumber mis à jour"
done < "$NAMES_TEAMS_CSV"

# --- Étape 5 : Export complet teamplayerlinks ---
echo "💾 Export complet de teamplayerlinks..."
TEAMPLAYERLINKS_OUTPUT="$TEAMPLAYERLINKS_EXPORT"
columns_tpl=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D "$DB_NAME" -Bse "SHOW COLUMNS FROM teamplayerlinks;" | paste -sd";" -)
echo "$columns_tpl" > "$TEAMPLAYERLINKS_OUTPUT"

mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -P"$PORT" -D "$DB_NAME" --batch --skip-column-names -e "
SELECT * FROM teamplayerlinks;
" | sed 's/\t/;/g' >> "$TEAMPLAYERLINKS_OUTPUT"

echo "✅ Export teamplayerlinks terminé : $TEAMPLAYERLINKS_OUTPUT"

echo "🏁 Import et mise à jour terminés avec succès !"
