apt UPDATE
apt install openssh-server -y
apt install curl -y
apt install gpg -y
apt install lsb-release -y
curl https://mgrosmann.onrender.com/script/projet/docker.sh
apt install mariadb-client-compat -y
docker run -d \
  --name fifa \
  -e MYSQL_ROOT_PASSWORD=root \
  -p 5000:3306 \
  -v mysql_data:/var/lib/mysql \
  mysql:8 \
  --local-infile=1 \
  --secure-file-priv=""
#mysql -uroot -proot -P 5000 -h 127.0.0.1