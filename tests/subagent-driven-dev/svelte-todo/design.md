# Svelte Todo List - Design

## 概览

一个用 Svelte 构建的 simple todo list application。支持创建、完成和删除 todos，并使用 localStorage persistence。

## Features

- Add new todos
- Mark todos as complete/incomplete
- Delete todos
- Filter by: All / Active / Completed
- Clear all completed todos
- Persist to localStorage
- Show count of remaining items

## User Interface

```
┌─────────────────────────────────────────┐
│  Svelte Todos                           │
├─────────────────────────────────────────┤
│  [________________________] [Add]       │
├─────────────────────────────────────────┤
│  [ ] Buy groceries                  [x] │
│  [✓] Walk the dog                   [x] │
│  [ ] Write code                     [x] │
├─────────────────────────────────────────┤
│  2 items left                           │
│  [All] [Active] [Completed]  [Clear ✓]  │
└─────────────────────────────────────────┘
```

## Components

```
src/
  App.svelte           # Main app, state management
  lib/
    TodoInput.svelte   # Text input + Add button
    TodoList.svelte    # List container
    TodoItem.svelte    # Single todo with checkbox, text, delete
    FilterBar.svelte   # Filter buttons + clear completed
    store.ts           # Svelte store for todos
    storage.ts         # localStorage persistence
```

## Data Model

```typescript
interface Todo {
  id: string;        // UUID
  text: string;      // Todo text
  completed: boolean;
}

type Filter = 'all' | 'active' | 'completed';
```

## Acceptance Criteria

1. 可以通过 typing and pressing Enter 或 clicking Add 添加 todo
2. 可以点击 checkbox toggle todo completion
3. 可以点击 X button delete todo
4. Filter buttons 显示正确 subset of todos
5. "X items left" 显示 incomplete todos count
6. "Clear completed" 移除所有 completed todos
7. Todos 在 page refresh 后持久化（localStorage）
8. Empty state 显示 helpful message
9. All tests pass
