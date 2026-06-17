# Worktree Rototill: Detect-and-Defer

**Date:** 2026-04-06
**Status:** Draft
**Ticket:** PRI-974
**包含：** PRI-823（Codex 应用程序兼容性）

## Problem

Superpowers 对工作树管理有自己的看法——特定路径 (`.worktrees/<branch>`)、特定命令 (`git worktree add`)、特定清理 (`git worktree remove`)。同时，Claude Code、Codex App、Gemini CLI 和 Cursor 都提供本机工作树支持以及自己的路径、生命周期管理和清理。

这会产生三种故障模式：

1. **重复** — 在 Claude Code 上，该技能执行 `EnterWorktree`/`ExitWorktree` 已经执行的操作
2. **冲突** - 在 Codex App 上，该技能尝试在已管理的工作树内创建工作树
3. **幻象状态** — 在 `.worktrees/` 处创建的技能工作树对于线束来说是不可见的；在 `.claude/worktrees/` 处由线束创建的工作树对于技能来说是不可见的

对于没有本机支持（Codex CLI、OpenCode、Copilot 独立）的线束，超级功能填补了真正的空白。这项技能不应该消失——当存在本机支持时它应该消失。

## Goals

1. 遵循本机线束工作树系统（如果存在）
2. 继续为缺乏工作树的线束提供工作树支持
3. 修复 Finishing-a-development-branch 中的三个已知错误（#940、#999、#238）
4. 使工作树创建成为选择加入而不是强制性的（#991）
5. 用平台中立语言替换硬编码的 `CLAUDE.md` 引用 (#1049)

## Non-Goals

- 每个工作树环境约定（`.worktree-env.sh`，端口偏移）— 第 4 阶段
- PreToolUse 挂钩进行路径实施 — 第 4 阶段
- 多存储库工作树文档 - 第 4 阶段
- 工作树集思广益清单变更 — 第 4 阶段
- `.superpowers-session.json` 元数据跟踪（有趣的 PR #997 想法，v1 不需要）
- 将符号链接挂钩到工作树中（PR #965 想法，单独关注）

## Design Principles

### 检测状态，而不是平台

使用 `GIT_DIR != GIT_COMMON` 确定"我已经在工作树中了吗？"而不是通过嗅探环境变量来识别线束。这是一个稳定的 git 原语（自 2015 年 git 2.5 起），在所有线束中通用，并且在新线束出现时需要零维护。

### 声明性意图，规定性后备

该技能描述了目标（"确保工作在隔离的工作空间中进行"）并遵循可用的本机工具。它规定特定的 git 命令仅作为没有本机工作树支持的工具的后备。步骤 1a 首先出现并明确命名本机工具（`EnterWorktree`、`WorktreeCreate`、`/worktree`、`--worktree`）；第二步是 git 后备步骤 1b。最初的规范保留了步骤 1a 的抽象性（"你知道你自己的工具包"），但 TDD 证明，当步骤 1a 过于模糊时，代理会锚定在步骤 1b 的具体命令上。为了使偏好可靠，需要显式的工具命名和同意授权桥。

### Provenance-based ownership

创建工作树的人就拥有其清理工作。如果安全带创造了它，那么超能力就不会碰它。如果超级大国创建了它（通过 git 回退），超级大国会清理它。启发式：如果工作树位于 `.worktrees/` 或 `worktrees/` 下，则超级权限拥有它。任何其他内容（`.claude/worktrees/`、`~/.codex/worktrees/`、`.gemini/worktrees/` 或旧的用户全局超级能力路径）都属于线束或用户，无需处理。

## Design

### 1. `using-git-worktrees` SKILL.md 重写

该技能在创建前增加了三个新步骤，并简化了创建流程。

#### Step 0: Detect Existing Isolation

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

Three outcomes:

|状况 |意义|行动|
|-----------|---------|--------|
| `GIT_DIR == GIT_COMMON` |正常回购结帐 |继续步骤 0.5 |
| `GIT_DIR != GIT_COMMON`，命名分支 |已经在链接的工作树中 |跳至步骤 3（项目设置）。报告："已位于分支 `<name>` 的 `<path>` 的隔离工作区中。" |
| `GIT_DIR != GIT_COMMON`，分离头 |外部管理的工作树（例如 Codex App 沙箱）|跳至步骤 3。报告："已位于 `<path>` 的隔离工作区中（分离的 HEAD，外部管理）。" |

步骤 0 不关心谁创建了工作树或哪个线束正在运行。工作树就是工作树，无论其来源如何。

**子模块保护：** `GIT_DIR != GIT_COMMON` 在 git 子模块中也是如此。在得出"已在工作树中"的结论之前，请检查我们是否不在子模块中：

```bash
# If this returns a path, we're in a submodule, not a worktree
git rev-parse --show-superproject-working-tree 2>/dev/null
```

如果在子模块中，则视为 `GIT_DIR == GIT_COMMON`（继续步骤 0.5）。

#### Step 0.5: Consent

当步骤 0 发现不存在现有隔离 (`GIT_DIR == GIT_COMMON`) 时，在创建之前询问：

> "您希望我建立一个独立的工作树吗？这可以保护您当前的分支免受更改。(y/n)"

如果是，则继续执行步骤 1。如果否，则就地工作 — 跳至步骤 3，无需工作树。

当步骤 0 检测到现有隔离时，将完全跳过此步骤（无需询问已存在的隔离）。

#### 步骤 1a：本机工具（首选）

> 用户已请求隔离工作区（第 0 步同意）。检查您可用的工具 - 您是否有 `EnterWorktree`、`WorktreeCreate`、`/worktree` 命令或 `--worktree` 标志？如果是：用户同意创建工作树即表示您授权您使用它。现在使用它并跳到步骤 3。

使用本机工具后，跳至步骤 3（项目设置）。

**设计说明 - TDD 修订版：** 原始规范故意使用了简短、抽象的步骤 1a（"您知道自己的工具包 - 该技能不需要命名特定的工具"）。 TDD 验证反驳了这一点：代理锚定在步骤 1b 的具体 git 命令上，而忽略了抽象指导（2/6 通过率）。三个更改修复了该问题（绿色和压力测试的通过率为 50/50）：

1. **显式工具命名** - 按名称列出 `EnterWorktree`、`WorktreeCreate`、`/worktree`、`--worktree` 将决策从解释（"我有本机工具吗？"）转换为事实查找（"`EnterWorktree` 在我的工具列表中吗？"）。没有这些工具的平台上的代理只需进行检查，什么也找不到，然后进入步骤 1b。没有观察到误报。
2. **同意桥** - "用户同意创建工作树就是您授权使用它"直接解决`EnterWorktree`的工具级护栏（"仅当用户明确要求时"）。工具描述优先于技能说明（Claude Code #29950），因此技能必须将用户同意作为工具所需的授权。
3. **危险信号条目** — 在危险信号部分中命名特定的反模式（"当您有本机工作树工具时使用 `git worktree add` — 这是第一个错误"）。

文件分割（单独技能中的步骤 1b）经过测试并证明是不必要的。锚定问题是通过步骤 1a 的文本质量来解决的，而不是通过 git 命令的物理分离来解决。具有完整 240 行技能的控制测试（所有 git 命令可见）通过了 20/20.

#### Step 1b: Git Worktree Fallback

当没有可用的本机工具时，请手动创建工作树。

**目录选择**（优先顺序）：
1. 检查项目的代理指令文件（CLAUDE.md、GEMINI.md、AGENTS.md、.cursorrules 或等效文件）以获取工作树目录首选项。
2. 检查现有的 `.worktrees/` 或 `worktrees/` 目录 - 如果找到，则使用它。如果两者都存在，则 `.worktrees/` 获胜。
3. 默认为`.worktrees/`。

没有交互式目录选择提示。未检测或提供旧的用户全局 Superpowers 工作树路径；新的手动工作树是项目本地的，除非用户明确指定另一个位置。

**安全验证**（仅限项目本地目录）：

```bash
git check-ignore -q .worktrees 2>/dev/null
```

如果不忽略，请添加到 `.gitignore` 并在继续之前提交。

**Create:**

```bash
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Hooks 意识：** Git 工作树不会继承父存储库的 hooks 目录。通过 1b 创建工作树后，从主存储库中符号链接 hooks 目录（如果存在）：

```bash
if [ -d "$MAIN_ROOT/.git/hooks" ]; then
    ln -sf "$MAIN_ROOT/.git/hooks" "$path/.git/hooks"
fi
```

这可以防止预提交检查、linter 和其他钩子在工作移动到工作树时默默停止。 （来自 PR #965 的想法。）

**沙盒后备：** 如果 `git worktree add` 因权限错误而失败，则视为受限环境。跳过创建，在当前目录中工作，继续步骤 3。

**步骤编号说明：** 当前技能将步骤 1-4 作为简单列表。此重新设计使用 0, 0.5, 1a, 1b, 3, 4。没有第 2 步 - 它是旧的整体"创建独立工作空间"，现在被拆分为 1a/1b 结构。实现应该干净地重新编号（例如，0→"步骤0：检测"，0.5→在步骤0的流程中，1a/1b→"步骤1"，3→"步骤2"，4→"步骤3"）或保留当前编号并附上注释。实施者的选择。

#### 步骤 3-4：项目设置和基线测试（不变）

无论使用哪条路径创建工作区（步骤 0 检测到现有工作区、步骤 1a 本机工具、步骤 1b git 回退或根本没有工作树），执行都会收敛：

- **第 3 步：** 自动检测并运行项目设置（`npm install`、`cargo build`、`pip install`、`go mod download` 等）
- **第 4 步：** 运行测试套件。如果测试失败，报告失败并询问是否继续。

### 2. `finishing-a-development-branch` SKILL.md 重写

终结技能获得环境检测并修复了三个错误。

#### 第 1 步：验证测试（不变）

运行项目的测试套件。如果测试失败，请停止。不提供完成选项。

#### 步骤1.5：检测环境（新）

重新运行与创建中步骤 0 相同的检测：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

Three paths:

|状态|菜单|清理 |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON`（普通仓库）|标准 4 选项 |没有需要清理的工作树 |
| `GIT_DIR != GIT_COMMON`，命名分支 |标准 4 选项 |基于出处（参见步骤 5）|
| `GIT_DIR != GIT_COMMON`，分离头 |简化菜单：作为新分支推送 + PR，保持原样，丢弃 |没有合并选项（无法从分离的 HEAD 合并）|

#### 步骤2：确定基础分支（不变）

#### Step 3: Present Options

**普通仓库和命名分支工作树：**

1. 合并回本地`<base-branch>`
2. 推送并创建拉取请求
3. 保持分支不变（我稍后会处理）
4. 放弃这个工作

**Detached HEAD:**

1. 作为新分支推送并创建拉取请求
2. 保持原样（稍后我会处理）
3. 放弃这个工作

#### Step 4: Execute Choice

**选项 1（本地合并）：**

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

顺序很关键：合并→验证→删除工作树→删除分支。旧技能在删除工作树之前删除了分支（这会失败，因为工作树仍然引用分支）。首先删除工作树的天真修复也是错误的——如果合并失败，工作目录就会消失，更改也会丢失。

**选项 2（创建 PR）：**

推送分支，创建 PR。不要清理工作树——用户需要它来进行 PR 迭代。 （错误#940修复：删除矛盾的"然后：清理工作树"散文。）

**选项 3（保持原样）：** 不执行任何操作。

**选项 4（丢弃）：** 需要键入"丢弃"确认。然后删除工作树（如果超级大国拥有它），强制删除分支。

#### 第 5 步：清理（已更新）

```
if GIT_DIR == GIT_COMMON:
    # Normal repo, no worktree to clean up
    done

if worktree path is under .worktrees/ or worktrees/:
    # Superpowers created it — we own cleanup
    cd to main repo root       # Bug #238 fix
    git worktree remove <path>

else:
    # Harness created it — hands off
    # If platform provides a workspace-exit tool, use it
    # Otherwise, leave the worktree in place
```

清理仅针对选项 1 和 4 运行。选项 2 和 3 始终保留工作树。 （错误#940 修复。）

**陈旧工作树修剪：** 在任何 `git worktree remove` 之后，运行 `git worktree prune` 作为自我修复步骤。工作树目录可能会被带外删除（例如，通过线束清理、手动`rm`或`.claude/`清理），留下陈旧的注册，从而导致混乱的错误。一根线，防止无声腐烂。 （来自 PR #1072 的想法。）

### 3. Integration Updates

#### `subagent-driven-development` 和 `executing-plans`

目前，两者都在其集成部分中将 `using-git-worktrees` 列为必需。更改为：

> `using-git-worktrees` — 确保隔离工作区（创建一个或验证现有工作区）

该技能本身现在可以处理同意（步骤 0.5）和检测（步骤 0），因此调用技能不需要门控或提示。

#### `writing-plans`

删除陈旧的主张"应该在专用工作树中运行（通过头脑风暴技能创建）"。头脑风暴是一种设计技能，不会创建工作树。工作树提示在执行时通过 `using-git-worktrees` 发生。

### 4. Platform-Neutral Instruction File References

工作树相关技能中所有硬编码的 `CLAUDE.md` 实例均替换为：

> "您项目的代理指令文件（CLAUDE.md、GEMINI.md、AGENTS.md、.cursorrules 或同等文件）"

这适用于步骤 1b 中的目录首选项检查。

## 错误修复（捆绑）

|错误 |问题 |修复|地点 |
|-----|---------|-----|----------|
|第940章选项 2 的散文说"然后：清理工作树（步骤 5）"，但快速参考说保留它。第 5 步显示"对于选项 1、2、4"，但常见错误显示"仅限选项 1 和 4"。 |从选项 2 中删除清理。步骤 5 仅适用于选项 1 和 4。 |正在整理SKILL.md |
|第999章选项 1 在删除工作树之前删除分支。 `git branch -d` 可能会失败，因为工作树仍然引用分支。 |重新排序为：合并→验证测试→删除工作树→删除分支。在删除任何内容之前，合并必须成功。 |正在整理SKILL.md |
|第238章如果 CWD 位于要删除的工作树内，则 `git worktree remove` 会静默失败。 |将 CWD 防护：`cd` 添加到主存储库根目录 `git worktree remove` 之前。 |正在整理SKILL.md |

## Issues Resolved

|问题 |分辨率|
|-------|-----------|
|第940章直接修复（错误#940）|
|第991章在步骤 0.5 中选择同意 |
|第918章步骤0检测+步骤1.5完成检测|
|第1009章通过步骤 1a 解决 - 代理使用在harness-native 路径上创建的本机工具（例如，`EnterWorktree`）。取决于步骤 1a 的工作情况；请参阅风险。 |
|第999章直接修复（错误#999）|
|第238章直接修复（错误#238）|
|第1049章平台中立指令文件参考 |
|第279章通过检测和延迟解决 - 尊重本机路径，因为我们不覆盖它们 |
|第574章**推迟。** 本规范中没有任何内容涉及 bug 所在的头脑风暴技能。全面修复（将工作树步骤添加到头脑风暴的清单中）是第 4 阶段。

## Risks

### 步骤 1a 是承载假设 — 已解决

步骤 1a——代理更喜欢本地工作树工具而不是 git 后备——是整个设计的基础。如果代理忽略步骤 1a 并在具有本机支持的线束上执行步骤 1b，则检测和延迟将完全失败。

**状态：** 此风险在实施过程中出现。最初的摘要步骤 1a（"你知道你自己的工具包"）在 Claude Code 上的 2/6 处失败。 TDD 门按设计工作——它在修改任何技能文件之前捕获故障，从而防止发布失败。三次 REFACTOR 迭代确定了根本原因（代理锚定具体命令、工具描述护栏覆盖技能指令），并生成了在 GREEN 和 PRESSURE 测试中以 50/50 进行验证的修复程序。有关详细信息，请参阅上面的步骤 1a 设计说明。

**Cross-platform validation:**

截至 2026 年 4 月 6 日，Claude Code 是唯一具有代理可调用的会话中工作树工具 (`EnterWorktree`) 的工具。所有其他人要么在代理启动之前创建工作树（Codex App、Gemini CLI、Cursor），要么没有本机工作树支持（Codex CLI、OpenCode）。步骤 1a 是向前兼容的：当其他工具添加代理可调用的工作树工具时，代理会将它们与命名示例进行匹配，并在无需更改技能的情况下使用它们。

|线束|当前工作树模型 |技能机制|已测试 |
|---------|----------------------|-----------------|--------|
|克劳德·代码 |代理可调用 `EnterWorktree` |步骤 1a | 50/50（绿色+压力）|
|法典 CLI |没有本机工具（仅限 shell） |步骤 1b git 后备 | 6/6 (`codex exec`) |
|双子座 CLI |启动时 `--worktree` 标志，无代理工具 |如果使用标志启动则执行步骤 0，否则执行步骤 1b |步骤 0：1/1，步骤 1b：1/1 (`gemini -p`) |
|光标代理|面向用户`/worktree`，无代理工具|如果用户激活则执行步骤 0，如果未激活则执行步骤 1b |步骤 0：1/1，步骤 1b：1/1 (`cursor-agent -p`) |
|法典应用程序 |平台管理、独立HEAD、无代理工具|步骤 0 检测现有 | 1/1 模拟 |
|开放代码 |仅检测（`ctx.worktree`），无代理工具 |步骤 1b git 后备 |未经测试（无 CLI 访问）|

**Residual risks:**
1. 如果 Anthropic 将 `EnterWorktree` 的工具描述更改为更具限制性（例如，"请勿根据技能说明使用"），则同意桥会中断。值得提出一个问题，要求工具描述适应技能驱动的调用。
2. 当其他工具添加代理可调用工作树工具时，它们可能会使用步骤 1a 列表中没有的名称。该列表应随着新工具的出现而更新。通用措辞（"工作树或工作区隔离工具"）提供了一些前瞻性的覆盖。

### Provenance heuristic

`.worktrees/` 或 `worktrees/` = 我们的，其他任何东西 = 放手 ` heuristic works for every current harness. If a future harness adopts one of those project-local directories as its convention, we'd have a false positive (superpowers tries to clean up a harness-owned worktree). Similarly, if a user manually runs `git worktree add .worktrees/experiment` without superpowers, we'd incorrectly claim ownership. Both are low risk — every harness uses branded paths, and manual `.worktrees/` 创建不太可能 - 但值得注意。

### Detached HEAD finishing

分离 HEAD 工作树的简化菜单（无合并选项）对于 Codex App 的沙箱模型是正确的。如果用户由于其他原因处于分离的 HEAD 中，则简化的菜单仍然有意义 - 如果不先创建分支，您确实无法从分离的 HEAD 进行合并。

## Implementation Notes

这两个技能文件都包含在实施过程中需要更新的核心步骤之外的部分：

- **Frontmatter** (`name`, `description`)：更新以反映检测和延迟行为
- **快速参考表**：重写以匹配新的步骤结构和错误修复
- **常见错误部分**：更新或删除引用旧行为的项目（例如，"跳过 CLAUDE.md 检查"现在是错误的）
- **危险信号部分**：更新以反映新的优先级（例如，"当步骤 0 检测到现有隔离时切勿创建工作树"）
- **集成部分**：更新技能之间的交叉引用

规范描述了*发生了什么变化*；实施计划将具体说明对这些次要部分的具体编辑。

## 未来的工作（不在本规范中）

- **第 3 阶段剩余部分：** `$TMPDIR` 目录选项 (#666)，用于缓存和环境继承的设置文档 (#299)
- **阶段 4：** PreToolUse 挂钩用于路径强制 (#1040)、每个工作树环境约定 (#597)、集思广益清单工作树步骤 (#574)、多存储库文档 (#710)
