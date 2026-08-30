---
name: classify
description: Точка входа адаптивного рабочего процесса. Оценивает сложность, риск и радиус воздействия задачи и рекомендует минимально необходимую стратегию исполнения. Когда стратегия требует state, создаёт/обновляет задачу и персистит стратегию в её `Strategy` (per `rules/core/task-context.md`). Не уточняет требования, не планирует, не оценивает, не пишет код.
---

# Классификация

Оцените задачу только по её описанию (без изучения репозитория) и рекомендуйте минимально необходимую стратегию для её безопасного выполнения. Это точка входа — она определяет, какой объём процесса заслуживает задача, ничего больше.

## Правила

- Не читайте repository и не пытайтесь понять текущую архитектуру, реализацию или контекст кода.
- Не уточняйте требования, не создавайте план, не оценивайте усилия, не пишите код, не разрабатывайте тесты и не рецензируйте результаты — вместо этого рекомендуйте соответствующие workflow решения.
- Оценивайте только те аспекты, которые материально влияют на нужный объём workflow: сложность, неопределённость, риск, радиус воздействия, архитектурное воздействие, внешние зависимости, воздействие на данные, чувствительность безопасности, обратимость. Пропускайте любой аспект, который не важен для этой задачи.
- Используйте качественные уровни (Тривиально/Низко/Средне/Высоко), а не оценки или описание.
- Основывайте оценку только на описании задачи — не предполагайте деловые цели, которые не указаны.
- Рекомендуйте минимально обоснованный workflow, а не максимально доступный. Тривиальная задача должна рекомендовать `state_required: false` и `research_required: false`.
- Ссылайтесь только на существующие названия skills в рекомендуемой цепочке (`task`, `clarify`, `research`, `design`, `creative-explore`, `plan`, `estimate`, `verify`, `design-review`, `status`, `reconcile`, `review`, `debug`) — никогда не изобретайте новое. `implement` также может появиться в цепочке, но это не skill набора инструментов: он обозначает встроенное поведение Claude по написанию кода.
- Classify предсказывает потребности workflow, а не факты о repository. Рекомендуйте минимально необходимый процесс, а не весь implementation workflow целиком: `research_areas` — это концептуальные подсказки (какие темы неопределённы), никогда не конкретные файлы, классы или технологии — их находит сам `/research`. По той же причине не решайте, должен ли research быть parallel или sequential — это решение `/research` принимает сам, когда уже знает реальный repository.
- Рекомендуйте `design` только для задач, которые явно ориентированы на UI/интерфейс (новый экран, панель управления, форма или существенный редизайн макета) — пропускайте его для работ только на backend или небольшой стилистической правки существующего UI (цвет, отступы, текст, изменение размера одного элемента).
- Рекомендуйте `creative-explore`, размещённый между `design` и `plan`, только для значительного визуального проекта — новая основная страница, новая поверхность продукта или явный запрос на что-то отличительное/премиум. Пропускайте для обычной работы с UI; собственный шаг Art Direction в `design` достаточен.
- Рекомендуйте `design-review` после реализации UI-задачи, которая прошла через `design` — размещённый перед `verify`/`review` в цепочке. Пропускайте для работ только на backend или небольшой правки, которая пропустила `design`.
- Рекомендуйте `task` только когда запрос не имеет естественного входа через `clarify`/`plan` (например, возобновление с голого id или внешней заметки). Рекомендуйте `reconcile` только при возобновлении задачи без контекста беседы, который произвел её текущее состояние, или когда есть конкретная причина подозревать дрейф — не как рутинный шаг в каждой цепочке.
- Упоминайте потенциальные возможности (MCP, файловая система, база данных, облако, браузер, внешние API) только если задача правдоподобно их нуждается. Никогда не предполагайте доступ к ним.
- Держите результат кратким — это решение о маршрутизации, а не анализ.

## Persistence

Classify doesn't own a workflow `phase` (`rules/core/execution-state.md`) — it runs before `clarify` and never advances `phase` past `new`.

- **`state_required: false`** (trivial task): do not create a task file. Report the classification only (`rules/core/execution-state.md`'s Principles: "Create `.ai/` lazily — no task file for trivial work").
- **`state_required: true`**: persist the strategy to the task's `Strategy` section (`rules/core/task-context.md`).
  - No task file yet: create it using TaskCreate tool:
    1. List existing task files with bash to find highest `TASK-NNN` id
    2. Allocate next id (same allocation rule `/plan`/`/clarify`/`/task` use)
    3. Create file at `.ai/tasks/TASK-NNN.md` with proper frontmatter
    4. Set `phase: new`, `status: READY`, `created_at: <today>`, `updated_at: <today>`
    5. Write `Strategy` section with YAML block from Output and the resulting workflow chain
    6. Append `TASK_CREATED` event to Execution History
  - Task file already exists (re-classifying, or a task started via `/task`): reconcile first — re-read fresh off disk, note any human edits (`rules/core/task-context.md` Reconciliation) — then update `Strategy` in place rather than duplicating it.
  - Write only the `Strategy` section (the YAML block from Output below, plus the resulting chain). Never touch Acceptance Criteria, Technical Plan, Slices, or any section another skill owns.
  - Follow `rules/core/common-rules.md`'s Persist-before-report: write, re-read to confirm, only then report.

### Frontmatter template for new task files:

```yaml
---
task_id: TASK-NNN
title: <short title from task description>
status: READY
phase: new
created_at: <YYYY-MM-DD>
updated_at: <YYYY-MM-DD>
---

# Task

## Objective

## Strategy
<YAML block from Output section, plus the resulting chain>

## Acceptance Criteria

## Execution History

- **TASK_CREATED** — Classify created this task with initial strategy assessment
```

## Implementation steps

When `state_required: true`:

1. **Check if task exists**: List files in `.ai/tasks/` to see if a task file for this request already exists
2. **Allocate task ID**: If creating new file, find highest existing TASK-NNN number and allocate TASK-(N+1)
3. **Build task content**: Construct the full task file with frontmatter, Strategy section, and Execution History
4. **Write to disk**: Use Write tool to create `.ai/tasks/TASK-NNN.md`
5. **Verify creation**: Re-read the file from disk to confirm it was written correctly
6. **Report with Task header**: Begin output with `Task: TASK-NNN — <title>`

When `state_required: false`:

- Skip task file creation entirely
- Report only the classification (no Task header)

## Вывод

Начните с Task header (`rules/core/common-rules.md`): `Task: TASK-NNN — <title>` — только если создан или уже существовал task file; для тривиальных задач без файла — без этого заголовка.

Структурируйте ответ в четыре части:

### 1. Task Profile
По одной строке на каждый материальный аспект: `<Аспект>: <Тривиально/Низко/Средне/Высоко>`, с кратким обоснованием только если оно неочевидно. Пропускайте аспекты, которые не применяются. Не персистится в файл — это обоснование для чата, не state.

Примеры аспектов:
- Complexity
- Uncertainty
- Risk
- Blast radius
- Architectural impact
- Data/state impact
- Security sensitivity
- Reversibility
- External dependencies

### 2. Recommended Strategy

Выведите YAML структуру со следующими полями — это то, что персистится в `Strategy`, когда `state_required: true`:

```yaml
strategy:
  state_required: bool          # нужен ли task file
  research_required: bool       # нужно ли изучение кода/архитектуры
  research_areas: []            # какие области/компоненты/системы изучать (если research требуется)
  clarification_required: bool  # нужны ли clarify вопросы перед планированием
  planning_required: bool       # нужен ли структурированный план
  verification_level: "standard" | "elevated"
                                # "standard" для обычных задач
                                # "elevated" если высокий риск или сложность
```

**Примеры:**

Simple task:
```yaml
strategy:
  state_required: false
  research_required: false
  clarification_required: false
  planning_required: false
  verification_level: standard
```

Medium task:
```yaml
strategy:
  state_required: true
  research_required: true
  research_areas:
    - relevant architecture patterns
    - existing implementation in area X
  clarification_required: true
  planning_required: true
  verification_level: standard
```

Complex task:
```yaml
strategy:
  state_required: true
  research_required: true
  research_areas:
    - component A integration points
    - component B dependency graph
    - data migration strategy
  clarification_required: true
  planning_required: true
  verification_level: elevated
```

### 3. Recommended Workflow Chain

Одна цепочка, слева направо в порядке выполнения, используя только название skills: `task`, `clarify`, `research`, `design`, `creative-explore`, `plan`, `estimate`, `verify`, `design-review`, `status`, `reconcile`, `review`, `debug`, а также встроенное `implement` для написания кода. Персистится вместе с YAML в `Strategy` (одна строка).

Примеры цепочек:
- `implement → verify` (simple tasks, no research/planning needed)
- `research → clarify → plan → implement → verify` (medium tasks, research_required: true)
- `research → clarify → plan → implement → design-review → verify → review` (UI/complex tasks, research_required: true)

Обратите внимание: `/execute` (или `/execute TASK-NNN`) автоматически запустит эту цепочку фаза за фазой, останавливаясь при human gates или блокерах — упомяните его как опцию автоматического запуска, а не как член цепочки.

### 4. Potential Capabilities (опционально)

Только если задача правдоподобно нуждается в чём-то выходящем за пределы локальной файловой системы (браузер, база данных, облако API и т.д.) — сверьтесь с `rules/core/capabilities.md`. В противном случае пропускайте.
