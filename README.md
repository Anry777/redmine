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

## Деплой на VPS (Ansible)

Для автоматического развёртывания Redmine на чистом Debian 12 используется плейбук `deploy-redmine.yml`.

### 1. Подготовка inventory

Создай файл `inventory.ini` рядом с плейбуком:

```ini
[redmine]
redmine-vps ansible_host=IP_ИЛИ_HOSTNAME_VPS ansible_user=root
```

Если логинишься не под `root`, укажи нужного пользователя в `ansible_user`, но оставь `become: true` в плейбуке.

### 2. Настройка переменных плейбука

В `deploy-redmine.yml` нужно указать:

- `reverse_proxy_ip` — IP сервера с nginx (reverse-proxy), который будет ходить к Redmine по HTTP.
- `redmine_repo_url` — SSH-URL приватного репозитория Redmine (формата `git@github.com:ORG/REPO.git` или `git@gitlab.com:ORG/REPO.git`).
- `redmine_repo_version` — ветка или тег (например, `main`).

### 3. Установка коллекции Ansible и запуск плейбука

На своей рабочей машине (где установлен Ansible):

```bash
ansible-galaxy collection install community.general
ansible-playbook -i inventory.ini deploy-redmine.yml
```

Плейбук:

- ставит Docker + docker compose plugin;
- создаёт пользователя `deploy` и директорию `~/apps/redmine`;
- клонирует приватный репозиторий под пользователем `deploy`;
- настраивает ufw (SSH + доступ к порту 3000 только с reverse-proxy);
- выполняет `docker compose pull` и `docker compose up -d`.

После успешного выполнения Redmine будет доступен по адресу, настроенному на nginx (например, `https://redmine.teamgram.ru`).

## Настройка SSH-ключа для доступа к приватному репозиторию

Для того чтобы плейбук мог клонировать приватный репозиторий от имени пользователя `deploy`, нужно создать деплой-ключ и добавить его в Git-хостинг.

### 1. Генерация ключа на VPS

Подключись к VPS и выполни от имени `deploy`:

```bash
ssh deploy@IP_ИЛИ_HOSTNAME_VPS
ssh-keygen -t ed25519 -C "deploy@redmine-vps"
```

На вопрос «Enter file in which to save the key» просто нажми Enter (ключ будет сохранён в `~/.ssh/id_ed25519`). Passphrase можно оставить пустым.

Покажи публичный ключ:

```bash
cat ~/.ssh/id_ed25519.pub
```

Скопируй полученную строку целиком.

### 2. Добавление ключа в Git-репозиторий

В зависимости от хостинга:

- **GitHub**: репозиторий → `Settings` → `Deploy keys` → `Add deploy key` → вставить `id_ed25519.pub`. Галочку `Allow write access` обычно можно не ставить (нужен только read-only доступ).
- **GitLab**: репозиторий → `Settings` → `Repository` → раздел **Deploy Keys** → `New deploy key` → вставить `id_ed25519.pub`.

### 3. Проверка SSH-доступа

На VPS под пользователем `deploy`:

```bash
# для GitHub
ssh -T git@github.com

# для GitLab
ssh -T git@gitlab.com
```

При первом запуске нужно подтвердить fingerprint (`yes`). В ответ должно прийти сообщение об успешной аутентификации.

После этого плейбук `deploy-redmine.yml` сможет без пароля клонировать приватный репозиторий и обновлять код.
