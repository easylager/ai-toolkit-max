---
name: decompose
description: Разбить проект, прошедший DECOMPOSE readiness gate, на capability/vertical-slice граф (`Task Graph` в `.ai/project.md`, per `rules/core/project-state.md`) — поведенческие узлы, не технические задачи. Технический разбор происходит позже, внутри задачи каждого узла, через обычный task workflow. Запускается пользователем явно; `/project` никогда его не вызывает.
---

# Decompose

Единственная работа: превратить проект, готовый к декомпозиции, в граф capability/vertical-slice узлов. Не PRD, не техническая архитектура, не список файлов — поведение, которое можно отдать в task workflow по одному узлу за раз.

```
readiness gate → capability/vertical-slice граф → узел → /classify → обычный task workflow
```

## Правила

- Реконсиляция (`rules/core/common-rules.md`): перечитать `.ai/project.md` с диска перед решением.
- **Сам проверяет DECOMPOSE readiness gate** (`rules/core/project-state.md`) — не доверяет тому, что предыдущий `/project` уже это сделал. Gate не пройден (`Goal`/`Flow` неполные, значимые решения не `ACCEPTED`, `Verification` пуста, scope неясен) — показать те же конкретные gaps, что показал бы `/project`, ничего не писать и не декомпозировать через силу.
- Узлы — **поведение или capability, никогда файлы, слои или технические задачи** (`rules/core/project-state.md`'s Task graph): «Пользователь может найти доставку по tracking number», не «создать endpoint /track». Технический разбор — дело `/plan` внутри задачи узла, не этого skill'а.
- Расставить `depends` между узлами и статус (`READY`/`BLOCKED`) по факту зависимости — не гадать про приоритет, только про порядок.
- **Не создаёт `TASK-NNN.md`.** Task-файл появляется позже обычным способом (`/classify`, или `/task` для голого узла), когда работа над узлом реально начинается — это уже `EXECUTE`-стадия `/project`, не эта команда.
- Пишет только `Task Graph` в `.ai/project.md` и переводит `stage` в `DECOMPOSE`. Больше ничего в файле не трогает — `Goal`/`Flow`/`Decisions`/`Verification` уже установлены раньше, здесь не переписываются.
- Persist-before-report (`rules/core/common-rules.md`): записать граф, перечитать, только потом показать.
- Не запускает `/classify`, `/execute` или что-либо ещё сам — граф написан, дальше решает пользователь (обычно через следующий `/project`).
- Один вызов — один граф. Перезапуск `/decompose` на проекте, где граф уже есть, пересматривает его по текущему состоянию `.ai/project.md`, а не добавляет узлы поверх бездумно.

## Вывод (на русском)

Gate не пройден:

```
DECOMPOSE

Readiness gate не пройден.

Что ещё не определено?
⚠️ External API timeout behaviour
⚠️ Verification strategy

Дальше:
Разрешить эти вопросы (`/decide`, `/project`), затем повторить `/decompose`.
```

Gate пройден — граф записан:

```
DECOMPOSE

DELIVERY TRACKER

├── SEARCH-01  Пользователь может найти доставку по tracking number       READY
├── ERROR-01   Приложение показывает понятную ошибку при сбое поиска      BLOCKED (depends: SEARCH-01)
│   ├── invalid input
│   ├── not found
│   └── external API failure/timeout
└── VERIFY-01  Основной happy path и сбои внешнего API покрыты тестами    BLOCKED (depends: SEARCH-01, ERROR-01)

Граф: 3 узла · 1 READY · 2 BLOCKED

Дальше:
`/project` — увидеть панель и следующий узел.
```
