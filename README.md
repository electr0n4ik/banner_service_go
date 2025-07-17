Добавить функции:
- загрузка баннеров из файла пачкой

### Структура проекта (Clean Architecture)

```
banner-service-go/
├── cmd/                  # Точки входа (main-файлы)
│   └── main.go           # Запуск HTTP-сервера
│   └── worker.go         # Запуск воркера для RabbitMQ
├── internal/
│   ├── domain/           # ЯДРО: бизнес-сущности и интерфейсы
│   │   ├── banner.go     # Структура Banker (FeatureID, TagIDs и т.д.)
│   │   └── repository.go # Интерфейсы типа BannerRepository
│   ├── repository/       # ИНФРАСТРУКТУРА: работа с данными
│   │   ├── postgres.go   # Реализация для PostgreSQL
│   │   └── redis.go      # Кеширование через Redis
│   ├── service/          # БИЗНЕС-ЛОГИКА: правила обработки
│   │   └── banner.go     # Методы GetBanner(), CreateBannerVersion()
│   └── delivery/         # ДОСТАВКА: преобразование в HTTP/GRPC
│       └── http/
│           ├── handler.go # Обработчики Gin
│           └── middleware.go # JWT-аутентификация
├── migrations/           # SQL-скрипты для инициализации БД
│   └── 001_init.sql
├── scripts/              # Вспомогательные скрипты
│   └── migrate.go        # Применение миграций
├── .github/workflows/    # CI/CD пайплайны
│   └── ci-cd.yml         # Конфиг GitHub Actions
├── Dockerfile            # Сборка production-образа
├── docker-compose.yml    # Локальная разработка
└── go.mod                # Go-зависимости
```

Нарисовать дерево проекта:

```
sudo apt install tree
tree
```

### Применение миграций:

```
docker-compose run --rm app go run scripts/migrate.go
```

```
Линтер	Решаемые проблемы	Важность для Junior
govet	Корректность кода	★★★★★ (обязателен)
errcheck	Необработанные ошибки	★★★★★
gosimple	Упрощение кода	★★★★☆
staticcheck	Находит реальные баги	★★★★☆
unused	Удаление мертвого кода	★★★☆☆
gofmt	Единый стиль кода	★★★★★
goimports	Сортировка импортов	★★★★☆
```

Сводный отчет линтера:

```
golangci-lint run --out-format=tab
```

### 1. Создание проекта в GitHub для пет-проекта
**Пошаговая инструкция:**

1. **Создайте новый репозиторий**
   - Нажмите "+" в правом верхнем углу GitHub → "New repository"
   - Заполните:
     - Repository name: `banner-service`
     - Description: "Pet-project for banner management service"
     - Public/Private: выберите Private если не хотите публичности
     - Initialize with: ✓ Add a README file

2. **Создайте GitHub Project**
   - В репозитории перейдите во вкладку "Projects"
   - "New project" → выберите шаблон "Kanban"
   - Назовите: "Banner Service Roadmap"

3. **Настройте доску проекта**
   ```mermaid
   graph LR
   A[To Do] --> B[In Progress]
   B --> C[Review]
   C --> D[Done]
   ```

4. **Добавьте задачи (пример):**
   | Статус      | Задачи |
   |-------------|--------|
   | To Do       | - Создать API для баннеров<br>- Реализовать аутентификацию<br>- Написать Dockerfile |
   | In Progress | - ... |
   | Done        | - Инициализация проекта |

5. **Интеграция с Issues**
   - Создавайте Issues для каждой задачи
   - В Issue нажмите "Projects" → привяжите к вашему проекту
   - Перетаскивайте карточки между статусами

---

### 2. Развертывание на рабочей машине (фоновый запуск)
**Лучшее решение: Docker Compose + Systemd**

1. Создайте `docker-compose.yml` в репозитории:
```yaml
version: '3.8'
services:
  banner-service:
    image: yourusername/banner-service:latest
    build: .
    ports:
      - "8080:8080"
    restart: always
    volumes:
      - ./config:/app/config
```

2. Создайте systemd сервис (`/etc/systemd/system/banner.service`):
```ini
[Unit]
Description=Banner Service
After=docker.service

[Service]
User=userdev
WorkingDirectory=/home/userdev/banner-service
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always

[Install]
WantedBy=multi-user.target
```

3. Запустите:
```bash
sudo systemctl daemon-reload
sudo systemctl enable banner.service
sudo systemctl start banner.service
```

**Проверка:**
```bash
systemctl status banner.service
curl http://localhost:8080/healthcheck
```

---

### 3. Минималистичный фронтенд для сервиса баннеров
**Оптимальные технологии:**

| Технология | Почему подходит | Пример использования |
|------------|-----------------|----------------------|
| **Vue.js** + **Tailwind CSS** | Легкий вход, компонентный подход | [Vite](https://vitejs.dev/) шаблон |
| **React** + **Chakra UI** | Готовые компоненты | [Create React App](https://create-react-app.dev/) |
| **Pure HTML/CSS** + **HTMX** | Нет сборки, минимализм | [HTMX](https://htmx.org/) + [Bulma](https://bulma.io/) |

**Старт за 5 минут (Vue.js вариант):**

1. Инициализируйте фронтенд в отдельной директории:
```bash
npm create vue@latest frontend
# Выберите: TypeScript, Pinia, ESLint
```

2. Установите зависимости:
```bash
cd frontend
npm install axios tailwindcss
npx tailwindcss init
```

3. Настройте `tailwind.config.js`:
```js
module.exports = {
  content: ["./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

4. Создайте компонент баннера (`src/components/BannerCard.vue`):
```vue
<template>
  <div class="border rounded-lg p-4 shadow hover:shadow-lg transition">
    <img :src="banner.imageUrl" class="mb-3 rounded w-full h-32 object-cover">
    <h3 class="font-bold text-lg">{{ banner.title }}</h3>
    <p>{{ banner.description }}</p>
  </div>
</template>

<script setup>
defineProps({
  banner: Object
})
</script>
```

5. Подключитесь к бэкенду (`src/services/api.js`):
```js
import axios from 'axios'

export default {
  async getBanners() {
    const response = await axios.get('http://localhost:8080/api/banners')
    return response.data
  }
}
```

---

### Дополнительные рекомендации
1. **Автоматическое обновление на сервере:**
   - Настройте GitHub Actions для автоматического билда при пуше в main
   - Добавьте скрипт авто-деплота через SSH

2. **Мониторинг:**
   - Установите [Uptime Kuma](https://github.com/louislam/uptime-kuma) для отслеживания работы сервиса

3. **Фронтенд-деплой:**
   - Используйте GitHub Pages для статического фронтенда
   ```yaml
   # .github/workflows/deploy-frontend.yml
   name: Deploy Frontend
   on:
     push:
       branches: [main]
       paths: ['frontend/**']
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - run: npm ci && npm run build --prefix frontend
         - uses: peaceiris/actions-gh-pages@v3
           with:
             github_token: ${{ secrets.GITHUB_TOKEN }}
             publish_dir: frontend/dist
   ```

Для начала этого стека достаточно, чтобы получить полнофункциональный пет-проект с автоматизацией и минималистичным интерфейсом!