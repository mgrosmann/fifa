#!/bin/bash
# --- max_export.sh ---
# Export ciblé : clubs majeurs + PL + joueurs 85+ ou potentiel élevé + réserve + exclusions AllStar/Nike/etc
# --- Variables pour équipes ---
#de 44 a 52 (avec 110374) serie a, de 59 a 219 ligue 1|  de 240 a 483 liga, de 245 a 247 eredivisie, de 1 a 1917 premier league, de 21 a 1825 bundesliga
AUTHORISED_TEAMS="44,45,46,47,48,52,110374,59,65,66,69,73,219,240,241,243,449,461,483,245,247,1,2,3,4,5,7,9,10,11,12,13,18,19,88,89,106,109,144,1790,1917,21,22,23,28,29,31,32,34,36,38,159,166,169,171,175,485,1824,1825"
DB="FIFA16"
cmd="mysql -uroot -proot -P5000 -h127.0.0.1 -D $DB"

# 🔥 Condition d’exclusion (équipes spéciales / nationales / marque)
exclude_condition="(
    t.teamname LIKE '%All star%'
 OR t.teamname LIKE '%Adidas%'
 OR t.teamname LIKE '%Nike%'
 OR t.teamname LIKE '% xi%'
 OR t.teamname LIKE '%allstar%'
 OR ltl.leagueid = 78
)"

# 🔥 Condition d’autorisation globale
authorized_condition="(
       tpl.teamid IN ($AUTHORISED_TEAMS)
    OR p.overallrating >= 85
    OR p.potential >= 85
    OR (p.potential - p.overallrating) >= 15
    OR p.playerid in (138654, 1607)
)
AND NOT ($exclude_condition)"

OUTPUT_FILE="players.csv"
OUTPUT_NAMES="playernames.csv"
OUTPUT_TPL="teamplayerlinks.csv"


echo "🔍 Export des joueurs filtrés…"

# ===================================================================
# 1) EXPORT players (filtrés)
# ===================================================================

echo "export de la table players"

$cmd -e "
SELECT DISTINCT p.*
FROM players p
JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
JOIN teamplayerlinks tpl  ON tpl.playerid  = p.playerid
JOIN teams t              ON tpl.teamid    = t.teamid
JOIN leagueteamlinks ltl  ON tpl.teamid    = ltl.teamid
WHERE $authorized_condition
ORDER BY CAST(p.playerid AS UNSIGNED) ASC;
" | sed 's/\t/;/g' > "$OUTPUT_FILE"

echo "📥 Export filtré enregistré dans : $OUTPUT_FILE"

# ===================================================================
# 2) EXPORT players_names_teams.csv
# ===================================================================

$cmd -e "
SELECT DISTINCT
    p.playerid,
    pn_first.name AS firstname,
    pn_last.name  AS lastname,
    pn_common.name AS commonname,
    pn_jersey.name AS playerjerseyname
FROM players p
JOIN playernames pn_first   ON p.firstnameid = pn_first.nameid
JOIN playernames pn_last    ON p.lastnameid  = pn_last.nameid
LEFT JOIN playernames pn_common  ON p.commonnameid        = pn_common.nameid
LEFT JOIN playernames pn_jersey  ON p.playerjerseynameid  = pn_jersey.nameid
JOIN teamplayerlinks tpl     ON tpl.playerid = p.playerid
JOIN teams t                 ON tpl.teamid   = t.teamid
JOIN leagueteamlinks ltl     ON tpl.teamid   = ltl.teamid
WHERE $authorized_condition
ORDER BY CAST(p.playerid AS UNSIGNED) ASC;
" | sed 's/\t/;/g' > "$OUTPUT_NAMES"

echo "💾 CSV léger exporté dans : $OUTPUT_NAMES"

# ===================================================================
# 3) EXPORT teamplayerlinks
# ===================================================================

$cmd -e "
SELECT DISTINCT tpl.*
FROM teamplayerlinks tpl
JOIN players p           ON tpl.playerid = p.playerid
JOIN teams t             ON tpl.teamid   = t.teamid
JOIN leagueteamlinks ltl ON tpl.teamid   = ltl.teamid
WHERE $authorized_condition
ORDER BY CAST(tpl.playerid AS UNSIGNED) ASC;
" | sed 's/\t/;/g' > "$OUTPUT_TPL"

echo "💾 Export de teamplayerlinks enregistré dans : $OUTPUT_TPL"

# ===================================================================
# 4) Comptage final
# ===================================================================

echo "✅ Export complet terminé."
echo "Les fichiers générés et leurs nombres de lignes :"
for f in "$OUTPUT_FILE" "$OUTPUT_NAMES" "$OUTPUT_TPL"; do
    echo -n "$f : "
    wc -l < "$f"
done

