# Worktree Rototill: Detect-and-Defer

**Date:** 2026-04-06
**Status:** Draft
**Ticket:** PRI-974
**Subsumes:** PRI-823（Codex App compatibility）

## Problem

Superpowers 对 worktree management 有强 opinion：特定 paths（`.worktrees/<branch>`）、特定 commands（`git worktree add`）、特定 cleanup（`git worktree remove`）。与此同时，Claude Code、Codex App、Gemini CLI 和 Cursor 都提供自己的 native worktree support，拥有各自的 paths、lifecycle management 和 cleanup。

这造成三种 failure modes：

1. **Duplication**：在 Claude Code 上，skill 做了 `EnterWorktree`/`ExitWorktree` 已经做的事
2. **Conflict**：在 Codex App 上，skill 会尝试在 already-managed worktree 里创建 worktrees
3. **Phantom state**：skill-created worktrees 位于 `.worktrees/`，harness 看不见；harness-created worktrees 位于 `.claude/worktrees/`，skill 看不见

对于没有 native support 的 harnesses（Codex CLI、OpenCode、Copilot standalone），superpowers 填补了真实 gap。该 skill 不应该消失；它应在 native support 存在时让路。

## Goals

1. 当 native harness worktree systems 存在时 defer 给它们
2. 继续为缺少 worktree support 的 harnesses 提供支持
3. 修复 `finishing-a-development-branch` 中三个已知 bugs（#940、#999、#238）
4. 让 worktree creation 从 mandatory 改为 opt-in（#991）
5. 用 platform-neutral language 替换 hardcoded `CLAUDE.md` references（#1049）

## Non-Goals

- Per-worktree environment conventions（`.worktree-env.sh`、port offsetting）：Phase 4
- PreToolUse hooks for path enforcement：Phase 4
- Multi-repo worktree documentation：Phase 4
- Brainstorming checklist changes for worktrees：Phase 4
- `.superpowers-session.json` metadata tracking（PR #997 的有趣想法，但 v1 不需要）
- Hooks symlinking into worktrees（PR #965 idea，单独 concern）

## Design Principles

### Detect state, not platform

使用 `GIT_DIR != GIT_COMMON` 判断 “我是否已经在 worktree 中？”，而不是 sniff environment variables 来识别 harness。这是稳定的 git primitive（自 git 2.5，2015 起），可普遍适用于所有 harnesses，并且随着新 harnesses 出现无需维护。

### Declarative intent, prescriptive fallback

Skill 描述目标（“ensure work happens in an isolated workspace”），并在可用时 defer 给 native tools。只有在缺少 native worktree support 的 harnesses 上，才 prescribe 具体 git commands 作为 fallback。Step 1a 放在前面，并明确命名 native tools（`EnterWorktree`、`WorktreeCreate`、`/worktree`、`--worktree`）；Step 1b 放在后面，提供 git fallback。原 spec 让 Step 1a 保持抽象（“you know your own toolkit”），但 TDD 证明当 Step 1a 太含糊时，agents 会锚定 Step 1b 的 concrete commands。必须显式命名 tools，并建立 consent-authorization bridge，才能可靠表达偏好。

### Provenance-based ownership

谁创建 worktree，谁拥有它的 cleanup。如果 harness 创建它，superpowers 不碰它。如果 superpowers 创建它（via git fallback），superpowers 清理它。Heuristic：如果 worktree 位于 `.worktrees/` 或 `~/.config/superpowers/worktrees/` 下，superpowers owns it。其他路径（`.claude/worktrees/`、`~/.codex/worktrees/`、`.gemini/worktrees/`）属于 harness。

## Design

### 1. `using-git-worktrees` SKILL.md Rewrite

该 skill 在 creation 前新增三个 steps，并简化 creation flow。

#### Step 0: Detect Existing Isolation

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

三种 outcomes：

| Condition | Meaning | Action |
|-----------|---------|--------|
| `GIT_DIR == GIT_COMMON` | Normal repo checkout | Proceed to Step 0.5 |
| `GIT_DIR != GIT_COMMON`, named branch | Already in a linked worktree | Skip to Step 3（project setup）。Report: "Already in isolated workspace at `<path>` on branch `<name>`." |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Externally managed worktree（例如 Codex App sandbox） | Skip to Step 3。Report: "Already in isolated workspace at `<path>` (detached HEAD, externally managed)." |

Step 0 不关心谁创建了 worktree，也不关心正在运行哪个 harness。无论 origin 如何，worktree 就是 worktree。

**Submodule guard:** `GIT_DIR != GIT_COMMON` 在 git submodules 中也为 true。在得出 “already in a worktree” 结论前，检查我们不是位于 submodule 中：

```bash
# If this returns a path, we're in a submodule, not a worktree
git rev-parse --show-superproject-working-tree 2>/dev/null
```

如果位于 submodule，将其视作 `GIT_DIR == GIT_COMMON`（继续 Step 0.5）。

#### Step 0.5: Consent

当 Step 0 未发现 existing isolation（`GIT_DIR == GIT_COMMON`）时，创建前询问：

> "Would you like me to set up an isolated worktree? This protects your current branch from changes. (y/n)"

如果 yes，继续 Step 1。如果 no，就 in place 工作：跳到 Step 3，不创建 worktree。

当 Step 0 检测到 existing isolation 时，完全跳过此步骤（没必要询问已经存在的东西）。

#### Step 1a: Native Tools (preferred)

> The user has asked for an isolated workspace (Step 0 consent). Check your available tools — do you have `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag? If YES: the user's consent to create a worktree is your authorization to use it. Use it now and skip to Step 3.

使用 native tool 后，跳到 Step 3（project setup）。

**Design note — TDD revision:** 原 spec 使用刻意简短、抽象的 Step 1a（“You know your own toolkit — the skill does not need to name specific tools”）。TDD validation 否定了它：agents 锚定 Step 1b 的 concrete git commands，并忽略抽象 guidance（2/6 pass rate）。三个变化修复了问题（GREEN 和 PRESSURE tests 中 50/50 pass rate）：

1. **Explicit tool naming**：列出 `EnterWorktree`、`WorktreeCreate`、`/worktree`、`--worktree` 名称，把 decision 从解释（“do I have a native tool?”）变成事实查找（“is `EnterWorktree` in my tool list?”）。没有这些 tools 的 platforms 上，agents 会检查、找不到并 fall through 到 Step 1b。未观察到 false positives。
2. **Consent bridge**：“the user's consent to create a worktree is your authorization to use it” 直接回应 `EnterWorktree` 的 tool-level guardrail（“ONLY when user explicitly asks”）。Tool descriptions override skill instructions（Claude Code #29950），因此 skill 必须把 user consent frame 成该 tool 所需的 authorization。
3. **Red Flag entry**：在 Red Flags section 明确命名具体 anti-pattern（“Use `git worktree add` when you have a native worktree tool — this is the #1 mistake”）。

File splitting（把 Step 1b 放到单独 skill）已测试并证明不需要。Anchoring problem 由 Step 1a text 的质量解决，而不是由 git commands 的物理分离解决。带完整 240-line skill（所有 git commands 可见）的 control tests 20/20 通过。

#### Step 1b: Git Worktree Fallback

没有 native tool 时，手动创建 worktree。

**Directory selection**（priority order）：
1. 检查现有 `.worktrees/` 或 `worktrees/` directory：若存在则使用。若二者都存在，`.worktrees/` 优先。
2. 检查现有 `~/.config/superpowers/worktrees/<project>/` directory：若存在则使用（保持 legacy global path 的 backward compatibility）。
3. 检查项目的 agent instruction file（CLAUDE.md、GEMINI.md、AGENTS.md、.cursorrules 或 equivalent），查看 worktree directory preference。
4. 默认使用 `.worktrees/`。

不再使用 interactive directory selection prompt。global path（`~/.config/superpowers/worktrees/`）不再作为选项提供给 new users，但会检测并使用该位置已有 worktrees，以保持 backward compatibility。

**Safety verification**（仅 project-local directories）：

```bash
git check-ignore -q .worktrees 2>/dev/null
```

如果没有 ignored，在继续前添加到 `.gitignore` 并 commit。

**Create:**

```bash
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Hooks awareness:** Git worktrees 不继承 parent repo 的 hooks directory。通过 1b 创建 worktree 后，如果 main repo 中存在 hooks directory，则 symlink 它：

```bash
if [ -d "$MAIN_ROOT/.git/hooks" ]; then
    ln -sf "$MAIN_ROOT/.git/hooks" "$path/.git/hooks"
fi
```

这能防止 pre-commit checks、linters 和其他 hooks 在工作移到 worktree 后 silent stop。（Idea from PR #965。）

**Sandbox fallback:** 如果 `git worktree add` 因 permission error 失败，将其视作 restricted environment。跳过 creation，在 current directory 工作，并继续 Step 3。

**Step numbering note:** 当前 skill 使用 Steps 1-4 的 flat list。此 redesign 使用 0、0.5、1a、1b、3、4。没有 Step 2，因为它是旧的 monolithic “Create Isolated Workspace”，现在拆成 1a/1b 结构。Implementation 应 cleanly renumber（例如 0 → “Step 0: Detect”，0.5 → Step 0 flow 内，1a/1b → “Step 1”，3 → “Step 2”，4 → “Step 3”），或保留当前 numbering 并加 note。由 implementer 决定。

#### Steps 3-4: Project Setup and Baseline Tests（unchanged）

无论 workspace 由哪条 path 创建（Step 0 detected existing、Step 1a native tool、Step 1b git fallback，或根本没有 worktree），execution 都 converge：

- **Step 3:** Auto-detect 并运行 project setup（`npm install`、`cargo build`、`pip install`、`go mod download` 等）
- **Step 4:** 运行 test suite。如果 tests fail，报告 failures 并询问是否继续。

### 2. `finishing-a-development-branch` SKILL.md Rewrite

finishing skill 增加 environment detection，并修复三个 bugs。

#### Step 1: Verify Tests（unchanged）

运行项目 test suite。如果 tests fail，停止。不要提供 completion options。

#### Step 1.5: Detect Environment（new）

重新运行 creation 中 Step 0 的相同 detection：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

三条 paths：

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON`（normal repo） | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based（见 Step 5） |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced menu：push as new branch + PR、keep as-is、discard | No merge options（can't merge from detached HEAD） |

#### Step 2: Determine Base Branch（unchanged）

#### Step 3: Present Options

**Normal repo and named-branch worktree:**

1. Merge back to `<base-branch>` locally
2. Push and create a Pull Request
3. Keep the branch as-is（I'll handle it later）
4. Discard this work

**Detached HEAD:**

1. Push as new branch and create a Pull Request
2. Keep as-is（I'll handle it later）
3. Discard this work

#### Step 4: Execute Choice

**Option 1（Merge locally）:**

```bash
# Get main repo root for CWD safety (Bug #238 fix)
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first, verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>
<run tests>

# Only after merge succeeds: remove worktree, then delete branch (Bug #999 fix)
git worktree remove "$WORKTREE_PATH"  # only if superpowers owns it
git branch -d <feature-branch>
```

顺序至关重要：merge → verify → remove worktree → delete branch。旧 skill 在 remove worktree 前删除 branch（会失败，因为 worktree 仍引用该 branch）。天真的修复是先 remove worktree，这也不对：如果 merge 随后失败，working directory 已消失，changes 会丢失。

**Option 2（Create PR）:**

Push branch，create PR。不要 clean up worktree：用户需要它做 PR iteration。（Bug #940 fix：移除矛盾的 “Then: Cleanup worktree” prose。）

**Option 3（Keep as-is）:** No action。

**Option 4（Discard）:** 要求 typed “discard” confirmation。然后 remove worktree（如果 superpowers owns it），force-delete branch。

#### Step 5: Cleanup（updated）

```
if GIT_DIR == GIT_COMMON:
    # Normal repo, no worktree to clean up
    done

if worktree path is under .worktrees/ or ~/.config/superpowers/worktrees/:
    # Superpowers created it — we own cleanup
    cd to main repo root       # Bug #238 fix
    git worktree remove <path>

else:
    # Harness created it — hands off
    # If platform provides a workspace-exit tool, use it
    # Otherwise, leave the worktree in place
```

Cleanup 只为 Options 1 和 4 运行。Options 2 和 3 始终保留 worktree。（Bug #940 fix。）

**Stale worktree pruning:** 每次 `git worktree remove` 后，运行 `git worktree prune` 作为 self-healing step。Worktree directories 可能 out-of-band 被删除（例如 harness cleanup、manual `rm` 或 `.claude/` cleanup），留下 stale registrations 并造成 confusing errors。一行命令即可防止 silent rot。（Idea from PR #1072。）

### 3. Integration Updates

#### `subagent-driven-development` and `executing-plans`

二者目前在 integration sections 中把 `using-git-worktrees` 列为 REQUIRED。改为：

> `using-git-worktrees` — Ensures isolated workspace (creates one or verifies existing)

skill 自身现在处理 consent（Step 0.5）和 detection（Step 0），所以 calling skills 不需要 gate 或 prompt。

#### `writing-plans`

移除过期说法 “should be run in a dedicated worktree (created by brainstorming skill)”。Brainstorming 是 design skill，不创建 worktrees。worktree prompt 在 execution time 通过 `using-git-worktrees` 发生。

### 4. Platform-Neutral Instruction File References

所有 worktree-related skills 中 hardcoded `CLAUDE.md` instances 都替换为：

> "your project's agent instruction file (CLAUDE.md, GEMINI.md, AGENTS.md, .cursorrules, or equivalent)"

这适用于 Step 1b 中的 directory preference checks。

## Bug Fixes（bundled）

| Bug | Problem | Fix | Location |
|-----|---------|-----|----------|
| #940 | Option 2 prose says "Then: Cleanup worktree (Step 5)" but quick reference says keep it. Step 5 says "For Options 1, 2, 4" but Common Mistakes says "Options 1 and 4 only." | Remove cleanup from Option 2. Step 5 applies to Options 1 and 4 only. | finishing SKILL.md |
| #999 | Option 1 deletes branch before removing worktree. `git branch -d` can fail because worktree still references the branch. | Reorder to: merge → verify tests → remove worktree → delete branch. Merge must succeed before anything is removed. | finishing SKILL.md |
| #238 | `git worktree remove` fails silently if CWD is inside the worktree being removed. | Add CWD guard: `cd` to main repo root before `git worktree remove`. | finishing SKILL.md |

## Issues Resolved

| Issue | Resolution |
|-------|-----------|
| #940 | Direct fix（Bug #940） |
| #991 | Opt-in consent in Step 0.5 |
| #918 | Step 0 detection + Step 1.5 finishing detection |
| #1009 | Resolved by Step 1a：agents use native tools（例如 `EnterWorktree`），这些 tools 会在 harness-native paths 创建。依赖 Step 1a 有效；见 Risks。 |
| #999 | Direct fix（Bug #999） |
| #238 | Direct fix（Bug #238） |
| #1049 | Platform-neutral instruction file references |
| #279 | Solved by detect-and-defer：native paths 得到尊重，因为我们不 override 它们 |
| #574 | **Deferred.** 本 spec 不触及 bug 所在的 brainstorming skill。完整修复（向 brainstorming checklist 添加 worktree step）属于 Phase 4。 |

## Risks

### Step 1a is the load-bearing assumption — RESOLVED

Step 1a，也就是 agents 优先使用 native worktree tools 而不是 git fallback，是整个 design 的基础。如果 agents 忽略 Step 1a，并在有 native support 的 harnesses 上 fall through 到 Step 1b，detect-and-defer 就完全失败。

**Status:** implementation 期间该风险确实出现。原先抽象的 Step 1a（“You know your own toolkit”）在 Claude Code 上 2/6 失败。TDD gate 按预期工作：它在任何 skill files 被修改前捕获 failure，防止发布 broken release。三轮 REFACTOR iterations 找到 root causes（agent anchoring on concrete commands、tool-description guardrail overriding skill instructions），并产生了在 GREEN 和 PRESSURE tests 中 50/50 验证通过的修复。细节见上方 Step 1a design note。

**Cross-platform validation:**

截至 2026-04-06，Claude Code 是唯一拥有 agent-callable mid-session worktree tool（`EnterWorktree`）的 harness。其他 harnesses 要么在 agent 启动前创建 worktrees（Codex App、Gemini CLI、Cursor），要么没有 native worktree support（Codex CLI、OpenCode）。Step 1a 是 forward-compatible 的：当其他 harnesses 增加 agent-callable worktree tools 时，agents 会将其与 named examples 匹配，并无需修改 skill 即可使用。

| Harness | Current worktree model | Skill mechanism | Tested |
|---------|----------------------|-----------------|--------|
| Claude Code | Agent-callable `EnterWorktree` | Step 1a | 50/50（GREEN + PRESSURE） |
| Codex CLI | No native tool（shell only） | Step 1b git fallback | 6/6（`codex exec`） |
| Gemini CLI | Launch-time `--worktree` flag, no agent tool | Step 0 if launched with flag, Step 1b if not | Step 0: 1/1, Step 1b: 1/1（`gemini -p`） |
| Cursor Agent | User-facing `/worktree`, no agent tool | Step 0 if user activated, Step 1b if not | Step 0: 1/1, Step 1b: 1/1（`cursor-agent -p`） |
| Codex App | Platform-managed, detached HEAD, no agent tool | Step 0 detects existing | 1/1 simulated |
| OpenCode | Detection only（`ctx.worktree`）, no agent tool | Step 1b git fallback | Untested（no CLI access） |

**Residual risks:**
1. 如果 Anthropic 将 `EnterWorktree` 的 tool description 改得更 restrictive（例如 “Do not use based on skill instructions”），consent bridge 会失效。值得 filing an issue，请求 tool description 适配 skill-driven invocation。
2. 当其他 harnesses 增加 agent-callable worktree tools 时，它们可能使用 Step 1a list 中没有的名称。新 tools 出现时应更新该 list。generic phrasing（“a worktree or workspace-isolation tool”）提供了一定 forward coverage。

### Provenance heuristic

`.worktrees/` 或 `~/.config/superpowers/worktrees/` = ours，anything else = hands off 的 heuristic 适用于所有当前 harness。如果未来某个 harness 采用 `.worktrees/` 作为 convention，会出现 false positive（superpowers 尝试清理 harness-owned worktree）。同样，如果用户手动运行 `git worktree add .worktrees/experiment` 而不通过 superpowers，我们也会错误认领 ownership。二者风险都低：所有 harness 都使用 branded paths，且 manual `.worktrees/` creation 不太常见；但值得记录。

### Detached HEAD finishing

detached HEAD worktrees 的 reduced menu（无 merge option）符合 Codex App sandbox model。如果用户出于其他原因位于 detached HEAD，reduced menu 仍然合理：不先创建 branch，确实无法从 detached HEAD merge。

## Implementation Notes

两个 skill files 都包含 core steps 之外的 sections，implementation 期间也需要更新：

- **Frontmatter**（`name`、`description`）：更新以反映 detect-and-defer behavior
- **Quick Reference tables**：重写以匹配新 step structure 和 bug fixes
- **Common Mistakes sections**：更新或移除引用旧 behavior 的 items（例如 “Skip CLAUDE.md check” 现在是错的）
- **Red Flags sections**：更新以反映新 priorities（例如 “Never create a worktree when Step 0 detects existing isolation”）
- **Integration sections**：更新 skills 之间的 cross-references

spec 描述 *what changes*；implementation plan 会指定这些 secondary sections 的 exact edits。

## Future Work（not in this spec）

- **Phase 3 remainder:** `$TMPDIR` directory option (#666)、setup docs for caching and env inheritance (#299)
- **Phase 4:** PreToolUse hooks for path enforcement (#1040)、per-worktree env conventions (#597)、brainstorming checklist worktree step (#574)、multi-repo documentation (#710)
