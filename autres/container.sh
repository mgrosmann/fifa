apt UPDATE
apt install curl -y
apt install gpg -y
apt install lsb-release -y
curl https://mgrosmann.onrender.com/script/projet/docker.sh
apt install mariadb-client-compat -y
docker run -d \
  --name fifa \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=fifa \
  -p 5000:3306 \
  mysql:latest
#mysql -uroot -proot -P 5000 -h 127.0.0.1