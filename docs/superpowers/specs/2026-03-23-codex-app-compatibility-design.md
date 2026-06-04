# Codex App Compatibility: Worktree and Finishing Skill Adaptation

让 superpowers skills 在 Codex App 的 sandboxed worktree environment 中可用，同时不破坏现有 Claude Code 或 Codex CLI behavior。

**Ticket:** PRI-823

## Motivation

Codex App 会让 agents 运行在它管理的 git worktrees 中：detached HEAD、位于 `$CODEX_HOME/worktrees/` 下，并带有 Seatbelt sandbox，会阻止 `git checkout -b`、`git push` 和 network access。三个 superpowers skills 假设 git access 不受限制：`using-git-worktrees` 会用 named branches 创建 manual worktrees，`finishing-a-development-branch` 会按 branch name merge/push/PR，`subagent-driven-development` 依赖二者。

Codex CLI（open source terminal tool）没有这个冲突：它没有 built-in worktree management。我们的 manual worktree approach 正好填补它的 isolation gap。问题特指 Codex App。

## Empirical Findings

2026-03-23 在 Codex App 中测试：

| Operation | workspace-write sandbox | Full access sandbox |
|---|---|---|
| `git add` | Works | Works |
| `git commit` | Works | Works |
| `git checkout -b` | **Blocked**（无法写 `.git/refs/heads/`） | Works |
| `git push` | **Blocked**（network + `.git/refs/remotes/`） | Works |
| `gh pr create` | **Blocked**（network） | Works |
| `git status/diff/log` | Works | Works |

Additional findings:
- `spawn_agent` subagents **共享** parent thread 的 filesystem（通过 marker file test 确认）。
- App header 中始终显示 “Create branch” button，不受 worktree 起始 branch 影响。
- App native finishing flow：Create branch → Commit modal → Commit and push / Commit and create PR。
- macOS 上 `network_access = true` config 会 silent broken（issue #10390）。

## Design: Read-Only Environment Detection

用三个 read-only git commands 无副作用检测 environment：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

派生出两个 signals：

- **IN_LINKED_WORKTREE:** `GIT_DIR != GIT_COMMON`：agent 位于其他东西创建的 worktree 中（Codex App、Claude Code Agent tool、previous skill run 或 user）
- **ON_DETACHED_HEAD:** `BRANCH` 为空：没有 named branch

为什么使用 `git-dir != git-common-dir` 而不是检查 `show-toplevel`：
- 在 normal repo 中，二者都 resolve 到同一个 `.git` directory
- 在 linked worktree 中，`git-dir` 是 `.git/worktrees/<name>`，而 `git-common-dir` 是 `.git`
- 在 submodule 中，二者相等，避免 `show-toplevel` 会产生的 false positive
- 通过 `cd && pwd -P` resolve 可以处理 relative-path problem（normal repos 中 `git-common-dir` 返回 relative `.git`，worktrees 中返回 absolute）以及 symlinks（macOS `/tmp` → `/private/tmp`）

### Decision Matrix

| Linked Worktree? | Detached HEAD? | Environment | Action |
|---|---|---|---|
| No | No | Claude Code / Codex CLI / normal git | Full skill behavior（unchanged） |
| Yes | Yes | Codex App worktree（workspace-write） | Skip worktree creation；finish 时提供 handoff payload |
| Yes | No | Codex App（Full access）或 manual worktree | Skip worktree creation；full finishing flow |
| No | Yes | Unusual（manual detached HEAD） | 正常创建 worktree；finish 时 warn |

## Changes

### 1. `using-git-worktrees/SKILL.md`：添加 Step 0（约 12 行）

在 “Overview” 和 “Directory Selection Process” 之间新增 section：

**Step 0: Check if Already in an Isolated Workspace**

运行 detection commands。如果 `GIT_DIR != GIT_COMMON`，完全跳过 worktree creation。改为：
1. 跳到 Creation Steps 下的 “Run Project Setup” subsection：`npm install` 等是 idempotent，为安全值得运行
2. 然后 “Verify Clean Baseline”：运行 tests
3. 带 branch state 报告：
   - 在 branch 上："Already in an isolated workspace at `<path>` on branch `<name>`. Tests passing. Ready to implement."
   - Detached HEAD："Already in an isolated workspace at `<path>` (detached HEAD, externally managed). Tests passing. Note: branch creation needed at finish time. Ready to implement."

如果 `GIT_DIR == GIT_COMMON`，继续完整 worktree creation flow（unchanged）。

Step 0 触发时跳过 Safety verification（.gitignore check）：externally-created worktrees 不相关。

更新 Integration section 中的 “Called by” entries。将每条 description 从 context-specific text 改为："Ensures isolated workspace (creates one or verifies existing)"。例如，`subagent-driven-development` entry 从 “REQUIRED: Set up isolated workspace before starting” 改为 “REQUIRED: Ensures isolated workspace (creates one or verifies existing)”。

**Sandbox fallback:** 如果 `GIT_DIR == GIT_COMMON` 且 skill 继续 Creation Steps，但 `git worktree add -b` 因 permission error（例如 Seatbelt sandbox denial）失败，将其视为 late-detected restricted environment。Fallback 到 Step 0 的 “already in workspace” behavior：跳过 creation，在 current directory 中运行 setup 和 baseline tests，并据此报告。

在 Step 0 中 report 后，STOP。不要继续 Directory Selection 或 Creation Steps。

**Everything else unchanged:** Directory Selection、Safety Verification、Creation Steps、Project Setup、Baseline Tests、Quick Reference、Common Mistakes、Red Flags。

### 2. `finishing-a-development-branch/SKILL.md`：添加 Step 1.5 + cleanup guard（约 20 行）

**Step 1.5: Detect Environment**（位于 Step 1 “Verify Tests” 之后、Step 2 “Determine Base Branch” 之前）

运行 detection commands。三条 paths：

- **Path A** 完全跳过 Steps 2 和 3（无需 base branch 或 options）。
- **Paths B and C** 按正常流程继续 Step 2（Determine Base Branch）和 Step 3（Present Options）。

**Path A — Externally managed worktree + detached HEAD**（`GIT_DIR != GIT_COMMON` AND `BRANCH` empty）：

首先，确保所有工作都 staged and committed（`git add` + `git commit`）。Codex App 的 finishing controls 作用于 committed work。

然后向用户展示以下内容（不要展示 4-option menu）：

```
Implementation complete. All tests passing.
Current HEAD: <full-commit-sha>

This workspace is externally managed (detached HEAD).
I cannot create branches, push, or open PRs from here.

⚠ These commits are on a detached HEAD. If you do not create a branch,
they may be lost when this workspace is cleaned up.

If your host application provides these controls:
- "Create branch" — to name a branch, then commit/push/PR
- "Hand off to local" — to move changes to your local checkout

Suggested branch name: <ticket-id/short-description>
Suggested commit message: <summary-of-work>
```

Branch name derivation：如果 ticket ID 可用（例如 `pri-823/codex-compat`），使用它；否则 slugify plan title 的前 5 个 words；否则省略 suggestion。避免在 branch names 中包含 sensitive content（vulnerability descriptions、customer names）。

跳到 Step 5（externally managed worktrees 的 cleanup 是 no-op）。

**Path B — Externally managed worktree + named branch**（`GIT_DIR != GIT_COMMON` AND `BRANCH` exists）：

正常展示 4-option menu。（Step 5 cleanup guard 会在 cleanup 时独立重新检测 externally managed state。）

**Path C — Normal environment**（`GIT_DIR == GIT_COMMON`）：

按当前方式展示 4-option menu（unchanged）。

**Step 5 cleanup guard:**

cleanup 时重新运行 `GIT_DIR` vs `GIT_COMMON` detection（不要依赖 earlier skill output，因为 finishing skill 可能在不同 session 中运行）。如果 `GIT_DIR != GIT_COMMON`，跳过 `git worktree remove`：host environment 拥有该 workspace。

否则，按当前方式检查并 remove。注意：现有 Step 5 text 写 “For Options 1, 2, 4”，但 Quick Reference table 和 Common Mistakes section 写 “Options 1 & 4 only”。新 guard 添加在现有 logic 前，不改变哪些 options 触发 cleanup。

**Everything else unchanged:** Options 1-4 logic、Quick Reference、Common Mistakes、Red Flags。

### 3. `subagent-driven-development/SKILL.md` 和 `executing-plans/SKILL.md`：各 1 行 edit

两个 skills 的 Integration section 中都有相同行。将：
```
- superpowers:using-git-worktrees - REQUIRED: Set up isolated workspace before starting
```
改为：
```
- superpowers:using-git-worktrees - REQUIRED: Ensures isolated workspace (creates one or verifies existing)
```

**Everything else unchanged:** Dispatch/review loop、prompt templates、model selection、status handling、red flags。

### 4. `codex-tools.md`：添加 environment detection docs（约 15 行）

末尾新增两个 sections：

**Environment Detection:**

```markdown
## Environment Detection

Skills that create worktrees or finish branches should detect their
environment with read-only git commands before proceeding:

\```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
\```

- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)

See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
Step 1.5 for how each skill uses these signals.
```

**Codex App Finishing:**

```markdown
## Codex App Finishing

When the sandbox blocks branch/push operations (detached HEAD in an
externally managed worktree), the agent commits all work and informs
the user to use the App's native controls:

- **"Create branch"** — names the branch, then commit/push/PR via App UI
- **"Hand off to local"** — transfers work to the user's local checkout

The agent can still run tests, stage files, and output suggested branch
names, commit messages, and PR descriptions for the user to copy.
```

## What Does NOT Change

- `implementer-prompt.md`、`spec-reviewer-prompt.md`、`code-quality-reviewer-prompt.md`：subagent prompts untouched
- `executing-plans/SKILL.md`：只有 1-line Integration description changes（与 `subagent-driven-development` 相同）；所有 runtime behavior unchanged
- `dispatching-parallel-agents/SKILL.md`：无 worktree 或 finishing operations
- `.codex/INSTALL.md`：installation process unchanged
- The 4-option finishing menu：为 Claude Code 和 Codex CLI 完整保留
- The full worktree creation flow：为 non-worktree environments 完整保留
- Subagent dispatch/review/iterate loop：unchanged（已确认 filesystem sharing）

## Scope Summary

| File | Change |
|---|---|
| `skills/using-git-worktrees/SKILL.md` | +12 lines（Step 0） |
| `skills/finishing-a-development-branch/SKILL.md` | +20 lines（Step 1.5 + cleanup guard） |
| `skills/subagent-driven-development/SKILL.md` | 1 line edit |
| `skills/executing-plans/SKILL.md` | 1 line edit |
| `skills/using-superpowers/references/codex-tools.md` | +15 lines |

5 个 files 中约 50 行 added/changed。Zero new files。Zero breaking changes。

## Future Considerations

如果第三个 skill 需要同样 detection pattern，则将其 extract 到 shared `references/environment-detection.md` file（Approach B）。目前不需要：只有 2 个 skills 使用它。

## Test Plan

### Automated（implementation 后在 Claude Code 中运行）

1. Normal repo detection：assert IN_LINKED_WORKTREE=false
2. Linked worktree detection：`git worktree add` test worktree，assert IN_LINKED_WORKTREE=true
3. Detached HEAD detection：`git checkout --detach`，assert ON_DETACHED_HEAD=true
4. Finishing skill handoff output：验证 restricted environment 中输出 handoff message（不是 4-option menu）
5. **Step 5 cleanup guard**：创建 linked worktree（`git worktree add /tmp/test-cleanup -b test-cleanup`），`cd` 进去，运行 Step 5 cleanup detection（`GIT_DIR` vs `GIT_COMMON`），assert 不会调用 `git worktree remove`。然后 `cd` 回 main repo，运行同一 detection，assert 会调用 `git worktree remove`。之后清理 test worktree。

### Manual Codex App Tests（5 tests）

1. Detection in Worktree thread（workspace-write）：验证 GIT_DIR != GIT_COMMON，branch 为空
2. Detection in Worktree thread（Full access）：相同 detection，不同 sandbox behavior
3. Finishing skill handoff format：验证 agent emits handoff payload，而不是 4-option menu
4. Full lifecycle：detection → commit → finishing detection → correct behavior → cleanup
5. **Sandbox fallback in Local thread**：启动 Codex App **Local thread**（workspace-write sandbox）。Prompt："Use the superpowers skill `using-git-worktrees` to set up an isolated workspace for implementing a small change." Pre-check：`git checkout -b test-sandbox-check` 应以 `Operation not permitted` 失败。Expected：skill 检测 `GIT_DIR == GIT_COMMON`（normal repo），尝试 `git worktree add -b`，遇到 Seatbelt denial，fallback 到 Step 0 “already in workspace” behavior：运行 setup、baseline tests，并从 current directory 报告 ready。Pass：agent graceful recover，没有 cryptic error messages。Fail：agent 打印 raw Seatbelt error、重试或用 confusing output 放弃。

### Regression

- Existing Claude Code skill-triggering tests still pass
- Existing subagent-driven-development integration tests still pass
- Normal Claude Code session：full worktree creation + 4-option finishing still works
