---
name: finishing-a-development-branch
description: implementation 完成、所有 tests pass，并需要决定如何 integrate work 时使用 - 通过提供 merge、PR 或 cleanup 的结构化选项来指导 development work 收尾
---

# Finishing a Development Branch

## 概览

通过展示清晰选项并处理所选 workflow，指导 development work 收尾。

**核心原则：** Verify tests → Detect environment → Present options → Execute choice → Clean up。

**开始时宣布：** "I'm using the finishing-a-development-branch skill to complete this work."

## 流程

### Step 1: 验证 Tests

**展示选项之前，验证 tests pass：**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**如果 tests fail：**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

停下。不要继续 Step 2。

**如果 tests pass：** 继续 Step 2。

### Step 2: 检测 Environment

**展示选项之前，确定 workspace state：**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

这会决定展示哪个 menu，以及 cleanup 如何工作：

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | 没有 worktree 需要清理 |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based（见 Step 6） |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options（无 merge） | 不 cleanup（externally managed） |

### Step 3: 确定 Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

或询问："This branch split from main - is that correct?"

### Step 4: 展示选项

**Normal repo 和 named-branch worktree：准确展示这 4 个选项：**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD：准确展示这 3 个选项：**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**不要添加解释**：保持选项简洁。

### Step 5: 执行选择

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

然后：Cleanup worktree（Step 6），再删除 branch：

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**不要 cleanup worktree**：用户需要它来迭代 PR feedback。

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**不要 cleanup worktree。**

#### Option 4: Discard

**先确认：**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

等待精确确认。

如果确认：
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

然后：Cleanup worktree（Step 6），再 force-delete branch：
```bash
git branch -D <feature-branch>
```

### Step 6: Cleanup Workspace

**只对 Options 1 和 4 运行。** Options 2 和 3 始终保留 worktree。

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**如果 `GIT_DIR == GIT_COMMON`：** Normal repo，没有 worktree 需要 cleanup。完成。

**如果 worktree path 位于 `.worktrees/`、`worktrees/` 或 `~/.config/superpowers/worktrees/` 下：** 这个 worktree 由 Superpowers 创建，我们负责 cleanup。

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**否则：** host environment（harness）拥有这个 workspace。不要移除它。如果你的平台提供 workspace-exit tool，就使用它。否则保留 workspace。

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## 常见错误

**Skipping test verification**
- **Problem:** Merge 破损代码，创建 failing PR
- **Fix:** 展示选项前始终 verify tests

**Open-ended questions**
- **Problem:** "What should I do next?" 含糊
- **Fix:** 准确展示 4 个结构化选项（detached HEAD 时 3 个）

**Cleaning up worktree for Option 2**
- **Problem:** 移除了用户迭代 PR 所需的 worktree
- **Fix:** 只对 Options 1 和 4 cleanup

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` 失败，因为 worktree 仍引用 branch
- **Fix:** 先 merge，移除 worktree，再删除 branch

**Running git worktree remove from inside the worktree**
- **Problem:** CWD 在待移除 worktree 内时，command 会静默失败
- **Fix:** `git worktree remove` 前始终 `cd` 到 main repo root

**Cleaning up harness-owned worktrees**
- **Problem:** 移除 harness 创建的 worktree 会造成 phantom state
- **Fix:** 只 cleanup `.worktrees/`、`worktrees/` 或 `~/.config/superpowers/worktrees/` 下的 worktrees

**No confirmation for discard**
- **Problem:** 意外删除工作
- **Fix:** 要求 typed "discard" confirmation

## Red Flags

**Never:**
- 带着 failing tests 继续
- 不验证 merged result 的 tests 就 merge
- 未确认就删除工作
- 未明确请求就 force-push
- 确认 merge 成功前移除 worktree
- Cleanup 不是你创建的 worktrees（provenance check）
- 从 worktree 内运行 `git worktree remove`

**Always:**
- 提供选项前 verify tests
- 展示 menu 前 detect environment
- 准确展示 4 个选项（detached HEAD 时 3 个）
- Option 4 获取 typed confirmation
- 只对 Options 1 & 4 cleanup worktree
- 移除 worktree 前 `cd` 到 main repo root
- 移除后运行 `git worktree prune`
