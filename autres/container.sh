apt UPDATE
apt install git -y
apt install openssh-server -y
apt install curl -y
apt install gpg -y
apt install lsb-release -y
curl https://mgrosmann.onrender.com/script/projet/docker.sh > docker.sh
bash docker.sh
apt install mariadb-client-compat -y
apt install python3-pip -y
apt install python3-venv -y
python3 -m venv venv
source venv/bin/activate
pip install pandas
docker run -d \
  --name fifa \
  -e MYSQL_ROOT_PASSWORD=root \
  -p 5000:3306 \
  -v mysql_data:/var/lib/mysql \
  mysql:8 \
  --local-infile=1 \
  --secure-file-priv=""