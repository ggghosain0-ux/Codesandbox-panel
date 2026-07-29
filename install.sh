#!/bin/bash

clear

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YEL}"
cat << "EOF"
███████╗██╗  ██╗██╗   ██╗     ██████╗ ██╗██████╗ ███████╗
██╔════╝██║  ██║╚██╗ ██╔╝    ██╔════╝██║██╔══██╗██╔════╝
███████╗███████║ ╚████╔╝     ██║     ██║██║  ██║█████╗  
╚════██║██╔══██║  ╚██╔╝      ██║     ██║██║  ██║██╔══╝  
███████║██║  ██║   ██║       ╚██████╗██║██████╔╝███████╗
╚══════╝╚═╝  ╚═╝   ╚═╝        ╚═════╝╚═╝╚═════╝ ╚══════╝
EOF
echo -e "${NC}"

echo -ne "${GRN}🔥 Please Subscribe \n"
for i in {1..3}; do
  echo -ne "${CYN}Subscribing To SKY CODE"
  for dot in {1..3}; do
    echo -n "."
    sleep 0.3
  done
  echo -ne "\r                     \r"
done
echo -e "${GRN} Thanks for Subscribing! If Not Do It Rn${NC}\n"
sleep 1

echo -e "${YEL}X-> Installing Docker and Docker Compose...${NC}"
apt update -y
apt install -y docker.io docker-compose

echo -e "${CYN}X-> Setting up Pterodactyl Panel directories...${NC}"
mkdir -p pterodactyl/panel
cd pterodactyl/panel || exit

echo -e "${CYN}X-> Writing docker-compose.yml...${NC}"
cat <<'EOF' > docker-compose.yml
version: '3.8'

services:
  database:
    image: mariadb:10.11
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - "./data/database:/var/lib/mysql"
    environment:
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"
      MYSQL_PASSWORD: "ptero_db_password_123"
      MYSQL_ROOT_PASSWORD: "ptero_root_password_123"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - "8030:80"
      - "4433:443"
    depends_on:
      - database
      - cache
    volumes:
      - "./data/var:/app/var"
      - "./data/nginx:/etc/nginx/http.d"
      - "./data/certs:/etc/letsencrypt"
      - "./data/logs:/app/storage/logs"
    environment:
      APP_URL: "http://localhost:8030"
      APP_TIMEZONE: "UTC"
      APP_SERVICE_AUTHOR: "noreply@example.com"
      TRUSTED_PROXIES: "*"
      APP_ENV: "production"
      APP_ENVIRONMENT_ONLY: "false"
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_DRIVER: "redis"
      REDIS_HOST: "cache"
      DB_HOST: "database"
      DB_PORT: "3306"
      DB_DATABASE: "panel"
      DB_USERNAME: "pterodactyl"
      DB_PASSWORD: "ptero_db_password_123"
      DB_MYSQL_CLIENT_FLAGS: 0
      MAIL_FROM: "noreply@example.com"
      MAIL_DRIVER: "smtp"
      MAIL_HOST: "mail"
      MAIL_PORT: "1025"
      MAIL_USERNAME: ""
      MAIL_PASSWORD: ""
      MAIL_ENCRYPTION: "true"

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

echo -e "${CYN}X-> Creating data directories...${NC}"
mkdir -p ./data/{database,var,nginx,certs,logs}

echo -e "${GRN}X-> Starting Database and Cache...${NC}"
docker-compose up -d database cache

echo -e "${CYN}X-> Waiting 20 seconds for MariaDB to fully initialize...${NC}"
sleep 20

echo -e "${GRN}X-> Starting Panel Container...${NC}"
docker-compose up -d panel

echo -e "${CYN}X-> Disabling SSL requirement in container MySQL client...${NC}"
docker-compose exec -T panel sh -c 'mkdir -p /etc/my.cnf.d && printf "[client]\nssl=0\nskip-ssl=1\n[mysql]\nssl=0\nskip-ssl=1\n[mariadb-client]\ndisable-ssl-verify-server-cert=1\n" > /etc/my.cnf.d/disable-ssl.cnf'
docker-compose exec -T panel sh -c 'printf "[client]\nssl=0\nskip-ssl=1\n[mysql]\nssl=0\nskip-ssl=1\n[mariadb-client]\ndisable-ssl-verify-server-cert=1\n" >> /etc/my.cnf'

echo -e "${CYN}X-> Generating Encryption Key and Running Migrations...${NC}"
docker-compose exec -T panel php artisan key:generate --force
docker-compose exec -T panel php artisan migrate --seed --force

echo -e "${GRN}X-> Creating Admin User...${NC}"
docker-compose exec -it panel php artisan p:user:make

echo -e "${YEL}✅ All done! Access your panel at http://YOUR_SERVER_IP:8030${NC}"
