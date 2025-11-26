#!/bin/bash
# --- Recherche d'un joueur ou d'une équipe dans la base FIFA --- mettre -N pour pas afficher les colonnes
DB="FC26"
USER="root"
PASS="root"
HOST="127.0.0.1"
PORT="5000"
cmd="mysql -u$USER -p$PASS -h127.0.0.1 -P5000 -D $DB -A -e"
exclude_condition="(
    t.teamname LIKE '%All star%'
 OR t.teamname LIKE '%Adidas%'
 OR t.teamname LIKE '%Nike%'
 OR t.teamname LIKE '%world%'
 OR t.teamname LIKE '% xi%'
 OR t.teamname LIKE '%allstar%'
) OR ltl.leagueid = 78"

echo "=== Recherche joueur / équipe ==="
read -p "🔍 Entrez un playerid, teamid ou un nom (partiel) : " query

# Si la saisie est numérique, on demande à l'utilisateur ce que c’est
if [[ "$query" =~ ^[0-9]+$ ]]; then
    echo "🧠 Vous avez entré un identifiant numérique : $query"
    read -p "Est-ce un (p)layerid ou un (t)eamid ? [p/t] : " type
    type=$(echo "$type" | tr '[:upper:]' '[:lower:]')

    if [[ "$type" == "p" ]]; then
        echo "➡ Recherche par playerid = $query..."
        $cmd "
            SELECT p.playerid,
                   p.overallrating,
                   p.potential,
                   CONCAT(pn_first.name, ' ', pn_last.name) AS fullname,
                   t.teamname
            FROM players p
            JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
            JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
            JOIN teamplayerlinks tpl ON p.playerid = tpl.playerid
            JOIN teams t        ON tpl.teamid = t.teamid
            JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
            WHERE p.playerid = $query AND NOT (
      $exclude_condition
  );
        "
    elif [[ "$type" == "t" ]]; then
        echo "➡ Recherche par teamid = $query..."
        $cmd "
            SELECT t.teamname
            FROM teams t
            WHERE t.teamid = $query
        "
    else
        echo "❌ Réponse invalide (veuillez taper 'p' ou 't')."
        exit 1
    fi

else
    # Si c'est du texte → recherche sur le nom
    echo "➡ Recherche par nom contenant '$query'..."
    $cmd "
        SELECT p.playerid,
               p.overallrating,
               p.potential,
               t.teamname,
               CONCAT(pn_first.name, ' ', pn_last.name) AS fullname
        FROM teamplayerlinks tpl
        JOIN teams t        ON tpl.teamid = t.teamid
        JOIN players p      ON tpl.playerid = p.playerid
        JOIN playernames pn_first ON p.firstnameid = pn_first.nameid
        JOIN playernames pn_last  ON p.lastnameid  = pn_last.nameid
        JOIN leagueteamlinks ltl ON t.teamid = ltl.teamid
        WHERE CONCAT(pn_first.name, ' ', pn_last.name) LIKE '%$query%' AND NOT (
      $exclude_condition
  )
        ORDER BY concat(pn_first.name, ' ', pn_last.name);
    "
fi
