# Worktree Rototill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: 使用 superpowers:subagent-driven-development（recommended）或 superpowers:executing-plans 逐 task 实现此 plan。Steps 使用 checkbox（`- [ ]`）syntax 进行 tracking。

**Goal:** 让 superpowers 在 native harness worktree systems 可用时 defer 给它们；否则 fallback 到 manual git worktrees；同时修复三个已知 finishing bugs。

**Architecture:** 重写两个 skill files（`using-git-worktrees`、`finishing-a-development-branch`），三个 files 做 one-line integration updates（`executing-plans`、`subagent-driven-development`、`writing-plans`）。核心变化是添加 detection（`GIT_DIR != GIT_COMMON`）和 native-tool-first creation path。这些是 markdown skill instruction files，不是 application code；“tests” 是使用 testing-skills-with-subagents TDD framework 的 agent behavior tests。

**Tech Stack:** Markdown（skill files）、bash（test scripts）、Claude Code CLI（`claude -p` 用于 headless testing）

**Spec:** `docs/superpowers/specs/2026-04-06-worktree-rototill-design.md`

---

### Task 1: GATE — TDD Validation of Step 1a（Native Tool Preference）

Step 1a 是整个 design 的 load-bearing assumption。如果 agents 不会优先使用 native worktree tools，而是使用 `git worktree add`，spec 就失败。必须先验证这一点，再触碰任何 skill files。

**Files:**
- Create: `tests/claude-code/test-worktree-native-preference.sh`
- Read: `skills/using-git-worktrees/SKILL.md`（current version，用于 RED baseline）
- Read: `tests/claude-code/test-helpers.sh`（用于 `run_claude`、`assert_contains` 等）
- Read: `skills/writing-skills/testing-skills-with-subagents.md`（TDD framework）

**This task is a gate.** 如果 GREEN phase 在 2 次 REFACTOR iterations 后仍失败，STOP。不要继续 Task 2。Report back：creation approach 需要 redesign。

- [ ] **Step 1: Write the RED baseline test script**

创建 test script，用于在 WITHOUT 和 WITH updated skill text 两种场景运行。RED phase 针对 current skill 运行（它没有 Step 1a）。

```bash
#!/usr/bin/env bash
# Test: Does the agent prefer native worktree tools (EnterWorktree) over git worktree add?
# Framework: RED-GREEN-REFACTOR per testing-skills-with-subagents.md
#
# RED:   Current skill has no native tool preference. Agent should use git worktree add.
# GREEN: Updated skill has Step 1a. Agent should use EnterWorktree on Claude Code.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Pressure scenario: realistic implementation task where agent needs isolation
SCENARIO='IMPORTANT: This is a real task. Choose and act.

You need to implement a small feature (add a "version" field to package.json).
This should be done in an isolated workspace to protect the main branch.

You have the using-git-worktrees skill available. Set up the isolated workspace now.
Do NOT actually implement the feature — just set up the workspace and report what you did.

Respond with EXACTLY what tool/command you used to create the workspace.'

echo "=== Worktree Native Preference Test ==="
echo ""

# Phase selection
PHASE="${1:-red}"

if [ "$PHASE" = "red" ]; then
    echo "--- RED PHASE: Running WITHOUT Step 1a (current skill) ---"
    echo "Expected: Agent uses 'git worktree add' (no native tool awareness)"
    echo ""

    test_dir=$(create_test_project)
    cd "$test_dir"
    git init && git commit --allow-empty -m "init"
    mkdir -p .worktrees

    output=$(run_claude "$SCENARIO" 120)

    echo "Agent output:"
    echo "$output"
    echo ""

    # RED expectation: agent uses git worktree add (current behavior)
    if echo "$output" | grep -qi "EnterWorktree"; then
        echo "[UNEXPECTED] Agent used EnterWorktree WITHOUT Step 1a — skill may not be needed"
        echo "Investigate: is Claude Code's default behavior already correct?"
    else
        echo "[RED CONFIRMED] Agent did NOT use EnterWorktree"
        assert_contains "$output" "git worktree" "Agent used git worktree (expected in RED)"
    fi

    cleanup_test_project "$test_dir"

elif [ "$PHASE" = "green" ]; then
    echo "--- GREEN PHASE: Running WITH Step 1a (updated skill) ---"
    echo "Expected: Agent uses EnterWorktree instead of git worktree add"
    echo ""

    test_dir=$(create_test_project)
    cd "$test_dir"
    git init && git commit --allow-empty -m "init"

    output=$(run_claude "$SCENARIO" 120)

    echo "Agent output:"
    echo "$output"
    echo ""

    # GREEN expectation: agent uses EnterWorktree
    assert_contains "$output" "EnterWorktree" "Agent used native EnterWorktree tool"
    assert_not_contains "$output" "git worktree add" "Agent did NOT fall back to git worktree add"

    cleanup_test_project "$test_dir"

elif [ "$PHASE" = "pressure" ]; then
    echo "--- PRESSURE PHASE: Multiple pressures to skip native tools ---"
    echo ""

    PRESSURE_SCENARIO='IMPORTANT: This is a real task. Choose and act.

You need to set up an isolated workspace URGENTLY. Production is impacted and
the fix needs to go in a worktree. You know git worktree add works reliably.
The .worktrees/ directory already exists and is gitignored.

You have the using-git-worktrees skill. Set up the workspace NOW.
Speed matters. Report EXACTLY what tool/command you used.'

    test_dir=$(create_test_project)
    cd "$test_dir"
    git init && git commit --allow-empty -m "init"
    mkdir -p .worktrees
    echo ".worktrees/" >> .gitignore

    output=$(run_claude "$PRESSURE_SCENARIO" 120)

    echo "Agent output:"
    echo "$output"
    echo ""

    # Should STILL use EnterWorktree even under pressure
    assert_contains "$output" "EnterWorktree" "Agent used native tool even under time pressure"
    assert_not_contains "$output" "git worktree add" "Agent resisted falling back to git despite pressure"

    cleanup_test_project "$test_dir"
fi

echo ""
echo "=== Test Complete ==="
```

- [ ] **Step 2: Run RED phase — confirm agent uses git worktree add today**

Run: `cd tests/claude-code && bash test-worktree-native-preference.sh red`

Expected: `[RED CONFIRMED] Agent did NOT use EnterWorktree`：agent 使用 `git worktree add`，因为 current skill 没有 native tool preference。

逐字记录 agent exact output 和任何 rationalizations。这是 skill 必须修复的 baseline failure。

- [ ] **Step 3: If RED confirmed, proceed. Write the Step 1a skill text.**

创建一个 temporary test version of the skill，只加入 Step 1a（minimal change，隔离变量）。将此 section 添加到 skill creation instructions 顶部，位于 existing directory selection process 之前：

```markdown
## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

If your platform provides a worktree or workspace-isolation tool, use it. You know your own toolkit — the skill does not need to name specific tools. Native tools handle directory placement, branch creation, and cleanup automatically.

After using a native tool, skip to Step 3 (Project Setup).

### 1b. Git Worktree Fallback

If no native tool is available, create a worktree manually using git.
```

- [ ] **Step 4: Run GREEN phase — confirm agent now uses EnterWorktree**

Run: `cd tests/claude-code && bash test-worktree-native-preference.sh green`

Expected: `[PASS] Agent used native EnterWorktree tool`

If FAIL: 记录 agent exact output 和 rationalizations。这是 REFACTOR signal：Step 1a text 需要 revision。最多尝试 2 次 REFACTOR iterations。如果仍失败，STOP and report back。

- [ ] **Step 5: Run PRESSURE phase — confirm agent resists fallback under pressure**

Run: `cd tests/claude-code && bash test-worktree-native-preference.sh pressure`

Expected: `[PASS] Agent used native tool even under time pressure`

If FAIL: 逐字记录 rationalizations。向 Step 1a text 添加 explicit counters（例如 Red Flag entry："Never use git worktree add when your platform provides a native worktree tool"）。Re-run。

- [ ] **Step 6: Commit test script**

```bash
git add tests/claude-code/test-worktree-native-preference.sh
git commit -m "test: add RED/GREEN validation for native worktree preference (PRI-974)

Gate test for Step 1a — validates agents prefer EnterWorktree over
git worktree add on Claude Code. Must pass before skill rewrite."
```

---

### Task 2: Rewrite `using-git-worktrees` SKILL.md

完整重写 creation skill。替换现有整个文件。

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md`（full rewrite，219 lines → ~210 lines）

**Depends on:** Task 1 GREEN passing。

- [ ] **Step 1: Write the complete new SKILL.md**

将 `skills/using-git-worktrees/SKILL.md` 的全部内容替换为：

```markdown
---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — proceed to Step 1
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

If your platform provides a worktree or workspace-isolation tool, use it. You know your own toolkit — the skill does not need to name specific tools. Native tools handle directory placement, branch creation, and cleanup automatically.

After using a native tool, skip to Step 3 (Project Setup).

### 1b. Git Worktree Fallback

If no native tool is available, create a worktree manually using git.

#### Directory Selection

Follow this priority order:

1. **Check your instructions for a worktree directory preference.** If specified, use it without asking.

2. **Check existing project-local directories:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use that directory. If both exist, `.worktrees` wins.

3. **Default to `.worktrees/`.**

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** Add to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

#### Create the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

#### Hooks Awareness

Git worktrees do not inherit the parent repo's hooks directory. After creating the worktree, symlink hooks from the main repo if they exist:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
if [ -d "$MAIN_ROOT/.git/hooks" ]; then
    ln -sf "$MAIN_ROOT/.git/hooks" "$path/.git/hooks"
fi
```

This prevents pre-commit checks, linters, and other hooks from silently stopping when work moves to a worktree.

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), treat this as a restricted environment. Skip creation, run setup and baseline tests in the current directory, report accordingly.

## Step 3: Project Setup

Auto-detect and run appropriate setup:

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

## Step 4: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: existing > instruction file > default

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

## Red Flags

**Never:**
- Create a worktree when Step 0 detects existing isolation
- Use git commands when a native worktree tool is available
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Run Step 0 detection first
- Prefer native tools over git fallback
- Follow directory priority: existing > instruction file > default
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline
- Symlink hooks after creating worktree via 1b

## Integration

**Called by:**
- **subagent-driven-development** - Ensures isolated workspace (creates one or verifies existing)
- **executing-plans** - Ensures isolated workspace (creates one or verifies existing)
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
```

- [ ] **Step 2: Verify the file reads correctly**

Run: `wc -l skills/using-git-worktrees/SKILL.md`

Expected: 约 200-220 lines。扫描任何 markdown formatting issues。

- [ ] **Step 3: Commit**

```bash
git add skills/using-git-worktrees/SKILL.md
git commit -m "feat: rewrite using-git-worktrees with detect-and-defer (PRI-974)

Step 0: GIT_DIR != GIT_COMMON detection (skip if already isolated)
Step 0 consent: opt-in prompt before creating worktree (#991)
Step 1a: native tool preference (short, first, declarative)
Step 1b: git worktree fallback with project-local directory policy
Submodule guard prevents false detection
Platform-neutral instruction file references (#1049)"
```

---

### Task 3: Rewrite `finishing-a-development-branch` SKILL.md

完整重写 finishing skill。添加 environment detection、修复三个 bugs，并添加 provenance-based cleanup。

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`（full rewrite，201 lines → ~220 lines）

- [ ] **Step 1: Write the complete new SKILL.md**

将 `skills/finishing-a-development-branch/SKILL.md` 的全部内容替换为：

```markdown
---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

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

# Only after merge succeeds: remove worktree, then delete branch
# (See Step 6 for worktree cleanup)
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 6)

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

**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 6), then force-delete branch:
```bash
git branch -D <feature-branch>
```

### Step 6: Cleanup Workspace

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Present exactly 4 options (or 3 for detached HEAD)
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
```

- [ ] **Step 2: Verify the file reads correctly**

Run: `wc -l skills/finishing-a-development-branch/SKILL.md`

Expected: 约 210-230 lines。

- [ ] **Step 3: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "feat: rewrite finishing-a-development-branch with detect-and-defer (PRI-974)

Step 2: environment detection (GIT_DIR != GIT_COMMON) before presenting menu
Detached HEAD: reduced 3-option menu (no merge from detached HEAD)
Provenance-based cleanup: .worktrees/ = ours, anything else = hands off
Bug #940: Option 2 no longer cleans up worktree
Bug #999: merge -> verify -> remove worktree -> delete branch
Bug #238: cd to main repo root before git worktree remove
Stale worktree pruning after removal (git worktree prune)"
```

---

### Task 4: Integration Updates

对引用 `using-git-worktrees` 的三个 files 做 one-line changes。

**Files:**
- Modify: `skills/executing-plans/SKILL.md:68`
- Modify: `skills/subagent-driven-development/SKILL.md:268`
- Modify: `skills/writing-plans/SKILL.md:16`

- [ ] **Step 1: Update executing-plans integration line**

在 `skills/executing-plans/SKILL.md` 中，将 line 68 从：

```markdown
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
```

改为：

```markdown
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
```

- [ ] **Step 2: Update subagent-driven-development integration line**

在 `skills/subagent-driven-development/SKILL.md` 中，将 line 268 从：

```markdown
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
```

改为：

```markdown
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
```

- [ ] **Step 3: Update writing-plans context line**

在 `skills/writing-plans/SKILL.md` 中，将 line 16 从：

```markdown
**Context:** This should be run in a dedicated worktree (created by brainstorming skill).
```

改为：

```markdown
**Context:** If working in an isolated worktree, it should have been created via the using-git-worktrees skill at execution time.
```

- [ ] **Step 4: Commit all three**

```bash
git add skills/executing-plans/SKILL.md skills/subagent-driven-development/SKILL.md skills/writing-plans/SKILL.md
git commit -m "fix: update worktree integration references across skills (PRI-974)

Remove REQUIRED language from executing-plans and subagent-driven-development.
Consent and detection now live inside using-git-worktrees itself.
Fix stale 'created by brainstorming' claim in writing-plans."
```

---

### Task 5: End-to-End Validation

验证完整 rewritten skills 可以协同工作。运行现有 test suite，并做 manual verification。

**Files:**
- Read: `tests/claude-code/run-skill-tests.sh`
- Read: `skills/using-git-worktrees/SKILL.md`（verify final state）
- Read: `skills/finishing-a-development-branch/SKILL.md`（verify final state）

- [ ] **Step 1: Run existing test suite**

Run: `cd tests/claude-code && bash run-skill-tests.sh`

Expected: 所有 existing tests pass。如果有失败，investigate：Task 4 的 integration changes 可能破坏了 content assertion。

- [ ] **Step 2: Re-run Step 1a GREEN test**

Run: `cd tests/claude-code && bash test-worktree-native-preference.sh green`

Expected: PASS：agent 仍使用 EnterWorktree，并且使用的是 final skill text（不只是 Task 1 中 minimal Step 1a addition）。

- [ ] **Step 3: Manual verification — read both rewritten skills end-to-end**

完整读取 `skills/using-git-worktrees/SKILL.md` 和 `skills/finishing-a-development-branch/SKILL.md`。检查：

1. 没有 references to old behavior（hardcoded `CLAUDE.md`、interactive directory prompt、"REQUIRED" language）
2. 每个文件中的 Step numbering 一致
3. Quick Reference tables 与 prose 匹配
4. Integration sections cross-reference 正确
5. 没有 markdown formatting issues

- [ ] **Step 4: Verify git status is clean**

Run: `git status`

Expected: Clean working tree。Tasks 1-4 的所有 changes 已 committed。

- [ ] **Step 5: Final commit if any fixups needed**

如果 manual verification 发现 issues，修复并 commit：

```bash
git add -A
git commit -m "fix: address review findings in worktree skill rewrite (PRI-974)"
```

如果没有 issues，跳过此 step。
