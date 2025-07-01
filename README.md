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

