#!/bin/bash

# ===========================
# Symfony provisioning script (PostgreSQL + Nginx inline)
# ===========================

set -e

PROJECT_NAME="posts"
PROJECT_DIR="/var/www/html/$PROJECT_NAME"
PHP_VERSION="8.2"
DOMAIN="andriipidhainyi.site"
EMAIL="andriipidhainyi@gmail.com"
DB_NAME="symfony_db"
DB_USER="symfony_user"
DB_PASS="symfony_pass"
DB_PORT=5432

echo "🚀 Starting Symfony provisioning..."

# 1️⃣ Обновление системы
sudo apt update && sudo apt upgrade -y

# 2️⃣ Установка инструментов
sudo apt install -y git unzip curl wget software-properties-common lsb-release gnupg

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

# 7️⃣ Настройка PostgreSQL
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
       CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
   END IF;
END
\$\$;

DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
       CREATE DATABASE $DB_NAME OWNER $DB_USER;
   END IF;
END
\$\$;
EOF
echo "✅ PostgreSQL user and database created"

# 8️⃣ Настройка прав и директорий для проекта
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:www-data $PROJECT_DIR
sudo chmod -R 775 $PROJECT_DIR

# 9️⃣ Создание .env.local для prod
cat > $PROJECT_DIR/.env.local <<EOL
APP_ENV=prod
APP_DEBUG=0
DATABASE_URL="pgsql://$DB_USER:$DB_PASS@127.0.0.1:$DB_PORT/$DB_NAME"
EOL
echo "✅ .env.local created"

# 🔟 Настройка Nginx inline
NGINX_CONF="/etc/nginx/sites-available/$PROJECT_NAME"
cat <<EOL | sudo tee $NGINX_CONF
# Redirect HTTP → HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    root $PROJECT_DIR/public;
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht { deny all; }
    location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|eot)\$ {
        try_files \$uri /index.php\$is_args\$args;
        access_log off; log_not_found off; expires max;
    }
}
EOL

sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "✅ Nginx configured"

# 1️⃣1️⃣ HTTPS через Certbot
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# 1️⃣2️⃣ Перезагрузка PHP-FPM
sudo systemctl enable php$PHP_VERSION-fpm
sudo systemctl restart php$PHP_VERSION-fpm

echo "✅ Provisioning finished! Symfony ready with PostgreSQL, Nginx, and HTTPS."
