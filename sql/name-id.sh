#!/bin/bash
DB_NAME="fifa14"
cmd="mysql -uroot -proot -h127.0.0.1 -D ${DB_NAME} -A -e"
$cmd "
INSERT IGNORE INTO playernames (name, commentaryid) VALUES ('', 900000);

SET @empty_id = (SELECT nameid FROM playernames WHERE name='' LIMIT 1);

-- Mettre à jour tous les joueurs sans surnom
UPDATE players SET commonnameid=@empty_id WHERE commonnameid=0;"