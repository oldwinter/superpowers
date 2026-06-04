# Defense-in-Depth Validation

## 概览

当你修复由 invalid data 导致的 bug 时，在一个地方添加 validation 会感觉足够。但那个单一 check 可能被不同 code paths、refactoring 或 mocks 绕过。

**核心原则：** 在 data 经过的每一层都 validate。让 bug 在结构上不可能发生。

## 为什么需要多层

Single validation: "We fixed the bug"
Multiple layers: "We made the bug impossible"

不同 layers 捕获不同 cases：
- Entry validation 捕获大多数 bugs
- Business logic 捕获 edge cases
- Environment guards 防止 context-specific dangers
- Debug logging 在其他 layers 失败时提供帮助

## 四层

### Layer 1: Entry Point Validation
**Purpose:** 在 API boundary 拒绝明显 invalid input

```typescript
function createProject(name: string, workingDirectory: string) {
  if (!workingDirectory || workingDirectory.trim() === '') {
    throw new Error('workingDirectory cannot be empty');
  }
  if (!existsSync(workingDirectory)) {
    throw new Error(`workingDirectory does not exist: ${workingDirectory}`);
  }
  if (!statSync(workingDirectory).isDirectory()) {
    throw new Error(`workingDirectory is not a directory: ${workingDirectory}`);
  }
  // ... proceed
}
```

### Layer 2: Business Logic Validation
**Purpose:** 确保 data 对当前 operation 来说合理

```typescript
function initializeWorkspace(projectDir: string, sessionId: string) {
  if (!projectDir) {
    throw new Error('projectDir required for workspace initialization');
  }
  // ... proceed
}
```

### Layer 3: Environment Guards
**Purpose:** 在特定 contexts 中防止 dangerous operations

```typescript
async function gitInit(directory: string) {
  // In tests, refuse git init outside temp directories
  if (process.env.NODE_ENV === 'test') {
    const normalized = normalize(resolve(directory));
    const tmpDir = normalize(resolve(tmpdir()));

    if (!normalized.startsWith(tmpDir)) {
      throw new Error(
        `Refusing git init outside temp dir during tests: ${directory}`
      );
    }
  }
  // ... proceed
}
```

### Layer 4: Debug Instrumentation
**Purpose:** 捕获 context，用于 forensics

```typescript
async function gitInit(directory: string) {
  const stack = new Error().stack;
  logger.debug('About to git init', {
    directory,
    cwd: process.cwd(),
    stack,
  });
  // ... proceed
}
```

## Applying the Pattern

当你找到 bug：

1. **Trace the data flow** - Bad value 从哪里来？在哪里使用？
2. **Map all checkpoints** - 列出 data 经过的每个点
3. **Add validation at each layer** - Entry、business、environment、debug
4. **Test each layer** - 尝试绕过 layer 1，验证 layer 2 会捕获

## Example from Session

Bug: Empty `projectDir` 导致 `git init` 在 source code 中运行

**Data flow:**
1. Test setup → empty string
2. `Project.create(name, '')`
3. `WorkspaceManager.createWorkspace('')`
4. `git init` 在 `process.cwd()` 中运行

**Four layers added:**
- Layer 1: `Project.create()` validates not empty/exists/writable
- Layer 2: `WorkspaceManager` validates projectDir not empty
- Layer 3: `WorktreeManager` refuses git init outside tmpdir in tests
- Layer 4: Stack trace logging before git init

**Result:** All 1847 tests passed，bug impossible to reproduce

## Key Insight

四层都必要。测试期间，每一层都捕获了其他层漏掉的 bugs：
- 不同 code paths 绕过了 entry validation
- Mocks 绕过了 business logic checks
- 不同 platforms 上的 edge cases 需要 environment guards
- Debug logging 识别了 structural misuse

**不要停在一个 validation point。** 在每一层添加 checks。
