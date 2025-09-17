#!/bin/bash

set -ex

SSH_USER=$1
SERVER_IP=$2
MYSQL_PASSWORD=$3

PUBLIC_SSH_KEY=$(cat $HOME/.ssh/id_ed25519.pub)

# Копируем SSH ключ
scp -C -o StrictHostKeyChecking=no -i $HOME/.ssh/id_ed25519 $HOME/.ssh/id_ed25519 $SSH_USER@$SERVER_IP:~/.ssh/id_rsa
ssh -tt -o StrictHostKeyChecking=no -i $HOME/.ssh/id_ed25519 $SSH_USER@$SERVER_IP "ssh-keyscan github.com >> ~/.ssh/known_hosts"

# Копируем и запускаем provisioning
scp -C -o StrictHostKeyChecking=no -i $HOME/.ssh/id_ed25519 ./provision_server.sh $SSH_USER@$SERVER_IP:./provision_server.sh
ssh -tt -o StrictHostKeyChecking=no -i $HOME/.ssh/id_ed25519 $SSH_USER@$SERVER_IP "chmod +x ./provision_server.sh && ./provision_server.sh $MYSQL_PASSWORD \"$PUBLIC_SSH_KEY\""

# Обновляем known_hosts ещё раз
ssh -tt -o StrictHostKeyChecking=no -i $HOME/.ssh/id_ed25519 $SSH_USER@$SERVER_IP "ssh-keyscan github.com >> /home/andrii/.ssh/known_hosts"

# 🔹 Копируем и запускаем деплой скрипт
scp -C -o StrictHostKeyChecking=no -i $HOME/.ssh/id_ed25519 ./deploy.sh $SSH_USER@$SERVER_IP:./deploy.sh
ssh -tt -o StrictHostKeyChecking=no -i $HOME/.ssh/id_ed25519 $SSH_USER@$SERVER_IP "chmod +x ./deploy.sh && ./deploy.sh"
