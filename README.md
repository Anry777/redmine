# Redmine (Docker)

## Старт

```bash
cd E:\Ruby\redmine
docker compose up -d
```

Первый запуск может занять несколько минут (скачивание образов, инициализация БД).

После старта:

1. Открой в браузере: http://127.0.0.1:3000/
2. Если появится предложение загрузить начальные данные (default data), выбери язык (например, `Russian`) и подтверди.
3. Залогинься под:
   - Логин: `admin`
   - Пароль: `admin` (после первого входа Redmine попросит сменить пароль)

## Структура

- `docker-compose.yml` — конфигурация сервисов `redmine` и `db` (Postgres).
- `themes/` — пользовательские темы (монтируются в Redmine).
- `plugins/` — плагины Redmine.
- `redmine_files/` — вложения и прочие файлы Redmine.
- `postgres_data/` — данные БД Postgres.

## Остановка

```bash
cd E:\Ruby\redmine
docker compose down
```

С параметром `-v` будут удалены и тома (в т.ч. БД):

```bash
docker compose down -v
```
