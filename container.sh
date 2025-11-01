#!/bin/bash
set -e  # Stoppe le script en cas d'erreur
echo "🚀 Mise à jour du système..."
apt update -y
apt install -y git openssh-server curl gpg lsb-release
curl -fsSL https://mgrosmann.onrender.com/script/projet/docker.sh -o docker.sh
chmod +x docker.sh
bash docker.sh
echo "🧩 Installation de MariaDB client et Python..."
apt install -y mariadb-client-compat
echo "🐬 Lancement du conteneur MySQL Docker (port 5000)..."
docker run -d \
  --name fifa \
  -e MYSQL_ROOT_PASSWORD=root \
  -p 5000:3306 \
  -v mysql_data:/var/lib/mysql \
  mysql:8 \
  --local-infile=1 \
  --secure-file-priv=""
  docker update --restart=always fifa
echo "✅ Configuration terminée !"
echo "➡️  Docker MySQL en écoute sur le port 5000"
echo "➡️  Python virtualenv activé (./venv)"