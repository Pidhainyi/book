#!/bin/bash

# ===========================
# Symfony provisioning script (PostgreSQL + Nginx separate files)
# ===========================

set -e

PROJECT_NAME="posts"
PROJECT_DIR="/var/www/html/$PROJECT_NAME"
PHP_VERSION="8.2"
DOMAIN="andriipidhainyi.site"
EMAIL="andriipidhainyi@gmail.com"

echo "🚀 Starting Symfony provisioning..."

# 1️⃣ Обновление системы
sudo apt update && sudo apt upgrade -y

# 2️⃣ Установка инструментов
sudo apt install -y git unzip curl wget software-properties-common

# 3️⃣ Установка PHP и расширений
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-mbstring \
php$PHP_VERSION-xml php$PHP_VERSION-curl php$PHP_VERSION-intl php$PHP_VERSION-zip \
php$PHP_VERSION-pgsql php$PHP_VERSION-gd php$PHP_VERSION-bcmath php$PHP_VERSION-fpm

# 4️⃣ Установка Composer
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")
if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    >&2 echo 'ERROR: Invalid Composer installer signature'
    rm composer-setup.php
    exit 1
fi
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php
composer -V
echo "✅ Composer installed successfully"

# 5️⃣ Установка Nginx
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# 6️⃣ Установка PostgreSQL 13
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-13 postgresql-client-13
sudo systemctl enable postgresql
sudo systemctl start postgresql

# 7️⃣ Настройка PostgreSQL (выполнение отдельного SQL файла)
sudo -u postgres psql -f ./postgres_setup.sql
echo "✅ PostgreSQL configured"

# 8️⃣ Настройка прав и директорий для проекта
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:www-data $PROJECT_DIR
sudo chmod -R 775 $PROJECT_DIR

# 9️⃣ Настройка Nginx (копирование конфигурации)
sudo cp ./nginx_posts.conf /etc/nginx/sites-available/$PROJECT_NAME
sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "✅ Nginx configured"

# 🔒 Настройка HTTPS через Certbot
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# 🔟 Перезагрузка PHP-FPM
sudo systemctl enable php$PHP_VERSION-fpm
sudo systemctl restart php$PHP_VERSION-fpm

echo "✅ Provisioning finished! Server is ready for Symfony with HTTPS and PostgreSQL."
