# Svelte Todo List - Implementation Plan

使用 `superpowers:subagent-driven-development` skill 执行这个 plan。

## Context

构建一个 Svelte todo list app。完整 specification 见 `design.md`。

## Tasks

### Task 1: Project Setup

用 Vite 创建 Svelte project。

**Do:**
- Run `npm create vite@latest . -- --template svelte-ts`
- Install dependencies with `npm install`
- Verify dev server works
- 从 App.svelte 清理 default Vite template content

**Verify:**
- `npm run dev` starts server
- App shows minimal "Svelte Todos" heading
- `npm run build` succeeds

---

### Task 2: Todo Store

创建用于 todo state management 的 Svelte store。

**Do:**
- 创建 `src/lib/store.ts`
- 定义 `Todo` interface with id, text, completed
- 创建 initial empty array 的 writable store
- Export functions: `addTodo(text)`, `toggleTodo(id)`, `deleteTodo(id)`, `clearCompleted()`
- 创建 `src/lib/store.test.ts`，为每个 function 添加 tests

**Verify:**
- Tests pass: `npm run test`（如需要，install vitest）

---

### Task 3: localStorage Persistence

为 todos 添加 persistence layer。

**Do:**
- 创建 `src/lib/storage.ts`
- 实现 `loadTodos(): Todo[]` 和 `saveTodos(todos: Todo[])`
- Gracefully handle JSON parse errors（return empty array）
- 与 store 集成：init 时 load，change 时 save
- 添加 load/save/error handling tests

**Verify:**
- Tests pass
- Manual test: add todo, refresh page, todo persists

---

### Task 4: TodoInput Component

创建添加 todos 的 input component。

**Do:**
- 创建 `src/lib/TodoInput.svelte`
- Text input bound to local state
- Add button calls `addTodo()` and clears input
- Enter key also submits
- Disable Add button when input is empty
- Add component tests

**Verify:**
- Tests pass
- Component renders input and button

---

### Task 5: TodoItem Component

创建 single todo item component。

**Do:**
- 创建 `src/lib/TodoItem.svelte`
- Props: `todo: Todo`
- Checkbox toggles completion（calls `toggleTodo`）
- Text with strikethrough when completed
- Delete button（X）calls `deleteTodo`
- Add component tests

**Verify:**
- Tests pass
- Component renders checkbox, text, delete button

---

### Task 6: TodoList Component

创建 list container component。

**Do:**
- 创建 `src/lib/TodoList.svelte`
- Props: `todos: Todo[]`
- Renders TodoItem for each todo
- Shows "No todos yet" when empty
- Add component tests

**Verify:**
- Tests pass
- Component renders list of TodoItems

---

### Task 7: FilterBar Component

创建 filter and status bar component。

**Do:**
- 创建 `src/lib/FilterBar.svelte`
- Props: `todos: Todo[]`, `filter: Filter`, `onFilterChange: (f: Filter) => void`
- Show count: "X items left"（incomplete count）
- Three filter buttons: All, Active, Completed
- Active filter is visually highlighted
- "Clear completed" button（hidden when no completed todos）
- Add component tests

**Verify:**
- Tests pass
- Component renders count, filters, clear button

---

### Task 8: App Integration

在 App.svelte 中接好所有 components。

**Do:**
- Import all components and store
- Add filter state（default: 'all'）
- Compute filtered todos based on filter state
- Render: heading, TodoInput, TodoList, FilterBar
- Pass appropriate props to each component

**Verify:**
- App renders all components
- Adding todos works
- Toggling works
- Deleting works

---

### Task 9: Filter Functionality

确保 filtering end-to-end 工作。

**Do:**
- Verify filter buttons change displayed todos
- 'all' shows all todos
- 'active' shows only incomplete todos
- 'completed' shows only completed todos
- Clear completed removes completed todos and resets filter if needed
- Add integration tests

**Verify:**
- Filter tests pass
- Manual verification of all filter states

---

### Task 10: Styling and Polish

添加 CSS styling，提升 usability。

**Do:**
- Style app to match design mockup
- Completed todos have strikethrough and muted color
- Active filter button is highlighted
- Input has focus styles
- Delete button appears on hover（or always on mobile）
- Responsive layout

**Verify:**
- App is visually usable
- Styles don't break functionality

---

### Task 11: End-to-End Tests

添加 full user flows 的 Playwright tests。

**Do:**
- Install Playwright: `npm init playwright@latest`
- 创建 `tests/todo.spec.ts`
- Test flows:
  - Add a todo
  - Complete a todo
  - Delete a todo
  - Filter todos
  - Clear completed
  - Persistence（add, reload, verify）

**Verify:**
- `npx playwright test` passes

---

### Task 12: README

记录 project。

**Do:**
- 创建 `README.md`，包含：
  - Project description
  - Setup: `npm install`
  - Development: `npm run dev`
  - Testing: `npm test` and `npx playwright test`
  - Build: `npm run build`

**Verify:**
- README accurately describes the project
- Instructions work
