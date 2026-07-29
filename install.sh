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

echo -e "${YEL}X-> Cleaning old volumes and starting clean...${NC}"
docker-compose down -v --remove-orphans 2>/dev/null
rm -rf ./data

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

echo -e "${CYN}X-> Starting containers...${NC}"
docker-compose up -d

echo -e "${CYN}X-> Waiting 20 seconds for MariaDB to boot...${NC}"
sleep 20

echo -e "${CYN}X-> Disabling SSL requirement in MySQL client...${NC}"
docker-compose exec -T panel sh -c 'mkdir -p /etc/my.cnf.d && printf "[client]\nssl=0\nskip-ssl=1\n[mysql]\nssl=0\nskip-ssl=1\n" > /etc/my.cnf.d/disable-ssl.cnf'

echo -e "${CYN}X-> Generating Encryption Key...${NC}"
docker-compose exec -T panel php artisan key:generate --force

echo -e "${CYN}X-> Migrating Database Schema...${NC}"
docker-compose exec -T panel php artisan migrate:fresh --seed --force

echo -e "${GRN}X-> Creating Admin Account (Non-Interactive)...${NC}"
docker-compose exec -T panel php artisan p:user:make \
  --email="admin@example.com" \
  --username="admin" \
  --firstname="Admin" \
  --lastname="User" \
  --password="Password123!" \
  --admin=1 \
  --no-interaction

echo -e "${YEL}--------------------------------------------------${NC}"
echo -e "${GRN}✅ Installation Complete!${NC}"
echo -e "${CYN}Email:    ${YEL}admin@example.com${NC}"
echo -e "${CYN}Password: ${YEL}Password123!${NC}"
echo -e "${YEL}--------------------------------------------------${NC}"
