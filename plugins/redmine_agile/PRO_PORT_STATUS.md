# Состояние порта Redmine Agile PRO → Light (Redmine 6.1 / Rails 7.2)

Этот файл фиксирует, **что именно уже портировано** из PRO‑версии плагина `redmine_agile` в light‑версию под Redmine 6.1 / Rails 7.2, и **что ещё не перенесено**.

Используй его как чеклист, если будешь продолжать порт позже.

---

## 1. Спринты

### 1.1. Что сделано

- **Модель `AgileSprint`**
  - Перенесена из PRO (ассоциации, валидации, статусы, sharing и scopes).
- **Миграции для спринтов и связи с задачами**
  - `agile_sprints` и `agile_sprint_id` в `agile_data` (через старую миграцию PRO).
- **Контроллер `AgileSprintsController`**
  - Полный CRUD: `index/new/create/edit/update/destroy`.
  - Фильтрация и сортировка спринтов по проекту.
- **Вьюхи спринтов**
  - `app/views/agile_sprints/_form.html.erb`
  - `app/views/agile_sprints/new.html.erb`
  - `app/views/agile_sprints/edit.html.erb`
- **Хелпер `AgileSprintsHelper`**
  - Логика группировки спринтов (активные / будущие / прошлые), исправлена ошибка с дубликатами.
- **Интеграция со страницей проекта**
  - Вкладка "Спринты" в настройках проекта через `ProjectsHelperPatch`.
  - Частичный шаблон `projects/_project_agile_sprints.html.erb`.
- **Модель `AgileData`**
  - Ассоциация `belongs_to :agile_sprint`.
- **Патч `IssuePatch`**
  - `has_one :agile_data, dependent: :destroy`.
  - `has_one :agile_sprint, through: :agile_data`.
  - `accepts_nested_attributes_for :agile_data`.
  - Проксирование `story_points` и позиционирования.
- **Формы задачи**
  - `issues/_agile_data_fields.html.erb` — блок со спринтом и story points.
  - `issues/_issue_spint_form.html.erb` — выбор спринта в задаче.
  - `issues/_issue_sprint.html.erb` — отображение спринта на show‑странице.
- **Хуки**
  - `views_issues_hook.rb` — рендерит `agile_data_fields` и `agile_data_labels`.
- **Маршруты**
  - `resources :agile_sprints` внутри `projects`.
- **Переводы**
  - Добавлены/актуализированы ключи `label_agile_sprint_*`, `field_agile_sprint` и ошибки спринтов в `config/locales/ru.yml`.

### 1.2. Что ещё не портировано из PRO

- **Scrum‑режим Agile‑доски по спринту**
  - В PRO у `AgileQuery` есть опции:
    - `sprints_enabled`
    - `sprint_id`, `sprint`
    - `backlog_column`
    - `show_description`
    - `is_default`
  - Доска может быть привязана к конкретному спринту, с отдельной backlog‑колонкой.
  - В light сейчас доска — это по сути Kanban по проекту, без жёсткой привязки к одному спринту и без backlog‑колонки.
- **Отдельные доски / запросы спринтов**
  - `AgileSprintQuery`, `agile_sprint_boards`, отдельный список/фильтры спринтов, как сущности досок (в PRO).
- **Планировочная/Backlog‑доска**
  - Маршруты и действия:
    - `/agile/board/backlog_load_more`
    - `/agile/board/backlog_autocomplete`
  - UI, где слева backlog, справа спринты/колонки — не перенесён.
- **Глубокая интеграция с диаграммами по спринтам**
  - В PRO дефолтный спринт для диаграмм синхронизирован с выбранным спринтом доски.
  - В light сейчас диаграммы работают более независимо.

---

## 2. Раскраска задач (AgileColor)

### 2.1. Что сделано

- **Модель `AgileColor`**
  - `COLOR_GROUPS` (issue/priority/tracker/spent_time/user/project).
  - `AGILE_COLORS` (green, blue, turquoise, lightgreen, yellow, orange, red, purple, gray).
  - Методы:
    - `for_user(user_name)` → детерминированный `#RRGGBB` по логину.
    - `for_spent_time(est_time, spent_time)` → цвет по проценту выполнения.
- **`acts_as_colored`**
  - Перенесён модуль `RedmineAgile::Acts::Colored` (init + lib).
  - Добавляет `has_one :agile_color`, `color`, nested attributes и `agile_color_with_default`.
- **Патчи моделей**
  - `IssuePatch`:
    - `acts_as_colored`.
    - `safe_attributes 'agile_color_attributes'` (при наличии прав редактировать задачу + Agile в проекте).
    - `css_classes_with_agile` добавляет CSS‑класс `bk-<color>` при базе `issue`.
  - `TrackerPatch`, `IssuePriorityPatch`, `ProjectPatch`, `UserPatch`:
    - `acts_as_colored` и соответствующие `safe_attributes`.
- **Настройки плагина (`RedmineAgile`)**
  - `COLOR_BASE = ['issue', 'tracker', 'priority', 'spent_time', 'user', 'project']`.
  - `color_base` читается из `Setting.plugin_redmine_agile['color_on']`.
  - `use_colors?`, `color_prefix`, и методы:
    - `issue_colors?`, `tracker_colors?`, `priority_colors?`, `spent_time_colors?`, `user_colors?`, `project_colors?`.
- **Экран настроек плагина**
  - `settings/agile/_general.html.erb`:
    - поле **"Цвета на основании"** (select),
    - ссылка **"Настроить цвета"**, ведущая на `/agile_colors/tracker`.
- **AgileColorsController + UI**
  - `app/controllers/agile_colors_controller.rb`:
    - `index` — список объектов (трекеры/приоритеты),
    - `update` — сохранение выбранных цветов в `agile_color`.
  - `app/views/agile_colors/index.html.erb`:
    - выбор цветов для трекеров и приоритетов,
    - `jquery.simplecolorpicker` (JS+CSS из `assets`).
- **Формы цвета**
  - **Проект**:
    - `app/views/projects/_project_color_form.html.erb` — выбор цвета проекта.
    - Хук `ViewsProjectsFormHook` (`views_projects_form_hook.rb`) → `:view_projects_form`.
  - **Пользователь**:
    - `app/views/users/_user_color_form.html.erb` — выбор цвета пользователя.
    - Хук `ViewsUsersFormHook` (`views_users_form_hook.rb`) → `:view_users_form_preferences`.
  - **Задача**:
    - `app/views/issues/_issue_color_form.html.erb`.
    - Встраивается в `issues/_agile_data_fields.html.erb` рядом со спринтом и story points.
    - Поле "Цвет" всегда доступно при наличии прав на изменение задачи.
- **AgileBoardsHelper**
  - Полностью восстановлены:
    - `agile_color_class(issue, options={})` — выбор цвета по базе: issue/tracker/priority/spent_time/project.
    - `agile_user_color(user, options={})` — бордер по цвету пользователя.
- **Интеграция с запросами и доской**
  - `IssueQueryPatch`:
    - при `issues_with_agile_preload` подгружает `agile_color` для issue/tracker/priority/project в зависимости от `color_base`.
  - `AgileQuery`:
    - реализованы `color_base` и `color_base=`, сохраняются в `options` + дефолт берётся из `RedmineAgile.color_base`.
- **Работающие режимы раскраски**
  - **База: Задача** — индивидуальный цвет каждой задачи (`issue.color`).
  - **База: Трекер** — цвет по трекеру.
  - **База: Приоритет** — цвет по приоритету.
  - **База: Назначена** — цвет по исполнителю (из `user.color` или `AgileColor.for_user(login)`).
  - **База: Проект** — цвет по проекту.
  - **База: Потраченное время** — цвет считается автоматически из `estimated_hours`/`spent_hours`.

### 2.2. Чего ещё не хватает до полного паритета с PRO

- **Контекстное меню Agile для смены цвета задач**
  - В PRO есть `app/views/context_menus/_agile_colors.html.erb` и интеграция с context menu Redmine для массовой установки цвета задач.
  - В light это пока не перенесено.
- **Статус‑цвета колонок**
  - В PRO `RedmineAgile.status_colors?` и `header_th` в `AgileBoardsHelper` могут подсвечивать заголовки статусов.
  - В light `status_colors?` оставлен как `false`.
- **Массовые UI‑мелочи**
  - Возможные подсказки/легенды по цветам (если были в PRO), сейчас не анализировались и не переносились.

---

## 3. Agile‑доска и запросы (кроме спринтов и цветов)

### 3.1. Что затронуто / адаптировано

- `AgileQuery`:
  - Приведён к работе на Redmine 6.1 / Rails 7.2.
  - Сохранил фильтры, колонки, last_comment, day_in_state и пр.
  - Добавлены/адаптированы:
    - `color_base`, `color_base=` (см. выше),
    - `chart_unit`/`chart_unit=`.
- `AgileBoardsHelper`:
  - Адаптация header, подсчёта спринтовых значений, story points и т.д.
- Маршруты доски и диаграмм:
  - `/agile/board`, `/projects/:project_id/agile/board`.
  - `/agile/charts`, `/projects/:project_id/agile/charts`.

### 3.2. Что ещё не перенесено

- **Расширенный функционал AgileQuery из PRO** (кроме спринтовых полей):
  - swimlanes по разным сущностям (parent, assignee, sprint и др.),
  - дополнительные тоталы/агрегаты на доске,
  - backlog/kanban варианты досок (если отличаются от light).
- **Планировочная доска версий и спринтов**
  - `agile_version_queries`, `agile_versions` (если нужны).

---

## 4. Что важно помнить при дальнейшем порте

1. **Совместимость с Rails 7 / Zeitwerk**
   - Все новые классы/модули должны лежать в путях, понятных Zeitwerk (мы это уже учитывали, но при добавлении нового кода — продолжать в том же стиле).
   - Не использовать `unloadable` и старые приёмы autoloading.

2. **Патчи (monkey patching)**
   - Весь функционал добавляется через модули в `lib/redmine_agile/patches` и хуки/partial’ы, а не изменением ядра Redmine.

3. **Грани между light и PRO**
   - Light‑версия официально урезана по функционалу (особенно по бэклогам/версиям). При переносе функционала из PRO нужно понимать, что это уже "кастомный гибрид" и возможны расхождения с оф. обновлениями.

4. **Порядок, если продолжать порт**

   Рекомендуемая последовательность, если захочешь довести до почти полного PRO:

   1. **Scrum‑режим доски по спринту**
      - Перенести спринтовые поля и опции из PRO `AgileQuery` (sprints_enabled, sprint_id, sprint, backlog_column, show_description, is_default).
      - Подружить их с текущей light‑реализацией, не ломая существующие доски.
   2. **Backlog‑доска**
      - Маршруты и действия `backlog_load_more`, `backlog_autocomplete`.
      - UI бэклога + перетаскивание задач в спринт.
   3. **Контекстное меню смены цвета задач**
      - Перенести `_context_menus/agile_colors` и интеграцию.
   4. **Доп. диаграммы/Swimlanes** (если реально нужны).

---

## 5. Краткое резюме текущего состояния

- **Спринты**: CRUD, привязка задач, колонка/фильтр и отображение — **работают**.
- **AgileColor**: модель, патчи, все базы цветов, UI для трекеров/приоритетов/задач/пользователей/проектов — **работает**, раскраска доски восстановлена.
- **Доска**: базовый Kanban с учётом спринтов и цветов — **работает**.
- **Не хватает до полного PRO**:
  - Scrum‑режим доски по спринту + backlog‑функционал.
  - Контекстное меню для смены цвета задач.
  - Расширенные фичи AgileQuery/Swimlanes/версий (по необходимости).

Дальнейшую работу удобнее вести, отталкиваясь от этого файла: по мере порта новых частей PRO просто отмечай, что сделано, и дописывай подробности, если меняешь архитектуру.
