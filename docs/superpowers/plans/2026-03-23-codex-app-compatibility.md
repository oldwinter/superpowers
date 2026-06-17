# Codex App Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: 使用 superpowers:subagent-driven-development（recommended）或 superpowers:executing-plans 逐 task 实现此 plan。Steps 使用 checkbox（`- [ ]`）syntax 进行 tracking。

**Goal:** 让 `using-git-worktrees`、`finishing-a-development-branch` 和相关 skills 在 Codex App 的 sandboxed worktree environment 中可用，同时不破坏现有 behavior。

**Architecture:** 在两个 skills 开始处使用 read-only environment detection（`git-dir` vs `git-common-dir`）。如果已经位于 linked worktree，则跳过 creation。如果位于 detached HEAD，则输出 handoff payload，而不是 4-option menu。Sandbox fallback 捕获 worktree creation 期间的 permission errors。

**Tech Stack:** Git、Markdown（skill files 是 instruction documents，不是 executable code）

**Spec:** `docs/superpowers/specs/2026-03-23-codex-app-compatibility-design.md`

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `skills/using-git-worktrees/SKILL.md` | Worktree creation + isolation | Add Step 0 detection + sandbox fallback |
| `skills/finishing-a-development-branch/SKILL.md` | Branch finishing workflow | Add Step 1.5 detection + cleanup guard |
| `skills/subagent-driven-development/SKILL.md` | Plan execution with subagents | Update Integration description |
| `skills/executing-plans/SKILL.md` | Plan execution inline | Update Integration description |
| `skills/using-superpowers/references/codex-tools.md` | Codex platform reference | Add detection + finishing docs |

---

### Task 1: Add Step 0 to `using-git-worktrees`

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md:14-15`（插入到 Overview 后、Directory Selection Process 前）

- [ ] **Step 1: Read the current skill file**

完整读取 `skills/using-git-worktrees/SKILL.md`。识别准确插入点：在 “Announce at start” line（line 14）后、"## Directory Selection Process"（line 16）前。

- [ ] **Step 2: Insert Step 0 section**

在 Overview section 和 "## Directory Selection Process" 之间插入以下内容：

```markdown
## Step 0: Check if Already in an Isolated Workspace

Before creating a worktree, check if one already exists:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**If `GIT_DIR` differs from `GIT_COMMON`:** You are already inside a linked worktree (created by the Codex App, Claude Code's Agent tool, a previous skill run, or the user). Do NOT create another worktree. Instead:

1. Run project setup (auto-detect package manager as in "Run Project Setup" below)
2. Verify clean baseline (run tests as in "Verify Clean Baseline" below)
3. Report with branch state:
   - On a branch: "Already in an isolated workspace at `<path>` on branch `<name>`. Tests passing. Ready to implement."
   - Detached HEAD: "Already in an isolated workspace at `<path>` (detached HEAD, externally managed). Tests passing. Note: branch creation needed at finish time. Ready to implement."

After reporting, STOP. Do not continue to Directory Selection or Creation Steps.

**If `GIT_DIR` equals `GIT_COMMON`:** Proceed with the full worktree creation flow below.

**Sandbox fallback:** If you proceed to Creation Steps but `git worktree add -b` fails with a permission error (e.g., "Operation not permitted"), treat this as a late-detected restricted environment. Fall back to the behavior above — run setup and baseline tests in the current directory, report accordingly, and STOP.
```

- [ ] **Step 3: Verify the insertion**

再次读取该文件。确认：
- Step 0 出现在 Overview 和 Directory Selection Process 之间
- 文件其余部分（Directory Selection、Safety Verification、Creation Steps 等）未改变
- 没有 duplicate sections 或 broken markdown

- [ ] **Step 4: Commit**

```bash
git add skills/using-git-worktrees/SKILL.md
git commit -m "feat(using-git-worktrees): add Step 0 environment detection (PRI-823)

Skip worktree creation when already in a linked worktree. Includes
sandbox fallback for permission errors on git worktree add."
```

---

### Task 2: Update `using-git-worktrees` Integration section

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md:211-215`（Integration > Called by）

- [ ] **Step 1: Update the three "Called by" entries**

将 lines 212-214 从：

```markdown
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- **subagent-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
```

改为：

```markdown
- **brainstorming** - REQUIRED: Ensures isolated workspace (creates one or verifies existing)
- **subagent-driven-development** - REQUIRED: Ensures isolated workspace (creates one or verifies existing)
- **executing-plans** - REQUIRED: Ensures isolated workspace (creates one or verifies existing)
```

- [ ] **Step 2: Verify the Integration section**

读取 Integration section。确认三条 entries 都已更新，"Pairs with" 保持不变。

- [ ] **Step 3: Commit**

```bash
git add skills/using-git-worktrees/SKILL.md
git commit -m "docs(using-git-worktrees): update Integration descriptions (PRI-823)

Clarify that skill ensures a workspace exists, not that it always creates one."
```

---

### Task 3: Add Step 1.5 to `finishing-a-development-branch`

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md:38`（插入到 Step 1 后、Step 2 前）

- [ ] **Step 1: Read the current skill file**

完整读取 `skills/finishing-a-development-branch/SKILL.md`。识别插入点：在 "**If tests pass:** Continue to Step 2."（line 38）后、"### Step 2: Determine Base Branch"（line 40）前。

- [ ] **Step 2: Insert Step 1.5 section**

在 Step 1 和 Step 2 之间插入以下内容：

```markdown
### Step 1.5: Detect Environment

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Path A — `GIT_DIR` differs from `GIT_COMMON` AND `BRANCH` is empty (externally managed worktree, detached HEAD):**

First, ensure all work is staged and committed (`git add` + `git commit`).

Then present this to the user (do NOT present the 4-option menu):

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

Branch name: use ticket ID if available (e.g., `pri-823/codex-compat`), otherwise slugify the first 5 words of the plan title, otherwise omit. Avoid sensitive content in branch names.

Skip to Step 5 (cleanup is a no-op — see guard below).

**Path B — `GIT_DIR` differs from `GIT_COMMON` AND `BRANCH` exists (externally managed worktree, named branch):**

Proceed to Step 2 and present the 4-option menu as normal.

**Path C — `GIT_DIR` equals `GIT_COMMON` (normal environment):**

Proceed to Step 2 and present the 4-option menu as normal.
```

- [ ] **Step 3: Verify the insertion**

再次读取文件。确认：
- Step 1.5 位于 Step 1 和 Step 2 之间
- Steps 2-5 保持不变
- Path A handoff 包含 commit SHA 和 data loss warning
- Paths B and C 正常继续 Step 2

- [ ] **Step 4: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "feat(finishing-a-development-branch): add Step 1.5 environment detection (PRI-823)

Detect externally managed worktrees with detached HEAD and emit handoff
payload instead of 4-option menu. Includes commit SHA and data loss warning."
```

---

### Task 4: Add Step 5 cleanup guard to `finishing-a-development-branch`

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`（Step 5: Cleanup Worktree；Task 3 后 line numbers 会变化）

- [ ] **Step 1: Read the current Step 5 section**

在 `skills/finishing-a-development-branch/SKILL.md` 中查找 "### Step 5: Cleanup Worktree" section（Task 3 插入后 line numbers 会变化）。当前 Step 5 是：

```markdown
### Step 5: Cleanup Worktree

**For Options 1, 2, 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.
```

- [ ] **Step 2: Add the cleanup guard before existing logic**

将 Step 5 section 替换为：

```markdown
### Step 5: Cleanup Worktree

**First, check if worktree is externally managed:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

If `GIT_DIR` differs from `GIT_COMMON`: skip worktree removal — the host environment owns this workspace.

**Otherwise, for Options 1 and 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.
```

Note: 原文写 “For Options 1, 2, 4”，但 Quick Reference table 和 Common Mistakes section 写 “Options 1 & 4 only”。此 edit 将 Step 5 与这些 sections 对齐。

- [ ] **Step 3: Verify the replacement**

读取 Step 5。确认：
- cleanup guard（re-detection）首先出现
- non-externally-managed worktrees 的 existing removal logic 保留
- “Options 1 and 4”（不是 “1, 2, 4”）与 Quick Reference 和 Common Mistakes 匹配

- [ ] **Step 4: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "feat(finishing-a-development-branch): add Step 5 cleanup guard (PRI-823)

Re-detect externally managed worktree at cleanup time and skip removal.
Also fixes pre-existing inconsistency: cleanup now correctly says
Options 1 and 4 only, matching Quick Reference and Common Mistakes."
```

---

### Task 5: Update Integration lines in `subagent-driven-development` and `executing-plans`

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:268`
- Modify: `skills/executing-plans/SKILL.md:68`

- [ ] **Step 1: Update `subagent-driven-development`**

将 line 268 从：
```
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
```
改为：
```
- **superpowers:using-git-worktrees** - REQUIRED: Ensures isolated workspace (creates one or verifies existing)
```

- [ ] **Step 2: Update `executing-plans`**

将 line 68 从：
```
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
```
改为：
```
- **superpowers:using-git-worktrees** - REQUIRED: Ensures isolated workspace (creates one or verifies existing)
```

- [ ] **Step 3: Verify both files**

读取 `skills/subagent-driven-development/SKILL.md` line 268 和 `skills/executing-plans/SKILL.md` line 68。确认二者都写着 "Ensures isolated workspace (creates one or verifies existing)"。

- [ ] **Step 4: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md skills/executing-plans/SKILL.md
git commit -m "docs(sdd, executing-plans): update worktree Integration descriptions (PRI-823)

Clarify that using-git-worktrees ensures a workspace exists rather than
always creating one."
```

---

### Task 6: Add environment detection docs to `codex-tools.md`

**Files:**
- Modify: `skills/using-superpowers/references/codex-tools.md:25`（append at end）

- [ ] **Step 1: Read the current file**

完整读取 `skills/using-superpowers/references/codex-tools.md`。确认它在 multi_agent section 后的 line 25-26 结束。

- [ ] **Step 2: Append two new sections**

在文件末尾添加：

```markdown

## Environment Detection

Skills that create worktrees or finish branches should detect their
environment with read-only git commands before proceeding:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)

See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
Step 1.5 for how each skill uses these signals.

## Codex App Finishing

When the sandbox blocks branch/push operations (detached HEAD in an
externally managed worktree), the agent commits all work and informs
the user to use the App's native controls:

- **"Create branch"** — names the branch, then commit/push/PR via App UI
- **"Hand off to local"** — transfers work to the user's local checkout

The agent can still run tests, stage files, and output suggested branch
names, commit messages, and PR descriptions for the user to copy.
```

- [ ] **Step 3: Verify the additions**

读取完整文件。确认：
- 现有内容后出现两个 new sections
- Bash code block 正确 render（未 escape）
- 存在对 Step 0 和 Step 1.5 的 cross-references

- [ ] **Step 4: Commit**

```bash
git add skills/using-superpowers/references/codex-tools.md
git commit -m "docs(codex-tools): add environment detection and App finishing docs (PRI-823)

Document the git-dir vs git-common-dir detection pattern and the Codex
App's native finishing flow for skills that need to adapt."
```

---

### Task 7: Automated test — environment detection

**Files:**
- Create: `tests/codex-app-compat/test-environment-detection.sh`

- [ ] **Step 1: Create test directory**

```bash
mkdir -p tests/codex-app-compat
```

- [ ] **Step 2: Write the detection test script**

Create `tests/codex-app-compat/test-environment-detection.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Test environment detection logic from PRI-823
# Tests the git-dir vs git-common-dir comparison used by
# using-git-worktrees Step 0 and finishing-a-development-branch Step 1.5

PASS=0
FAIL=0
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log_pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
log_fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# Helper: run detection and return "linked" or "normal"
detect_worktree() {
  local git_dir git_common
  git_dir=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
  git_common=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
  if [ "$git_dir" != "$git_common" ]; then
    echo "linked"
  else
    echo "normal"
  fi
}

echo "=== Test 1: Normal repo detection ==="
cd "$TEMP_DIR"
git init test-repo > /dev/null 2>&1
cd test-repo
git commit --allow-empty -m "init" > /dev/null 2>&1
result=$(detect_worktree)
if [ "$result" = "normal" ]; then
  log_pass "Normal repo detected as normal"
else
  log_fail "Normal repo detected as '$result' (expected 'normal')"
fi

echo "=== Test 2: Linked worktree detection ==="
git worktree add "$TEMP_DIR/test-wt" -b test-branch > /dev/null 2>&1
cd "$TEMP_DIR/test-wt"
result=$(detect_worktree)
if [ "$result" = "linked" ]; then
  log_pass "Linked worktree detected as linked"
else
  log_fail "Linked worktree detected as '$result' (expected 'linked')"
fi

echo "=== Test 3: Detached HEAD detection ==="
git checkout --detach HEAD > /dev/null 2>&1
branch=$(git branch --show-current)
if [ -z "$branch" ]; then
  log_pass "Detached HEAD: branch is empty"
else
  log_fail "Detached HEAD: branch is '$branch' (expected empty)"
fi

echo "=== Test 4: Linked worktree + detached HEAD (Codex App simulation) ==="
result=$(detect_worktree)
branch=$(git branch --show-current)
if [ "$result" = "linked" ] && [ -z "$branch" ]; then
  log_pass "Codex App simulation: linked + detached HEAD"
else
  log_fail "Codex App simulation: result='$result', branch='$branch'"
fi

echo "=== Test 5: Cleanup guard — linked worktree should NOT remove ==="
cd "$TEMP_DIR/test-wt"
result=$(detect_worktree)
if [ "$result" = "linked" ]; then
  log_pass "Cleanup guard: linked worktree correctly detected (would skip removal)"
else
  log_fail "Cleanup guard: expected 'linked', got '$result'"
fi

echo "=== Test 6: Cleanup guard — main repo SHOULD remove ==="
cd "$TEMP_DIR/test-repo"
result=$(detect_worktree)
if [ "$result" = "normal" ]; then
  log_pass "Cleanup guard: main repo correctly detected (would proceed with removal)"
else
  log_fail "Cleanup guard: expected 'normal', got '$result'"
fi

# Cleanup worktree before temp dir removal
cd "$TEMP_DIR/test-repo"
git worktree remove "$TEMP_DIR/test-wt" > /dev/null 2>&1 || true

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
```

- [ ] **Step 3: Make it executable and run it**

```bash
chmod +x tests/codex-app-compat/test-environment-detection.sh
./tests/codex-app-compat/test-environment-detection.sh
```

Expected output: 6 passed, 0 failed。

- [ ] **Step 4: Commit**

```bash
git add tests/codex-app-compat/test-environment-detection.sh
git commit -m "test: add environment detection tests for Codex App compat (PRI-823)

Tests git-dir vs git-common-dir comparison in normal repo, linked
worktree, detached HEAD, and cleanup guard scenarios."
```

---

### Task 8: Final verification

**Files:**
- Read: all 5 modified skill files

- [ ] **Step 1: Run the automated detection tests**

```bash
./tests/codex-app-compat/test-environment-detection.sh
```

Expected: 6 passed, 0 failed。

- [ ] **Step 2: Read each modified file and verify changes**

逐个 end-to-end 读取：
- `skills/using-git-worktrees/SKILL.md`：Step 0 present，rest unchanged
- `skills/finishing-a-development-branch/SKILL.md`：Step 1.5 present，cleanup guard present，rest unchanged
- `skills/subagent-driven-development/SKILL.md`：line 268 updated
- `skills/executing-plans/SKILL.md`：line 68 updated
- `skills/using-superpowers/references/codex-tools.md`：末尾有两个 new sections

- [ ] **Step 3: Verify no unintended changes**

```bash
git diff --stat HEAD~7
```

Should show exactly 6 files changed（5 skill files + 1 test file）。No other files modified。

- [ ] **Step 4: Run existing test suite**

如果 test runner 存在：
```bash
# Run skill-triggering tests
# Note: tests/skill-triggering/ was lifted into drill scenarios on 2026-05-06.
# See evals/scenarios/triggering-*.yaml. The reference below is a dated artifact.
./tests/skill-triggering/run-all.sh 2>/dev/null || echo "Skill triggering tests not available in this environment"

# Run SDD integration test
./tests/claude-code/test-subagent-driven-development-integration.sh 2>/dev/null || echo "SDD integration test not available in this environment"
```

Note: 这些 tests 需要 Claude Code with `--dangerously-skip-permissions`。如果不可用，记录 regression tests 应 manual run。
