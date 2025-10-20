#!/bin/bash
# ===========================================
# ⚽ Mise à jour leagueid = 20 pour Germany 2. Bundesliga (FIFA14 et FIFA16)
# Désactive temporairement le mode safe updates
# ===========================================

MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="5000"

SQL=$(cat <<'EOF'
SET SQL_SAFE_UPDATES = 0;

UPDATE FIFA14.leagues
SET leagueid = 20
WHERE leaguename LIKE 'Germany 2.%';

UPDATE FIFA16.leagues
SET leagueid = 20
WHERE leaguename LIKE 'Germany 2.%';

SET SQL_SAFE_UPDATES = 1;
EOF
)

mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -h"$MYSQL_HOST" -P"$MYSQL_PORT" -e "$SQL"

echo "✅ leagueid mis à jour à 20 pour Germany 2. Bundesliga dans FIFA14 et FIFA16."
