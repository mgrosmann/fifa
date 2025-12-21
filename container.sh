#!/bin/bash
set -e  # Stoppe le script en cas d'erreur
echo "🚀 Mise à jour du système..."
apt update -y
apt install -y git openssh-server curl gpg lsb-release
curl -fsSL https://mgrosmann.onrender.com/script/projet/docker.sh -o docker.sh
chmod +x docker.sh
bash docker.sh
echo "🧩 Installation de MariaDB client..."
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
echo "alias sql='mysql -u root -proot -h127.0.0.1 -P5000 -A'" >> ~/.bashrc
echo "alias sql14='mysql -u root -proot -h127.0.0.1 -DFIFA14 -P5000 -A'" >> ~/.bashrc
echo "alias sql15='mysql -u root -proot -h127.0.0.1 -DFIFA15 -P5000 -A'" >> ~/.bashrc
echo "alias sql16='mysql -u root -proot -h127.0.0.1 -DFIFA16 -P5000 -A'" >> ~/.bashrc
echo "alias sql18='mysql -u root -proot -h127.0.0.1 -DFIFA1518 -P5000 -A'" >> ~/.bashrc
echo "alias vide='>'" >> ~/.bashrc
echo "alias fifa='cd /mnt/c/github/fifa'" >> ~/.bashrc
echo "alias home='cd /mnt/c/Users/PC'" >> ~/.bashrc
echo "alias regen='source ~/.bashrc'" >> ~/.bashrc
echo "alias dump='mysqldump -uroot -proot -h127.0.0.1 -P5000'" >> ~/.bashrc
echo "penser à faire 'source ~/.bashrc'"
apt install python3.11-venv -y
apt install python3-full -y
python3 -m venv venv
source venv/bin/activate
apt install pip -y
pip install pandas datetime mysql.connector

