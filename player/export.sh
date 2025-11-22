#!/bin/bash
# --- export_single_player.sh ---
# Export rapide d’un joueur individuel

DB="FIFA16"
cmd="mysql -uroot -proot -P5000 -h127.0.0.1 -D $DB"

# Condition d’exclusion nationale / all-star
exclude_condition="(
    t.teamname LIKE '%All star%' OR
    t.teamname LIKE '%Adidas%' OR
    t.teamname LIKE '%Nike%' OR
    t.teamname LIKE '% xi%' OR
    t.teamname LIKE '%allstar%' OR
    ltl.leagueid = 78
)"

# --- Recherche par nom ---
read -p "Entrer une partie du nom du joueur : " PlayerName

$cmd -e "
SELECT 
    p.playerid,
    CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
    p.overallrating,
    p.potential,
    t.teamname
FROM players p
INNER JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
INNER JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
INNER JOIN teamplayerlinks tpl  ON p.playerid    = tpl.playerid
INNER JOIN teams t              ON tpl.teamid    = t.teamid
INNER JOIN leagueteamlinks ltl  ON t.teamid      = ltl.teamid
WHERE CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%$PlayerName%'
AND NOT ( $exclude_condition )
ORDER BY CAST(p.playerid AS UNSIGNED) ASC;
"

echo ""
read -p "ID du joueur à exporter : " PLAYERID

OUTPUT_PLAYER="player_export.csv"
OUTPUT_NAMES="player_names.csv"
OUTPUT_TPL="player_tpl.csv"

echo "🔍 Export du joueur ID $PLAYERID ..."

# ----------------------------
# 1. Export complet du joueur
# ----------------------------
$cmd -e "
SELECT *
FROM players p
WHERE p.playerid = $PLAYERID;
" | sed 's/\t/;/g' >> "$OUTPUT_PLAYER"

echo "📄 Export joueurs → $OUTPUT_PLAYER"

# -----------------------------------------------
# 2. Export firstname;lastname;teamid;playerid
# -----------------------------------------------
$cmd -e "
SELECT
    pn_first.name AS firstname,
    pn_last.name AS lastname,
    tpl.teamid,
    p.playerid,
    p.overallrating
FROM players p
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
JOIN teamplayerlinks tpl  ON tpl.playerid  = p.playerid
JOIN teams t              ON tpl.teamid    = t.teamid
JOIN leagueteamlinks ltl  ON tpl.teamid    = ltl.teamid
WHERE p.playerid = $PLAYERID
AND NOT ( $exclude_condition )
ORDER BY CAST(p.playerid AS UNSIGNED) ASC;
" | sed 's/\t/;/g' >> "$OUTPUT_NAMES"

echo "📄 Export noms → $OUTPUT_NAMES"

# ----------------------------
# 3. Export teamplayerlinks
# ----------------------------
$cmd -e "
SELECT tpl.*
FROM teamplayerlinks tpl
JOIN teams t              ON tpl.teamid = t.teamid
JOIN leagueteamlinks ltl  ON tpl.teamid = ltl.teamid
WHERE tpl.playerid = $PLAYERID
AND NOT ( $exclude_condition )
ORDER BY CAST(tpl.playerid AS UNSIGNED) ASC;
" | sed 's/\t/;/g' >> "$OUTPUT_TPL"

echo "📄 Export teamplayerlinks → $OUTPUT_TPL"

echo "✅ Terminé !"
echo "Résultat :"
for f in "$OUTPUT_PLAYER" "$OUTPUT_NAMES" "$OUTPUT_TPL"; do
    echo -n "$f : "
    wc -l < "$f"
done
