#!/bin/bash

# ==============================
# Symfony deployment script (prod safe, DoctrineFixturesBundle safe)
# ==============================

set -e

PROJECT_NAME="posts"
PROJECT_DIR="/var/www/html/$PROJECT_NAME"
GIT_REPO="git@github.com:Pidhainyi/book.git"
BRANCH="master"
PHP_VERSION="8.2"

DB_NAME="symfony_db"
DB_USER="symfony_user"
DB_PASS="symfony_pass"
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_VERSION="8.0"

# 1️⃣ Проверка существования проекта
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "🔄 Project exists. Pulling latest changes..."
    cd $PROJECT_DIR || exit
    git fetch origin
    git reset --hard origin/$BRANCH
else
    echo "📦 Project not found. Cloning repository..."
    TMP_DIR="${PROJECT_DIR}_tmp"
    git clone -b $BRANCH $GIT_REPO $TMP_DIR
    if [ -d "$PROJECT_DIR" ]; then
        mv "$PROJECT_DIR" "${PROJECT_DIR}_backup"
    fi
    mv "$TMP_DIR" "$PROJECT_DIR"
fi

cd $PROJECT_DIR || exit

# 2️⃣ Установка зависимостей через Composer
echo "📥 Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader --no-scripts

# 3️⃣ Создание нужных папок Symfony
mkdir -p var/cache var/log public/uploads

# 4️⃣ Настройка прав
echo "🔧 Updating permissions..."
sudo chown -R $USER:www-data $PROJECT_DIR
sudo chmod -R 775 $PROJECT_DIR/var $PROJECT_DIR/vendor $PROJECT_DIR/public/uploads

# 5️⃣ Создание .env.local для продакшн с PostgreSQL
DB_HOST="localhost"
DB_PORT="5432"
DB_VERSION="13"  # версія PostgreSQL

cat > .env.local <<EOL
APP_ENV=prod
APP_DEBUG=0
DATABASE_URL="pgsql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME?serverVersion=$DB_VERSION&charset=utf8"
EOL

# 6️⃣ Полное удаление старого кеша prod (DoctrineFixturesBundle safe)
echo "🧹 Removing old prod cache..."
rm -rf var/cache/prod

# 7️⃣ Очистка и прогрев кеша Symfony
echo "⚡ Clearing and warming up Symfony cache..."
php bin/console cache:warmup --env=prod

# 8️⃣ Запуск миграций
echo "🗄️ Running database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod

# 9️⃣ Перезагрузка PHP-FPM
echo "🔄 Restarting PHP-FPM..."
sudo systemctl restart php$PHP_VERSION-fpm

echo "✅ Deployment finished! Project is updated at $PROJECT_DIR (env=prod)"
