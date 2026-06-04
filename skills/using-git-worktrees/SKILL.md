---
name: using-git-worktrees
description: 开始需要与当前 workspace 隔离的 feature work，或执行 implementation plans 前使用 - 通过 native tools 或 git worktree fallback 确保存在 isolated workspace
---

# Using Git Worktrees

## 概览

确保工作发生在 isolated workspace 中。优先使用平台原生 worktree tools。只有在没有 native tool 可用时，才 fallback 到手动 git worktrees。

**核心原则：** 先检测已有隔离。再使用 native tools。再 fallback 到 git。永远不要和 harness 对抗。

**开始时宣布：** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: 检测已有隔离

**创建任何东西之前，先检查你是否已经在 isolated workspace 中。**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** 在 git submodules 中，`GIT_DIR != GIT_COMMON` 也为 true。在得出“已经在 worktree 中”的结论前，确认你不是在 submodule 中：

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**如果 `GIT_DIR != GIT_COMMON`（且不是 submodule）：** 你已经在 linked worktree 中。跳到 Step 3（Project Setup）。不要再创建另一个 worktree。

报告 branch 状态：
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**如果 `GIT_DIR == GIT_COMMON`（或在 submodule 中）：** 你处于普通 repo checkout。

用户是否已经在指令中说明 worktree preference？如果没有，在创建 worktree 前请求同意：

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

如果已有明确偏好，直接遵循，不再询问。如果用户拒绝，同步在当前目录工作并跳到 Step 3。

## Step 1: 创建 Isolated Workspace

**你有两种机制。按顺序尝试。**

### 1a. Native Worktree Tools（优先）

用户已经要求 isolated workspace（Step 0 consent）。你是否已经有创建 worktree 的方式？它可能叫 `EnterWorktree`、`WorktreeCreate`、`/worktree` command，或某个 `--worktree` flag。如果有，使用它，然后跳到 Step 3。

Native tools 会自动处理目录位置、branch 创建和 cleanup。当你拥有 native tool 时使用 `git worktree add`，会创建 harness 看不见、也无法管理的 phantom state。

只有在没有 native worktree tool 可用时，才进入 Step 1b。

### 1b. Git Worktree Fallback

**只有 Step 1a 不适用时才使用**：你没有 native worktree tool。用 git 手动创建 worktree。

#### Directory Selection

按以下优先级。用户明确偏好永远优先于观察到的 filesystem state。

1. **检查你的 instructions 中是否声明 worktree directory preference。** 如果用户已经指定，直接使用，不再询问。

2. **检查是否存在 project-local worktree directory：**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   如果找到就使用。如果两者都存在，`.worktrees` 优先。

3. **检查是否存在 global directory：**
   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
   ```
   如果找到就使用它（backward compatibility with legacy global path）。

4. **如果没有其他可用指导**，默认使用 project root 下的 `.worktrees/`。

#### Safety Verification（仅 project-local directories）

**创建 worktree 前必须验证目录已被 ignored：**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**如果没有 ignored：** 添加到 .gitignore，commit 该变更，然后继续。

**为什么关键：** 防止意外把 worktree contents commit 到 repository。

Global directories（`~/.config/superpowers/worktrees/`）不需要验证。

#### Create the Worktree

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

# Determine path based on chosen location
# For project-local: path="$LOCATION/$BRANCH_NAME"
# For global: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** 如果 `git worktree add` 因 permission error（sandbox denial）失败，告诉用户 sandbox 阻止了 worktree 创建，你将在当前目录工作。然后在原地运行 setup 和 baseline tests。

## Step 3: Project Setup

自动检测并运行适当 setup：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 4: 验证 Clean Baseline

运行 tests，确保 workspace 起点干净：

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**如果 tests fail：** 报告 failures，询问是继续还是调查。

**如果 tests pass：** 报告 ready。

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | 跳过创建（Step 0） |
| In a submodule | 当作 normal repo 处理（Step 0 guard） |
| Native worktree tool available | 使用它（Step 1a） |
| No native tool | Git worktree fallback（Step 1b） |
| `.worktrees/` exists | 使用它（verify ignored） |
| `worktrees/` exists | 使用它（verify ignored） |
| Both exist | 使用 `.worktrees/` |
| Neither exists | 检查 instruction file，然后默认 `.worktrees/` |
| Global path exists | 使用它（backward compat） |
| Directory not ignored | 添加到 .gitignore + commit |
| Permission error on create | Sandbox fallback，在原地工作 |
| Tests fail during baseline | 报告 failures + 询问 |
| No package.json/Cargo.toml | 跳过 dependency install |

## 常见错误

### Fighting the harness

- **Problem:** 平台已经提供隔离时仍使用 `git worktree add`
- **Fix:** Step 0 检测已有隔离。Step 1a 让 native tools 接管。

### Skipping detection

- **Problem:** 在已有 worktree 内创建 nested worktree
- **Fix:** 创建任何东西前始终运行 Step 0

### Skipping ignore verification

- **Problem:** Worktree contents 被 tracked，污染 git status
- **Fix:** 创建 project-local worktree 前始终使用 `git check-ignore`

### Assuming directory location

- **Problem:** 造成不一致，违反项目约定
- **Fix:** 遵循优先级：existing > global legacy > instruction file > default

### Proceeding with failing tests

- **Problem:** 无法区分新 bug 和既有问题
- **Fix:** 报告 failures，取得明确许可后再继续

## Red Flags

**Never:**
- Step 0 检测到已有隔离时仍创建 worktree
- 拥有 native worktree tool（例如 `EnterWorktree`）时使用 `git worktree add`。这是头号错误：如果有，就用它。
- 跳过 Step 1a，直接进入 Step 1b 的 git commands
- 创建 worktree 而不验证它被 ignored（project-local）
- 跳过 baseline test verification
- 未询问就带着 failing tests 继续

**Always:**
- 先运行 Step 0 detection
- 优先使用 native tools，而不是 git fallback
- 遵循目录优先级：existing > global legacy > instruction file > default
- 对 project-local 验证目录被 ignored
- 自动检测并运行 project setup
- 验证 clean test baseline
