#!/bin/bash

# ==============================
# Symfony deployment script (safe & full)
# ==============================

PROJECT_NAME="posts"
PROJECT_DIR="/var/www/html/$PROJECT_NAME"
GIT_REPO="git@github.com:Pidhainyi/book.git"
BRANCH="main"
PHP_VERSION="8.2"

echo "🚀 Starting deployment for $PROJECT_NAME..."

# 1️⃣ Проверка существования проекта
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "🔄 Project exists. Pulling latest changes..."
    cd $PROJECT_DIR || exit
    git fetch origin
    git reset --hard origin/$BRANCH
    if [ $? -ne 0 ]; then
        echo "❌ Git pull failed"
        exit 1
    fi
else
    echo "📦 Project not found. Cloning repository..."

    # Клонируем в временную папку
    TMP_DIR="${PROJECT_DIR}_tmp"
    git clone -b $BRANCH $GIT_REPO $TMP_DIR
    if [ $? -ne 0 ]; then
        echo "❌ Git clone failed"
        exit 1
    fi

    # Сохраняем старую версию на случай ошибки
    if [ -d "$PROJECT_DIR" ]; then
        mv "$PROJECT_DIR" "${PROJECT_DIR}_backup"
    fi

    # Перемещаем новую версию на место проекта
    mv "$TMP_DIR" "$PROJECT_DIR"
fi

cd $PROJECT_DIR || exit

# 2️⃣ Установка зависимостей через Composer
echo "📥 Installing PHP dependencies..."
composer install --no-interaction --optimize-autoloader --no-dev
if [ $? -ne 0 ]; then
    echo "❌ Composer install failed"
    exit 1
fi

# 3️⃣ Создание нужных папок Symfony
mkdir -p var/cache var/log public/uploads

# 4️⃣ Настройка прав
echo "🔧 Updating permissions..."
sudo chown -R $USER:www-data $PROJECT_DIR
sudo chmod -R 775 $PROJECT_DIR/var $PROJECT_DIR/vendor $PROJECT_DIR/public/uploads

# 5️⃣ Очистка и прогрев кеша Symfony
echo "⚡ Clearing and warming up Symfony cache..."
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

# 6️⃣ Перезагрузка PHP-FPM
echo "🔄 Restarting PHP-FPM..."
sudo systemctl restart php$PHP_VERSION-fpm

echo "✅ Deployment finished! Project is updated at $PROJECT_DIR"
