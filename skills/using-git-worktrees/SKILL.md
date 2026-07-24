---
name: using-git-worktrees
description: 在启动需要与当前工作区隔离的功能工作时或在执行实施计划之前使用 - 通过本机工具或 git worktree 后备确保存在隔离的工作区
---

# Using Git Worktrees

## Overview

确保工作在隔离的工作空间中进行。更喜欢您平台的本机工作树工具。仅当没有可用的本机工具时才回退到手动 git 工作树。

**核心原则：** 首先检测现有的隔离。然后使用原生工具。然后回到 git。切勿与安全带对抗。

**开始时宣布：**"我正在使用 using-git-worktrees 技能来设置一个隔离的工作区。"

## Step 0: Detect Existing Isolation

**在创建任何内容之前，请检查您是否已处于隔离工作区中。**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**子模块保护：** `GIT_DIR != GIT_COMMON` 在 git 子模块中也是如此。在得出"已在工作树中"的结论之前，请验证您不在子模块中：

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**如果`GIT_DIR != GIT_COMMON`（而不是子模块）：**您已经位于链接的工作树中。跳至步骤 2（项目设置）。不要创建另一个工作树。

报告分支状态：
- 在分支上："已位于分支 `<name>` 上 `<path>` 的隔离工作区中。"
- 分离的 HEAD："已位于 `<path>` 的隔离工作区中（分离的 HEAD，外部管理）。完成时需要创建分支。"

**如果`GIT_DIR == GIT_COMMON`（或在子模块中）：**您处于正常的回购结账状态。

用户是否已在您的说明中表明了他们的工作树偏好？如果没有，请在创建工作树之前征求同意：

> "您希望我建立一个独立的工作树吗？它可以保护您当前的分支免受更改。"

尊重任何现有的已声明的偏好，无需询问。如果用户拒绝同意，请就地工作并跳至步骤 2。

## Step 1: Create Isolated Workspace

**你有两种机制。按此顺序尝试。**

### 1a.本机工作树工具（首选）

用户已请求隔离工作区（第 0 步同意）。您已经有办法创建工作树了吗？它可能是一个名称类似于 `EnterWorktree`、`WorktreeCreate`、`/worktree` 命令或 `--worktree` 标志的工具。如果这样做，请使用它并跳到步骤 2。

本机工具自动处理目录放置、分支创建和清理。当您拥有本机工具时使用 `git worktree add` 会创建您的线束无法看到或管理的幻象状态。

仅当您没有可用的本机工作树工具时才继续执行步骤 1b。

### 1b. Git Worktree Fallback

**仅当步骤 1a 不适用时才使用此** - 您没有可用的本机工作树工具。使用 git 手动创建工作树。

#### Directory Selection

请遵循此优先顺序。显式的用户首选项总是优于观察到的文件系统状态。

1. **检查您的说明以了解声明的工作树目录首选项。**如果用户已经指定了一个，则无需询问即可使用它。

2. **检查现有的项目本地工作树目录：**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   如果找到，请使用它。如果两者都存在，则 `.worktrees` 获胜。

3. **如果没有其他可用的指导**，默认为项目根目录下的 `.worktrees/`（default to `.worktrees/` at the project root）。

#### 安全验证（仅限项目本地目录）

**在创建工作树之前必须验证目录是否被忽略：**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**如果不忽略：** 添加到 .gitignore，提交更改，然后继续。

**为什么重要：** 防止意外地将工作树内容提交到存储库。

#### Create the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**沙箱后备：** 如果 `git worktree add` 因权限错误（沙箱拒绝）而失败，请告诉用户沙箱阻止了工作树创建，并且您正在当前目录中工作。然后就地运行设置和基线测试。

## Step 2: Project Setup

自动检测并运行适当的设置：

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

## Step 3: Verify Clean Baseline

运行测试以确保工作区开始干净：

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**如果测试失败：** 报告失败，询问是否继续或调查。

**如果测试通过：** 报告准备就绪。

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

|情况|行动|
|-----------|--------|
|已经在链接的工作树中 |跳过创建（步骤 0）|
|在子模块中 |视为正常回购（步骤 0 防护）|
|本机工作树工具可用 |使用它（步骤 1a）|
|没有原生工具 | Git 工作树后备（步骤 1b） |
| `.worktrees/` 存在 |使用它（验证忽略）|
| `worktrees/` 存在 |使用它（验证忽略） |
|两者都存在|使用 `.worktrees/` |
|两者都不存在 |查看指令文件，默认`.worktrees/` |
|目录不被忽略 |添加到 .gitignore + 提交 |
|创建时权限错误 |沙箱后备，就地工作 |
|测试在基线期间失败 |报告失败+询问|
|没有 package.json/Cargo.toml |跳过依赖安装 |

## 常见合理化借口

| 借口 | 事实 |
|------|------|
| “我显然不在 worktree 中，不必检查” | 运行 Step 0。Harness 创建的隔离环境和 submodule 都可能误导肉眼判断；检测命令会给出确定答案。 |
| “直接用 `git worktree add` 比找原生工具快” | 原生工具（例如 `EnterWorktree`）负责位置、分支和清理。绕过它是最常见的错误，会产生 harness 看不到、也无法管理的残留状态。 |
| “worktree 目录肯定已经被忽略” | 运行 `git check-ignore`。未被忽略的 worktree 目录会把整棵工作树提交进仓库。 |
| “目录名随便用都行” | 显式指令优先，其次是已有的项目本地目录，最后才是默认 `.worktrees/`。 |
| “工作区是新的，基线测试可以以后再跑” | 脏基线会让后续每个 failure 都无法归因。现在运行测试；是否带着 failure 继续，必须由你的人类伙伴决定。 |
