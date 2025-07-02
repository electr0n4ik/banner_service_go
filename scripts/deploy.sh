# Выходим при первой ошибке
set -e

echo "🔄 Остановка текущего контейнера"
docker-compose down || true

echo "🔄 Обновление кода"
cd /home/userdev/go/src/banner_service_go
git pull origin main

echo "🚀 Пересборка и запуск контейнеров"
docker-compose up --build -d

echo "✅ Деплой успешно завершен"