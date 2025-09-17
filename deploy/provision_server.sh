#!/bin/bash

# ===========================
# Symfony provisioning script
# ===========================

PROJECT_NAME="posts"
PROJECT_DIR="/var/www/html/$PROJECT_NAME"
DB_NAME="symfony_db"
DB_USER="symfony_user"
DB_PASS="symfony_pass"
PHP_VERSION="8.2"
NGINX_CONF_SRC="./nginx_posts.conf"  # файл конфігурації поруч зі скриптом
DOMAIN="andriipidhainyi.site"
EMAIL="andriipidhainyi@gmail.com"       # замени на свой email для Certbot


echo "🚀 Starting Symfony provisioning..."

# 1️⃣ Обновление системы
sudo apt update && sudo apt upgrade -y

# 2️⃣ Установка базовых инструментов
sudo apt install -y git unzip curl wget software-properties-common

# 3️⃣ Установка PHP и расширений
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-curl php$PHP_VERSION-intl php$PHP_VERSION-zip php$PHP_VERSION-sqlite3 php$PHP_VERSION-mysql php$PHP_VERSION-gd php$PHP_VERSION-bcmath php$PHP_VERSION-fpm

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

# 6️⃣ Установка MySQL
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql

# 7️⃣ Создание базы данных и пользователя
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
echo "✅ MySQL database and user created"

# 8️⃣ Настройка прав и директорий для проекта
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:www-data $PROJECT_DIR
sudo chmod -R 775 $PROJECT_DIR

# 9️⃣ Настройка виртуального хоста Nginx из внешнего файла
NGINX_CONF_DEST="/etc/nginx/sites-available/$PROJECT_NAME"
sudo cp $NGINX_CONF_SRC $NGINX_CONF_DEST
sudo ln -sf $NGINX_CONF_DEST /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
echo "✅ Nginx virtual host configured for $DOMAIN and 217.24.174.16"

# 🔒 Настройка HTTPS через Certbot
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# 10️⃣ Перезагрузка PHP-FPM
sudo systemctl enable php$PHP_VERSION-fpm
sudo systemctl restart php$PHP_VERSION-fpm

echo "✅ Provisioning finished! Server is ready for Symfony with HTTPS."
echo "Project directory: $PROJECT_DIR"
echo "Database: $DB_NAME, User: $DB_USER"
echo "Domain HTTPS: https://$DOMAIN"
