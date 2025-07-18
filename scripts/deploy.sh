#!/bin/bash
set -euo pipefail

# Переменные
PROJECT_DIR="/home/userdev/go/src/banner_service_go"
DOCKER_MODE=true

echo "🚀 Starting Docker deployment..."

cd $PROJECT_DIR

# Обновляем код
echo "📥 Pulling latest code..."
git pull origin main

echo "🐳 Docker deployment..."

# Останавливаем контейнеры
echo "🛑 Stopping containers..."
docker-compose down || true

# Очищаем старые образы (опционально)
# echo "🧹 Cleaning up old images..."
# docker system prune -f || true

# Собираем новые образы
echo "🔨 Building new images..."
docker-compose build

# Запускаем контейнеры
echo "🚀 Starting containers..."
docker-compose up -d

# Ждем запуска
echo "⏳ Waiting for services to start..."
sleep 10

# Проверяем статус
echo "✅ Checking container status..."
docker-compose ps

# Проверяем логи
echo "📋 Recent logs:"
docker-compose logs --tail=20

# Проверяем здоровье приложения
echo "🏥 Health check..."
if curl -f http://localhost:8080/health 2>/dev/null; then
    echo "✅ Application is healthy!"
else
    echo "⚠️ Application health check failed, but deployment completed"
fi

echo "✅ Docker deployment completed!"
echo "🌐 Application should be available at: http://localhost:8080"
