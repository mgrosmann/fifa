#!/bin/bash
DB_NAME="fifa14"
cmd="mysql -uroot -proot -h127.0.0.1 -D ${DB_NAME} -A -e"
$cmd "
-- 1️⃣ Ajouter une ligne vide pour les surnoms si elle n'existe pas
INSERT IGNORE INTO playernames (name, commentaryid) VALUES ('', 900000);

-- 2️⃣ Mettre à jour les joueurs sans surnom pour pointer sur cette ligne
UPDATE players SET commonnameid=LAST_INSERT_ID() WHERE commonnameid=0;
