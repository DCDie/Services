# Services

Проект содержит микросервисы для управления слотами и календарем.

## Архитектура

Проект состоит из двух групп сервисов:

### 1. Базовые сервисы (docker-services.yaml)
- **nginx** - веб-сервер и reverse proxy (порт 80, 443) - конфигурация в `nginx.conf`
- **postgres** - база данных (порт 5432)
- **redis** - кэш и брокер сообщений (порт 6379)

### 2. Приложение (JWStand/docker-compose.yml)
- **web** - Django приложение с Daphne (внутренний порт 8000)
- **telegrambot** - Telegram бот
- **celeryworker** - Celery worker для фоновых задач
- **celerybeat** - Celery beat для периодических задач

## Быстрый старт

### Первый запуск

1. Убедитесь, что у вас установлены Docker и Docker Compose
2. Создайте файл `.env` в папке `JWStand/` на основе примера
3. Запустите все сервисы:
```bash
./restart-services.sh
```

### Управление сервисами

#### Перезапуск всех сервисов
```bash
./restart-services.sh
```

#### Проверка статуса
```bash
./status.sh
```

#### Просмотр логов
```bash
# Все логи приложения
./logs.sh

# Логи конкретного сервиса
./logs.sh web
./logs.sh telegrambot
./logs.sh celeryworker
```

#### Остановка всех сервисов
```bash
docker compose -f docker-services.yaml down
cd JWStand && docker compose down
```

### Ручное управление

#### Базовые сервисы
```bash
# Запуск
docker compose -f docker-services.yaml up -d

# Остановка
docker compose -f docker-services.yaml down

# Логи
docker compose -f docker-services.yaml logs -f nginx
```

#### Приложение
```bash
cd JWStand

# Запуск
docker compose up -d

# Перезапуск конкретного сервиса
docker compose restart web

# Пересборка и запуск
docker compose up -d --build

# Остановка
docker compose down

# Логи
docker compose logs -f web
```

## Исправление проблемы 502

Проблема 502 (Bad Gateway) возникала из-за того, что nginx пытался подключиться к Django приложению до того, как оно было готово к приему запросов.

### Что было исправлено:

1. **Добавлен healthcheck для сервиса web**
   - Проверяет доступность `/health/` endpoint каждые 10 секунд
   - Дает 40 секунд на запуск (миграции + collectstatic)

2. **Добавлен endpoint `/health/` в Django**
   - Простой endpoint, возвращающий HTTP 200
   - Используется для healthcheck

3. **Улучшена конфигурация nginx**
   - Добавлена обработка ошибок upstream
   - Настроен retry mechanism
   - Добавлен keepalive для соединений

4. **Добавлены зависимости между сервисами**
   - telegrambot, celeryworker и celerybeat ждут готовности web

5. **Добавлена политика перезапуска**
   - Все сервисы автоматически перезапускаются при падении

## Порядок запуска

Правильный порядок запуска сервисов:

1. **Базовые сервисы** (postgres, redis, nginx)
   - Запускаются первыми
   - nginx пока не может подключиться к web (это нормально)

2. **Web сервис**
   - Выполняет миграции БД
   - Собирает статические файлы
   - Запускает Daphne сервер
   - Проходит healthcheck

3. **Остальные сервисы приложения**
   - Запускаются после того, как web станет healthy

## Проверка работоспособности

### Проверка nginx
```bash
curl http://localhost/health
# Должно вернуть: healthy
```

### Проверка Django
```bash
curl http://localhost/health/
# Должно вернуть: OK
```

### Проверка статуса контейнеров
```bash
docker ps
# Все контейнеры должны быть в статусе "healthy" или "Up"
```

## Troubleshooting

### Nginx показывает 502
1. Проверьте, что сервис web запущен и healthy:
   ```bash
   cd JWStand && docker compose ps web
   ```

2. Проверьте логи web сервиса:
   ```bash
   ./logs.sh web
   ```

3. Подождите 30-40 секунд после запуска (миграции + healthcheck)

4. Если проблема не решается, перезапустите все сервисы:
   ```bash
   ./restart-services.sh
   ```

### Сервис web не становится healthy
1. Проверьте логи:
   ```bash
   ./logs.sh web
   ```

2. Проверьте подключение к БД:
   ```bash
   cd JWStand
   docker compose exec web python manage.py check --database default
   ```

3. Попробуйте пересобрать образ:
   ```bash
   cd JWStand
   docker compose up -d --build --force-recreate web
   ```

### База данных недоступна
1. Проверьте статус postgres:
   ```bash
   docker compose -f docker-services.yaml ps db
   ```

2. Проверьте логи:
   ```bash
   docker compose -f docker-services.yaml logs db
   ```

3. Проверьте сеть:
   ```bash
   docker network inspect services-network
   ```

## Разработка

### Применение миграций
```bash
cd JWStand
docker compose exec web python manage.py migrate
```

### Создание суперпользователя
```bash
cd JWStand
docker compose exec web python manage.py createsuperuser
```

### Сбор статических файлов
```bash
cd JWStand
docker compose exec web python manage.py collectstatic --noinput
```

### Запуск shell
```bash
cd JWStand
docker compose exec web python manage.py shell
```

## Мониторинг

### Просмотр логов в реальном времени
```bash
# Все сервисы приложения
./logs.sh

# Конкретный сервис
./logs.sh web
./logs.sh nginx
```

### Проверка использования ресурсов
```bash
docker stats
```

### Проверка сети
```bash
docker network inspect services-network
```

## Сеть

Все сервисы находятся в одной сети `services-network`, что позволяет им общаться друг с другом по именам сервисов:
- `web:8000` - Django приложение
- `db:5432` - PostgreSQL
- `redis:6379` - Redis

## Volumes

### Persistent volumes (сохраняются при удалении контейнеров):
- `services_postgres_data` - данные PostgreSQL
- `services_static_volume` - статические файлы Django
- `services_media_volume` - медиа файлы

