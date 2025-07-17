Полная инструкция для деплоя на Ubuntu сервер
1. Подготовка сервера
bash
# Подключитесь к серверу
ssh userdev@SERVER_IP

# Обновите систему
sudo apt update && sudo apt upgrade -y
sudo reboot

# Установите зависимости
sudo apt install -y git golang-go docker.io docker-compose ufw

# Настройте firewall
sudo ufw allow 22
sudo ufw allow 8080
sudo ufw enable

# Настройте Go
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc

# Разрешите пользователю работать с Docker
sudo usermod -aG docker userdev
newgrp docker
2. Настройка GitHub Secrets
В настройках репозитория GitHub:

Settings → Secrets and variables → Actions

Добавьте:

SSH_HOST: IP сервера

SSH_PORT: 22

SSH_USERNAME: userdev

SSH_PRIVATE_KEY: Содержимое приватного SSH-ключа

SERVICE_PORT: 8080

JWT_SECRET: Случайная строка (можно сгенерировать: openssl rand -hex 32)

POSTGRES_PASSWORD: Пароль для БД

3. Подготовка файлов проекта
Создайте на сервере структуру:

bash
mkdir -p ~/go/src/banner_service_go/{configs,scripts}
4. Создайте необходимые файлы
A. configs/banner.service

ini
[Unit]
Description=Banner Service
After=network.target

[Service]
Type=simple
User=userdev
WorkingDirectory=/home/userdev/go/src/banner_service_go
ExecStart=/home/userdev/go/src/banner_service_go/bin/banner_service
Restart=always
RestartSec=5
EnvironmentFile=/etc/banner_service.env

[Install]
WantedBy=multi-user.target
B. scripts/deploy.sh

bash
#!/bin/bash
set -euo pipefail

PROJECT_DIR="/home/userdev/go/src/banner_service_go"
cd $PROJECT_DIR

# Остановка сервиса
sudo systemctl stop banner.service || true

# Обновление кода
git fetch origin
git reset --hard origin/main

# Установка зависимостей
go mod tidy

# Сборка
go build -o ./bin/banner_service ./cmd/main.go

# Настройка окружения
sudo tee /etc/banner_service.env > /dev/null <<EOF
APP_PORT=8080
POSTGRES_URL=postgres://user:$POSTGRES_PASSWORD@localhost:5432/banners?sslmode=disable
REDIS_ADDR=localhost:6379
JWT_SECRET=$JWT_SECRET
CACHE_TTL=5m
EOF

# Настройка systemd
sudo cp ./configs/banner.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable banner.service
sudo systemctl start banner.service

# Проверка
sleep 5
curl -sf http://localhost:8080/health || (echo "Health check failed!"; exit 1)
C. docker-compose.yml

yaml
version: '3.8'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: banners
      POSTGRES_USER: user
      POSTGRES_PASSWORD: $POSTGRES_PASSWORD
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
    ports: ["6379:6379"]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
5. Настройка CI/CD
Добавьте в .github/workflows/deploy.yml:

yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
      
      - name: Copy files to server
        uses: appleboy/scp-action@v1.0.0
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          port: ${{ secrets.SSH_PORT }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          source: "."
          target: "/home/userdev/go/src/banner_service_go"
          strip_components: 1
      
      - name: Run deployment script
        run: |
          ssh -o StrictHostKeyChecking=no \
              -p "${{ secrets.SSH_PORT }}" \
              "${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }}" \
              "cd ~/go/src/banner_service_go && \
               chmod +x scripts/deploy.sh && \
               POSTGRES_PASSWORD='${{ secrets.POSTGRES_PASSWORD }}' \
               JWT_SECRET='${{ secrets.JWT_SECRET }}' \
               ./scripts/deploy.sh"
      
      - name: Health check
        run: |
          curl -sf \
            http://${{ secrets.SSH_HOST }}:${{ secrets.SERVICE_PORT }}/health
6. Первый запуск на сервере
bash
# Запустите базы данных
cd ~/go/src/banner_service_go
docker-compose up -d

# Дайте права скрипту
chmod +x scripts/deploy.sh

# Запустите деплой (вручную для инициализации)
POSTGRES_PASSWORD='ваш_пароль' \
JWT_SECRET='ваш_секрет' \
./scripts/deploy.sh
7. Запуск CI/CD
Закоммитьте все файлы

Запушьте в ветку main

GitHub Actions автоматически развернёт приложение

8. Проверка
bash
# Проверка сервиса
sudo systemctl status banner.service

# Проверка логов
journalctl -u banner.service -f

# Проверка API
curl http://SERVER_IP:8080/health
Если возникнут проблемы
Проверьте логи сервиса:

bash
journalctl -u banner.service -f
Проверьте работу баз данных:

bash
docker ps
docker logs banner-postgres
Проверьте подключение:

bash
nc -zv localhost 5432  # PostgreSQL
nc -zv localhost 6379  # Redis
Для отладки CI/CD:

В GitHub: Actions → Выберите workflow → Просмотр логов

