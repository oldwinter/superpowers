# Superpowers Release Notes

## v5.1.0 (2026-04-30)

### 移除

- **移除旧 slash commands**：`/brainstorm`、`/execute-plan` 和 `/write-plan` 已移除。它们原本是 deprecated stubs，只会提示用户调用对应 skill。请直接调用 `superpowers:brainstorming`、`superpowers:executing-plans` 和 `superpowers:writing-plans`。(#1188)
- **移除 `superpowers:code-reviewer` named agent**：该 agent 是 plugin 中唯一的 named agent，并且只被两个 skills 使用；而仓库中其他 reviewer/implementer subagent 都是在其 skill 旁边通过 prompt template dispatch `general-purpose`。该 agent 的 persona 和 checklist 已合并进 `skills/requesting-code-review/code-reviewer.md`，作为自包含的 Task dispatch template。任何 dispatch `Task (superpowers:code-reviewer)` 的地方都应改为使用 prompt template dispatch `Task (general-purpose)`。(PR #1299)
- **从 skills 中移除 Integration sections**：这些 sections 是 agents 尚未具备 native skills systems 之前的遗留内容，对 steering 已无帮助。

### Worktree Skills 重写

`using-git-worktrees` 和 `finishing-a-development-branch` 现在会检测 agent 是否已经运行在隔离 worktree 中，并在 fallback 到 `git worktree` 前优先使用 harness native worktree controls。该行为已通过 TDD 验证，并在五种 harness 上完成跨平台检查。(PRI-974, PR #1121)

- **Environment detection**：两个 skills 在做任何事前都会检查 `GIT_DIR != GIT_COMMON`；如果已经位于 linked worktree 中，就完全跳过创建。submodule guard 可防止误判。
- **创建 worktrees 前征得同意**：`using-git-worktrees` 不再隐式创建 worktrees；skill 会先询问用户。修复 #991（subagent-driven-development 未经同意自动创建 worktrees）。
- **Native tool preference (Step 1a)**：当 harness 暴露自己的 worktree tool（例如 Codex）时，skill 会交给它处理。若用户表达了偏好，会尊重该偏好。
- **基于 provenance 的 cleanup**：`finishing-a-development-branch` 只清理 `.worktrees/` 内的 worktrees（由 superpowers 创建）；外部内容保持不动。修复 #940（Option 2 错误清理 worktrees）、#999（merge-then-remove 顺序）和 #238（`git worktree remove` 前先 `cd` 到 repo root）。
- **Detached HEAD handling**：当没有可 merge 的 branch 时，finishing menu 会收缩为两个 options。
- skill 示例中的硬编码 `/Users/jesse` paths 已替换为通用 placeholders。(#858, PR #1122)

### 面向 AI Agents 的 Contributor Guidelines

`CLAUDE.md` 顶部新增两个直接面向 AI agents 的 sections（symlink 到 `AGENTS.md`）。对本 repo 最近 100 个 closed PR 的 audit 显示，AI-generated slop 导致了 94% rejection rate：agents 没读 PR template、提交重复 PR、编造 problem descriptions，或把 fork/domain-specific changes 推到 upstream。

- **Pre-submission checklist**：阅读 PR template，搜索已有 PR，验证真实问题存在，确认 change 属于 core，并在提交前向 human partner 展示完整 diff。
- **我们不会接受的内容**：third-party dependencies、skill content 的“compliance” rewrites、project-specific configuration、bulk PRs、speculative fixes、domain-specific skills、fork-specific changes、fabricated content 和 bundled unrelated changes。
- **新 harness PR 需要 session transcript**：过去多数 new-harness integrations 只是复制 skill files，或用 `npx skills` 包一层，而不是在 session start 加载 `using-superpowers` bootstrap。现在要求 acceptance test（在干净 session 中，“Let's make a react todo list” 必须自动触发 `brainstorming`）以及完整 transcript。

### Codex Plugin Mirror Tooling

新增 `sync-to-codex-plugin` script，用于把 superpowers mirror 到 OpenAI Codex plugin marketplace，目标为 `prime-radiant-inc/openai-codex-plugins`。该脚本与 path/user 无关，因此任意团队成员都能运行。(PR #1165)

- 每次运行都 fresh clone fork 到 temp directory，inline 重新生成 overlays，并打开 PR；从脚本自身位置 auto-detect upstream，并预检 `rsync`/`git`/`gh auth`/`python3`。
- 首次设置使用 `--bootstrap` flag；`EXCLUDES` patterns anchored 到 source root；排除 `assets/`。
- Mirror `CODE_OF_CONDUCT.md`；移除 `agents/openai.yaml` overlay。
- 在 mirrored `plugin.json` 中 seed `interface.defaultPrompt`。(PR #1180 by @arittr)
- Codex plugin files 已提交进 source repo，因此 sync script 使用 canonical versions；Codex marketplace metadata 会保留。

### OpenCode

- **Bootstrap content cached at module level**：`getBootstrapContent()` 过去会在每个 agent step 上调用 `fs.existsSync` + `fs.readFileSync` + frontmatter regex（OpenCode 的 agent loop 每步都会触发 `experimental.chat.messages.transform` hook）。现在每个 session lifetime 只读取一次并缓存；缺文件时使用 null sentinel。15 个 regression tests 覆盖 cache behavior、fs call counts、injection guard、missing-file sentinel 和 cache reset。(Fixes #1202)
- **Integration tests modernized**。
- **README 中 clarified install caveats**。

### Code Review Consolidation

`requesting-code-review` 现在自包含：persona、checklist 和 dispatch template 都位于 `skills/requesting-code-review/code-reviewer.md`，skill 直接 dispatch `Task (general-purpose)`。(PR #1299)

- **Single source of truth**：之前同时存在于 `agents/code-reviewer.md` 和 skill placeholder template 中、且各自 drift 的 persona/checklist，现在合并为一个文件。
- **`subagent-driven-development` 同步跟进**：其 `code-quality-reviewer-prompt.md` 现在 dispatch `Task (general-purpose)`，不再使用 named agent。
- **新增 behavioral test**：`tests/claude-code/test-requesting-code-review.sh` 在小型项目中植入真实 bugs（SQL injection、plaintext password handling、credential logging），并断言 dispatched reviewer 以 Critical/Important severity 标记每个植入问题，且拒绝 approve diff。
- **精简 Codex 和 Copilot workaround docs**：`references/codex-tools.md` 和 `references/copilot-tools.md` 中的 “Named agent dispatch” sections 原本说明如何把 named agent flatten 成 generic dispatch。现在不再 shipping named agents，该 workaround 已无必要，因此两个 sections 均已删除。

### Subagent-Driven Development

- **不再每 3 个 tasks 暂停**：`requesting-code-review` 中 “review after each batch (3 tasks)” 的 cadence（原本用于 `executing-plans`）泄漏到了 `subagent-driven-development`。已替换为 “each task or at natural checkpoints”，并加入显式 continuous-execution directive。
- **SDD integration test 现在会运行 assertions**：三个独立 bugs 曾导致测试在打印任何 verification results 前静默退出：working-dir path 中未解析的 `..` segment、`set -euo pipefail` 与 `find | sort | head -1` 的交互（producer 上 SIGPIPE 终止脚本），以及 `claude -p` 调用缺少 `--plugin-dir`，导致测试加载 installed plugin 而不是 working tree。三者均已修复；现在六个 verification tests 会针对真实 end-to-end SDD run 实际运行。

### Cursor

- **Windows SessionStart hook** 改为通过 `run-hook.cmd` 路由，而不是直接调用 extensionless `session-start` script。修复 Windows 在 editor 中打开文件而不是执行它的问题。同时移除 `hooks-cursor.json` 中意外的 UTF-8 BOM。

### Gemini CLI

- **Subagent dispatch mapping**：Gemini 的 `Task` dispatch 现在映射到 `@agent-name` / `@generalist`，并记录了独立任务的 parallel subagent dispatch。

### Skills

- **Terminology cleanups**：清理 skill content 中的术语。

### Documentation & Install

- README 新增 **Factory Droid installation instructions**。
- README 新增 **Quickstart install links**。(PR #1293 by @arittr)
- 更新 **Codex plugin install guidance**。(PR #1288 by @arittr)
- 修正 Codex `wait` mapping 为 `wait_agent`。
- 重组 install order；清理 Codex install instructions。
- 移除遗留 `CHANGELOG.md`，将 `RELEASE-NOTES.md` 作为 single source。(PR #1163 by @shaanmajid)
- 修复 Discord invite link；Community section 新增 release announcements link 和更详细的 Discord description。

### Community

- @shaanmajid：移除遗留 `CHANGELOG.md` (PR #1163)
- @arittr：README quickstart install links (#1293)、Codex plugin install guidance (#1288)、`sync-to-codex-plugin` `interface.defaultPrompt` seed (#1180)

## v5.0.7 (2026-03-31)

### GitHub Copilot CLI Support

- **SessionStart context injection**：Copilot CLI v1.0.11 增加了 sessionStart hook output 中的 `additionalContext` 支持。session-start hook 现在检测 `COPILOT_CLI` environment variable，并输出 SDK-standard `{ "additionalContext": "..." }` format，让 Copilot CLI users 在 session start 获得完整 superpowers bootstrap。（原始修复由 @culinablaz 在 PR #910 提供）
- **Tool mapping**：新增 `references/copilot-tools.md`，包含完整 Claude Code 到 Copilot CLI 的 tool equivalence table。
- **Skill and README updates**：在 `using-superpowers` skill 的 platform instructions 和 README installation section 中加入 Copilot CLI。

### OpenCode Fixes

- **Skills path consistency**：bootstrap text 不再宣传具有误导性的 `configDir/skills/superpowers/` path，该 path 与 runtime path 不匹配。agent 应使用 native `skill` tool，而不是按 path 导航文件。Tests 现在使用来自 single source of truth 的一致 paths。(#847, #916)
- **Bootstrap as user message**：将 bootstrap injection 从 `experimental.chat.system.transform` 移到 `experimental.chat.messages.transform`，prepend 到第一条 user message，而不是添加 system message。避免每 turn 重复 system messages 造成 token bloat (#750)，并修复 Qwen 等会因多个 system messages 出错的模型兼容性 (#894)。

## v5.0.6 (2026-03-24)

### Inline Self-Review Replaces Subagent Review Loops

subagent review loop（dispatch 一个新 agent 审查 plans/specs）会让执行时间翻倍（约 25 分钟 overhead），但没有可测量地提升 plan quality。跨 5 个版本、每版 5 次 trials 的 regression testing 显示，无论是否运行 review loop，quality scores 都相同。

- **brainstorming**：用 inline Spec Self-Review checklist 替代 Spec Review Loop（subagent dispatch + 3-iteration cap）：placeholder scan、internal consistency、scope check、ambiguity check。
- **writing-plans**：用 inline Self-Review checklist 替代 Plan Review Loop（subagent dispatch + 3-iteration cap）：spec coverage、placeholder scan、type consistency。
- **writing-plans**：新增显式 “No Placeholders” section，定义 plan failures（TBD、vague descriptions、undefined references、“similar to Task N”）。
- Self-review 每次约 30 秒可捕获 3-5 个真实 bugs，而不是约 25 分钟；defect rates 与 subagent approach 相当。

### Brainstorm Server

- **Session directory restructured**：brainstorm server session directory 现在包含两个同级 subdirectories：`content/`（供 browser 服务的 HTML files）和 `state/`（events、server-info、pid、log）。此前 server state 和 user interaction data 与 served content 放在一起，可通过 HTTP 访问。server-started JSON 中同时包含 `screen_dir` 和 `state_dir` paths。（由 吉田仁 报告）

### Bug Fixes

- **Owner-PID lifecycle fixes**：brainstorm server 的 owner-PID monitoring 有两个 bugs，会导致 60 秒内 false shutdowns：(1) cross-user PIDs（Tailscale SSH 等）的 EPERM 被当作 “process dead”，(2) WSL 上 grandparent PID 解析为短生命周期 subprocess，在第一次 lifecycle check 前就退出。修复方式是把 EPERM 视作 “alive”，并在 startup 验证 owner PID；如果它已经死亡，则禁用 monitoring，让 server 依赖 30-minute idle timeout。这也移除了 `start-server.sh` 中 Windows/MSYS2-specific carve-out，因为 server 现在能通用处理。(#879)
- **writing-skills**：修正错误说法，即 SKILL.md frontmatter 只支持 “only two fields”；现在表述为 “two required fields”，并链接到 agentskills.io specification 查看所有 supported fields。(PR #882 by @arittr)

### Codex App Compatibility

- **codex-tools**：新增 named agent dispatch mapping，记录如何把 Claude Code 的 named agent types 转换为 Codex 的 `spawn_agent` with worker roles。(PR #647 by @arittr)
- **codex-tools**：为 worktree-aware skills 新增 environment detection 和 Codex App finishing sections。(by @arittr)
- **Design spec**：新增 Codex App compatibility design spec (PRI-823)，覆盖 read-only environment detection、worktree-safe skill behavior 和 sandbox fallback patterns。(by @arittr)

## v5.0.5 (2026-03-17)

### Bug Fixes

- **Brainstorm server ESM fix**：将 `server.js` 重命名为 `server.cjs`，使 brainstorming server 在 Node.js 22+ 上能正确启动；此前 root `package.json` 的 `"type": "module"` 会导致 `require()` 失败。(PR #784 by @sarbojitrana, fixes #774, #780, #783)
- **Brainstorm owner-PID on Windows**：在 Windows/MSYS2 上跳过 PID lifecycle monitoring，因为 Node.js 看不到 PID namespace，这会导致 server 在 60 秒后 self-terminate。(#770, docs from PR #768 by @lucasyhzlu-debug)
- **stop-server.sh reliability**：在报告 success 前验证 server process 是否真的死亡。SIGTERM + 2s wait + SIGKILL fallback。(#723)

### Changed

- **Execution handoff**：恢复 plan writing 后用户在 subagent-driven 和 inline execution 之间选择的能力。Subagent-driven 推荐使用，但不再强制。

## v5.0.4 (2026-03-16)

### Review Loop Refinements

通过消除不必要的 review passes 并收紧 reviewer focus，显著降低 token usage 并加快 spec/plan reviews。

- **Single whole-plan review**：plan reviewer 现在一次性审查完整 plan，而不是逐 chunk 审查。移除所有 chunk-related concepts（`## Chunk N:` headings、1000-line chunk limits、per-chunk dispatch）。
- **提高 blocking issues 门槛**：spec 和 plan reviewer prompts 现在都包含 “Calibration” section：只标记会在 implementation 中造成真实问题的 issues。轻微措辞、style preferences 和 formatting quibbles 不应阻塞 approval。
- **降低 max review iterations**：spec 和 plan review loops 都从 5 次降至 3 次。如果 reviewer 校准正确，3 轮足够。
- **精简 reviewer checklists**：spec reviewer 从 7 类降至 5 类；plan reviewer 从 7 类降至 4 类。移除 formatting-focused checks（task syntax、chunk size），转而关注 substance（buildability、spec alignment）。

### OpenCode

- **One-line plugin install**：OpenCode plugin 现在通过 `config` hook 自动注册 skills directory。不需要 symlinks 或 `skills.paths` config。Install 只需在 `opencode.json` 中加一行。(PR #753)
- **Added `package.json`**，使 OpenCode 可以从 git 以 npm package 安装 superpowers。

### Bug Fixes

- **Verify server actually stopped**：`stop-server.sh` 现在会在报告 success 前确认 process 已死亡。SIGTERM + 2s wait + SIGKILL fallback。如果 process 存活则报告 failure。(PR #751)
- **Generic agent language**：brainstorm companion waiting page 现在说 “the agent”，不再说 “Claude”。

## v5.0.3 (2026-03-15)

### Cursor Support

- **Cursor hooks**：新增 `hooks/hooks-cursor.json`，使用 Cursor 的 camelCase format（`sessionStart`, `version: 1`），并更新 `.cursor-plugin/plugin.json` 引用它。修复 `session-start` 中的 platform detection，优先检查 `CURSOR_PLUGIN_ROOT`（Cursor 也可能设置 `CLAUDE_PLUGIN_ROOT`）。（基于 PR #709）

### Bug Fixes

- **Stop firing SessionStart hook on `--resume`**：startup hook 过去会在 resumed sessions 中重新注入 context，而这些 sessions 的 conversation history 已经有 context。现在 hook 只在 `startup`、`clear` 和 `compact` 时触发。
- **Bash 5.3+ hook hang**：在 `hooks/session-start` 中用 `printf` 替换 heredoc（`cat <<EOF`）。修复 macOS 上 Homebrew bash 5.3+ 因大变量展开中的 bash regression 造成 indefinite hang。(#572, #571)
- **POSIX-safe hook script**：在 `hooks/session-start` 中用 `$0` 替换 `${BASH_SOURCE[0]:-$0}`。修复 Ubuntu/Debian 上 `/bin/sh` 为 dash 时的 “Bad substitution” error。(#553)
- **Portable shebangs**：所有 shell scripts 从 `#!/bin/bash` 改为 `#!/usr/bin/env bash`。修复 NixOS、FreeBSD 和使用 Homebrew bash 的 macOS 上 `/bin/bash` outdated 或 missing 的问题。(#700)
- **Brainstorm server on Windows**：auto-detect Windows/Git Bash（`OSTYPE=msys*`, `MSYSTEM`）并切换到 foreground mode，修复 `nohup`/`disown` process reaping 导致的 silent server failure。(#737)
- **Codex docs fix**：在 Codex documentation 中用 `multi_agent` 替换 deprecated `collab` flag。(PR #749)

## v5.0.2 (2026-03-11)

### Zero-Dependency Brainstorm Server

**移除所有 vendored node_modules：server.js 现在完全 self-contained**

- 用基于内置 `http`、`fs` 和 `crypto` modules 的 zero-dependency Node.js server 替换 Express/Chokidar/WebSocket dependencies。
- 移除约 1,200 行 vendored `node_modules/`、`package.json` 和 `package-lock.json`。
- Custom WebSocket protocol implementation（RFC 6455 framing、ping/pong、proper close handshake）。
- Native `fs.watch()` file watching 替代 Chokidar。
- Full test suite：HTTP serving、WebSocket protocol、file watching 和 integration tests。

### Brainstorm Server Reliability

- **Auto-exit after 30 minutes idle**：无 clients connected 时 server 自动关闭，防止 orphaned processes。
- **Owner process tracking**：server 监控 parent harness PID，并在 owning session 死亡时退出。
- **Liveness check**：skill 在复用现有 instance 前验证 server responsive。
- **Encoding fix**：served HTML pages 使用正确的 `<meta charset="utf-8">`。

### Subagent Context Isolation

- 所有 delegation skills（brainstorming、dispatching-parallel-agents、requesting-code-review、subagent-driven-development、writing-plans）现在都包含 context isolation principle。
- Subagents 只接收它们需要的 context，防止 context window pollution。

## v5.0.1 (2026-03-10)

### Agentskills Compliance

**Brainstorm-server 移入 skill directory**

- 按照 [agentskills.io](https://agentskills.io) specification，将 `lib/brainstorm-server/` 移到 `skills/brainstorming/scripts/`。
- 所有 `${CLAUDE_PLUGIN_ROOT}/lib/brainstorm-server/` references 替换为 relative `scripts/` paths。
- Skills 现在可完全跨平台 portable：定位 scripts 不需要 platform-specific env vars。
- 移除 `lib/` directory（最后剩余内容）。

### New Features

**Gemini CLI extension**

- 通过 repo root 的 `gemini-extension.json` 和 `GEMINI.md` 原生支持 Gemini CLI extension。
- `GEMINI.md` 在 session start 通过 @imports 加载 `using-superpowers` skill 和 tool mapping table。
- Gemini CLI tool mapping reference（`skills/using-superpowers/references/gemini-tools.md`）：将 Claude Code tool names（Read、Write、Edit、Bash 等）转换为 Gemini CLI equivalents（read_file、write_file、replace 等）。
- 记录 Gemini CLI limitations：无 subagent support，skills fallback 到 `executing-plans`。
- Extension root 位于 repo root，确保 cross-platform compatibility（避免 Windows symlink issues）。
- README 新增 install instructions。

### Improvements

**Multi-platform brainstorm server launch**

- `visual-companion.md` 中加入 per-platform launch instructions：Claude Code（default mode）、Codex（通过 `CODEX_CI` auto-foreground）、Gemini CLI（`--foreground` with `is_background`）以及其他 environments fallback。
- Server 现在将 startup JSON 写入 `$SCREEN_DIR/.server-info`，即使 background execution 隐藏 stdout，agents 也能找到 URL 和 port。

**Brainstorm server dependencies bundled**

- 将 `node_modules` vendored 进 repo，让 brainstorm server 在全新 plugin installs 上无需 runtime `npm` 即可立即工作。
- 从 bundled deps 移除 `fsevents`（macOS-only native binary；chokidar 没有它也会 graceful fallback）。
- 如果 `node_modules` missing，则 fallback auto-install via `npm install`。

**OpenCode tool mapping fix**

- `TodoWrite` → `todowrite`（之前错误映射到 `update_plan`）；已对照 OpenCode source 验证。

### Bug Fixes

**Windows/Linux: single quotes break SessionStart hook** (#577, #529, #644, PR #585)

- hooks.json 中 `${CLAUDE_PLUGIN_ROOT}` 周围的 single quotes 在 Windows 上失败（cmd.exe 不把 single quotes 识别为 path delimiters），在 Linux 上也失败（single quotes 阻止 variable expansion）。
- Fix：用 escaped double quotes 替换 single quotes，可在 macOS bash、Windows cmd.exe、Windows Git Bash 和 Linux 上工作，无论 paths 中是否有空格。
- 已在 Windows 11（NT 10.0.26200.0）+ Claude Code 2.1.72 + Git for Windows 上验证。

**Brainstorming spec review loop skipped** (#677)

- spec review loop（dispatch spec-document-reviewer subagent，iterate until approved）存在于 prose “After the Design” section，但缺失于 checklist 和 process flow diagram。
- 由于 agents 比 prose 更可靠地遵循 diagram 和 checklist，spec review step 被完全跳过。
- 已向 checklist 添加 step 7（spec review loop），并向 dot graph 添加对应 nodes。
- 用 `claude --plugin-dir` 和 `claude-session-driver` 测试：worker 现在会正确 dispatch reviewer。

**Cursor install command** (PR #676)

- 修复 README 中 Cursor install command：`/plugin-add` → `/add-plugin`（已通过 Cursor 2.5 release announcement 确认）。

**User review gate in brainstorming** (#565)

- 在 spec completion 和 writing-plans handoff 之间新增 explicit user review step。
- User 必须 approve spec 后，implementation planning 才开始。
- Checklist、process flow 和 prose 都已更新新 gate。

**Session-start hook emits context only once per platform**

- Hook 现在检测正在 Claude Code 还是其他 platform 中运行。
- 对 Claude Code 输出 `hookSpecificOutput`，对其他平台输出 `additional_context`，防止 double context injection。

**Linting fix in token analysis script**

- `tests/claude-code/analyze-token-usage.py` 中 `except:` → `except Exception:`。

### Maintenance

**Removed dead code**

- 删除 `lib/skills-core.js` 及其 test（`tests/opencode/test-skills-core.js`），自 2026 年 2 月以来未被使用。
- 从 `tests/opencode/test-plugin-loading.sh` 移除 skills-core existence check。

### Community

- @karuturi：Claude Code official marketplace install instructions (PR #610)
- @mvanhorn：session-start hook dual-emit fix、OpenCode tool mapping fix
- @daniel-graham：bare except linting fix
- PR #585 author：Windows/Linux hooks quoting fix

---

## v5.0.0 (2026-03-09)

### Breaking Changes

**Specs and plans directory restructured**

- Specs（brainstorming output）现在保存到 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`。
- Plans（writing-plans output）现在保存到 `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`。
- User preferences for spec/plan locations 会覆盖这些 defaults。
- 所有 internal skill references、test files 和 example paths 都已更新匹配。
- Migration：如有需要，将现有 files 从 `docs/plans/` 移到新位置。

**Subagent-driven development mandatory on capable harnesses**

Writing-plans 不再提供 subagent-driven 和 executing-plans 之间的选择。对于支持 subagent 的 harnesses（Claude Code、Codex），必须使用 subagent-driven-development。Executing-plans 保留给不具备 subagent capability 的 harnesses，并会告知用户 Superpowers 在 subagent-capable platform 上效果更好。

**Executing-plans no longer batches**

移除 “execute 3 tasks then stop for review” pattern。Plans 现在持续执行，只在 blockers 处停止。

**Slash commands deprecated**

`/brainstorm`、`/write-plan` 和 `/execute-plan` 现在显示 deprecation notices，指向对应 skills。Commands 会在下个 major release 移除。

### New Features

**Visual brainstorming companion**

面向 brainstorming sessions 的可选 browser-based companion。当 topic 适合视觉辅助时，brainstorming skill 会提出在 browser window 中与 terminal conversation 并排显示 mockups、diagrams、comparisons 和其他内容。

- `lib/brainstorm-server/`：WebSocket server，包含 browser helper library、session management scripts，以及 dark/light themed frame template（"Superpowers Brainstorming" with GitHub link）。
- `skills/brainstorming/visual-companion.md`：server workflow、screen authoring 和 feedback collection 的 progressive disclosure guide。
- Brainstorming skill 在 process flow 中增加 visual companion decision point：探索 project context 后，skill 会评估接下来的问题是否涉及 visual content，并用独立消息提供 companion。
- Per-question decision：即便用户接受 companion，每个问题仍会单独评估 browser 或 terminal 哪个更合适。
- `tests/brainstorm-server/` 中的 integration tests。

**Document review system**

使用 subagent dispatch 自动审查 spec 和 plan documents 的 review loops：

- `skills/brainstorming/spec-document-reviewer-prompt.md`：Reviewer 检查 completeness、consistency、architecture 和 YAGNI。
- `skills/writing-plans/plan-document-reviewer-prompt.md`：Reviewer 检查 spec alignment、task decomposition、file structure 和 file size。
- Brainstorming 在写完 design doc 后 dispatch spec reviewer。
- Writing-plans 在每个 section 后包含 chunk-based plan review loop。
- Review loops 重复直到 approved，或在 5 iterations 后 escalate。
- End-to-end tests 位于 `tests/claude-code/test-document-review-system.sh`。
- Design spec 和 implementation plan 位于 `docs/superpowers/`。

**Architecture guidance across the skill pipeline**

向 brainstorming、writing-plans 和 subagent-driven-development 增加 design-for-isolation 和 file-size-awareness guidance：

- **Brainstorming**：新增 sections：“Design for isolation and clarity”（clear boundaries、well-defined interfaces、independently testable units）和 “Working in existing codebases”（follow existing patterns、targeted improvements only）。
- **Writing-plans**：新增 “File Structure” section：在定义 tasks 前先梳理 files 和 responsibilities。新增 “Scope Check” backstop：捕捉本应在 brainstorming 阶段拆分的 multi-subsystem specs。
- **SDD implementer**：新增 “Code Organization” section（遵循 plan 的 file structure，报告 growing files 相关 concerns）和 “When You're in Over Your Head” escalation guidance。
- **SDD code quality reviewer**：现在检查 architecture、unit decomposition、plan conformance 和 file growth。
- **Spec/plan reviewers**：将 architecture 和 file size 纳入 review criteria。
- **Scope assessment**：Brainstorming 现在评估 project 是否太大，无法放进单一 spec。Multi-subsystem requests 会早期 flag 并拆成 sub-projects，每个 sub-project 有自己的 spec → plan → implementation cycle。

**Subagent-driven development improvements**

- **Model selection**：新增按 task type 选择 model capability 的 guidance：cheap models 用于 mechanical implementation，standard 用于 integration，capable 用于 architecture 和 review。
- **Implementer status protocol**：Subagents 现在报告 DONE、DONE_WITH_CONCERNS、BLOCKED 或 NEEDS_CONTEXT。Controller 会按状态适当处理：用更多 context 重新 dispatch、升级 model capability、拆分 tasks，或 escalate 给 human。

### Improvements

**Instruction priority hierarchy**

在 using-superpowers 中新增显式 priority ordering：

1. 用户的显式 instructions（CLAUDE.md、AGENTS.md、direct requests）：最高优先级
2. Superpowers skills：覆盖 default system behavior
3. Default system prompt：最低优先级

如果 CLAUDE.md 或 AGENTS.md 说 “don't use TDD”，而某个 skill 说 “always use TDD”，用户 instructions 优先。

**SUBAGENT-STOP gate**

向 using-superpowers 添加 `<SUBAGENT-STOP>` block。为具体 tasks dispatch 的 subagents 现在会跳过该 skill，而不是触发 1% rule 并调用完整 skill workflows。

**Multi-platform improvements**

- Codex tool mapping 移到 progressive disclosure reference file（`references/codex-tools.md`）。
- 添加 Platform Adaptation pointer，让非 Claude Code platforms 能找到 tool equivalents。
- Plan headers 现在称呼 “agentic workers”，不再专指 “Claude”。
- `docs/README.codex.md` 记录 Collab feature requirement。

**Writing-plans template updates**

- Plan steps 现在使用 checkbox syntax（`- [ ] **Step N:**`）进行 progress tracking。
- Plan header 同时引用 subagent-driven-development 和 executing-plans，并带 platform-aware routing。

---

## v4.3.1 (2026-02-21)

### Added

**Cursor support**

Superpowers 现在支持 Cursor 的 plugin system。包含 `.cursor-plugin/plugin.json` manifest 和 README 中的 Cursor-specific installation instructions。SessionStart hook output 现在在现有 `hookSpecificOutput.additionalContext` 之外，也包含 `additional_context` field，以兼容 Cursor hook。

### Fixed

**Windows: Restored polyglot wrapper for reliable hook execution (#518, #504, #491, #487, #466, #440)**

Claude Code 在 Windows 上的 `.sh` auto-detection 会向 hook command prepend `bash`，破坏 execution。修复如下：

- 将 `session-start.sh` 重命名为 `session-start`（extensionless），避免 auto-detection 干扰。
- 恢复 `run-hook.cmd` polyglot wrapper，支持 multi-location bash discovery（标准 Git for Windows paths，然后 PATH fallback）。
- 如果找不到 bash，则 silent exit，而不是报错。
- 在 Unix 上，wrapper 通过 `exec bash` 直接运行 script。
- 使用 POSIX-safe `dirname "$0"` path resolution（适用于 dash/sh，不只适用于 bash）。

这修复了 Windows 上 paths 含空格、missing WSL、MSYS 中 `set -euo pipefail` fragility，以及 backslash mangling 导致的 SessionStart failures。

## v4.3.0 (2026-02-12)

该修复应显著提升 superpowers skills compliance，并降低 Claude 意外进入 native plan mode 的概率。

### Changed

**Brainstorming skill now enforces its workflow instead of describing it**

Models 过去会跳过 design phase，直接进入 frontend-design 等 implementation skills，或把整个 brainstorming process 压缩成单个 text block。该 skill 现在使用 hard gates、mandatory checklist 和 graphviz process flow 来强制 compliance：

- `<HARD-GATE>`：在 design 呈现并获得 user approve 前，禁止 implementation skills、code 或 scaffolding。
- Explicit checklist（6 items）必须创建为 tasks，并按顺序完成。
- Graphviz process flow 中 `writing-plans` 是唯一 valid terminal state。
- 为 “this is too simple to need a design” 添加 anti-pattern callout；这是 models 跳过流程时常用的具体 rationalization。
- Design section sizing 基于 section complexity，而不是 project complexity。

**Using-superpowers workflow graph intercepts EnterPlanMode**

向 skill flow graph 添加 `EnterPlanMode` intercept。当 model 准备进入 Claude native plan mode 时，会检查是否已经 brainstorming，并改路由到 brainstorming skill。Plan mode 永远不会进入。

### Fixed

**SessionStart hook now runs synchronously**

将 hooks.json 中的 `async: true` 改为 `async: false`。使用 async 时，hook 可能无法在 model 第一 turn 前完成，导致 using-superpowers instructions 没有进入第一条消息的 context。

## v4.2.0 (2026-02-05)

### Breaking Changes

**Codex: Replaced bootstrap CLI with native skill discovery**

移除 `superpowers-codex` bootstrap CLI、Windows `.cmd` wrapper 和相关 bootstrap content file。Codex 现在通过 `~/.agents/skills/superpowers/` symlink 使用 native skill discovery，因此不再需要旧的 `use_skill`/`find_skills` CLI tools。

安装现在只是 clone + symlink（记录在 INSTALL.md）。不需要 Node.js dependency。旧的 `~/.codex/skills/` path 已 deprecated。

### Fixes

**Windows: Fixed Claude Code 2.1.x hook execution (#331)**

Claude Code 2.1.x 改变了 Windows 上 hooks 的执行方式：现在会 auto-detect commands 中的 `.sh` files 并 prepend `bash`。这破坏了 polyglot wrapper pattern，因为 `bash "run-hook.cmd" session-start.sh` 会尝试把 `.cmd` 文件当 bash script 执行。

Fix：hooks.json 现在直接调用 session-start.sh。Claude Code 2.1.x 会自动处理 bash invocation。同时添加 .gitattributes，为 shell scripts 强制 LF line endings（修复 Windows checkout 上的 CRLF issues）。

**Windows: SessionStart hook runs async to prevent terminal freeze (#404, #413, #414, #419)**

synchronous SessionStart hook 会阻塞 TUI 进入 raw mode，冻结 Windows 上的所有 keyboard input。async 运行 hook 可防止 freeze，同时仍注入 superpowers context。

**Windows: Fixed O(n^2) `escape_for_json` performance**

使用 `${input:$i:1}` 的 character-by-character loop 在 bash 中由于 substring copy overhead 是 O(n^2)。在 Windows Git Bash 上需要 60+ 秒。已替换为 bash parameter substitution（`${s//old/new}`），每个 pattern 作为 single C-level pass 运行；在 macOS 上快 7x，在 Windows 上显著更快。

**Codex: Fixed Windows/PowerShell invocation (#285, #243)**

- Windows 不尊重 shebangs，因此直接调用 extensionless `superpowers-codex` script 会触发 “Open with” dialog。所有 invocations 现在都 prefix `node`。
- 修复 Windows 上 `~/` path expansion：PowerShell 不会扩展作为 `node` argument 传入的 `~`。改用 `$HOME`，在 bash 和 PowerShell 中都能正确扩展。

**Codex: Fixed path resolution in installer**

使用 `fileURLToPath()`，而不是手工解析 URL pathname，以在所有 platforms 上正确处理带 spaces 和 special characters 的 paths。

**Codex: Fixed stale skills path in writing-skills**

将 `~/.codex/skills/` reference（deprecated）更新为 `~/.agents/skills/`，用于 native discovery。

### Improvements

**Worktree isolation now required before implementation**

为 `subagent-driven-development` 和 `executing-plans` 都添加 `using-git-worktrees` 作为 required skill。Implementation workflows 现在明确要求开始工作前设置 isolated worktree，防止意外直接在 main 上工作。

**Main branch protection softened to require explicit consent**

不再完全禁止 main branch work，而是允许在获得 explicit user consent 后进行。这样更灵活，同时仍确保用户理解影响。

**Simplified installation verification**

从 verification steps 移除 `/help` command check 和具体 slash command list。Skills 主要通过描述目标来调用，而不是运行具体 commands。

**Codex: Clarified subagent tool mapping in bootstrap**

改进 Codex tools 如何映射到 Claude Code equivalents 的文档，适用于 subagent workflows。

### Tests

- 新增 subagent-driven-development 的 worktree requirement test。
- 新增 main branch red flag warning test。
- 修复 skill recognition test assertions 中的 case sensitivity。

---

## v4.1.1 (2026-01-23)

### Fixes

**OpenCode: Standardized on `plugins/` directory per official docs (#343)**

OpenCode official documentation 使用 `~/.config/opencode/plugins/`（plural）。我们的 docs 此前使用 `plugin/`（singular）。虽然 OpenCode 两种形式都接受，但我们已按 official convention 标准化，避免混淆。

Changes:
- 将 repo structure 中 `.opencode/plugin/` 重命名为 `.opencode/plugins/`。
- 更新所有 platforms 上的 installation docs（INSTALL.md、README.opencode.md）。
- 更新 test scripts 以匹配。

**OpenCode: Fixed symlink instructions (#339, #342)**

- 在 `ln -s` 前新增显式 `rm`（修复 reinstall 时 “file already exists” errors）。
- 添加 INSTALL.md 中缺失的 skills symlink step。
- 从 deprecated `use_skill`/`find_skills` 更新到 native `skill` tool references。

---

## v4.1.0 (2026-01-23)

### Breaking Changes

**OpenCode: Switched to native skills system**

Superpowers for OpenCode 现在使用 OpenCode native `skill` tool，而不是 custom `use_skill`/`find_skills` tools。这是更干净的 integration，可与 OpenCode built-in skill discovery 配合。

**Migration required:** Skills 必须 symlink 到 `~/.config/opencode/skills/superpowers/`（见更新后的 installation docs）。

### Fixes

**OpenCode: Fixed agent reset on session start (#226)**

此前使用 `session.prompt({ noReply: true })` 的 bootstrap injection method 会导致 OpenCode 在第一条消息时把 selected agent reset 为 “build”。现在使用 `experimental.chat.system.transform` hook，直接修改 system prompt 且没有 side effects。

**OpenCode: Fixed Windows installation (#232)**

- 移除对 `skills-core.js` 的依赖（当文件被复制而不是 symlink 时，消除 broken relative imports）。
- 为 cmd.exe、PowerShell 和 Git Bash 添加 comprehensive Windows installation docs。
- 记录每个平台上正确的 symlink vs junction 用法。

**Claude Code: Fixed Windows hook execution for Claude Code 2.1.x**

Claude Code 2.1.x 改变了 Windows 上 hooks 的执行方式：现在会 auto-detect commands 中的 `.sh` files 并 prepend `bash `。这破坏了 polyglot wrapper pattern，因为 `bash "run-hook.cmd" session-start.sh` 会尝试把 .cmd 文件当 bash script 执行。

Fix：hooks.json 现在直接调用 session-start.sh。Claude Code 2.1.x 会自动处理 bash invocation。同时添加 .gitattributes，为 shell scripts 强制 LF line endings（修复 Windows checkout 上的 CRLF issues）。

---

## v4.0.3 (2025-12-26)

### Improvements

**Strengthened using-superpowers skill for explicit skill requests**

修复一种 failure mode：即使用户明确按名称请求某个 skill（例如 “subagent-driven-development, please”），Claude 也会跳过 invoking skill。Claude 会认为 “I know what that means”，然后直接开始工作而不是加载 skill。

Changes:
- 将 “The Rule” 从 “Check for skills” 改为 “Invoke relevant or requested skills”，强调 active invocation 而不是 passive checking。
- 添加 “BEFORE any response or action”：原始措辞只提到 “response”，但 Claude 有时会先执行 action 而不回应。
- 添加 reassurance：调用错误 skill 也可以，减少 hesitation。
- 新增 red flag：“I know what that means” → 知道概念不等于使用 skill。

**Added explicit skill request tests**

`tests/explicit-skill-requests/` 中新增 test suite，验证当 users 按名称请求 skills 时 Claude 会正确 invoke。包含 single-turn 和 multi-turn test scenarios。

## v4.0.2 (2025-12-23)

### Fixes

**Slash commands now user-only**

向全部三个 slash commands（`/brainstorm`、`/execute-plan`、`/write-plan`）添加 `disable-model-invocation: true`。Claude 不再能通过 Skill tool 调用这些 commands；它们仅限 manual user invocation。

底层 skills（`superpowers:brainstorming`、`superpowers:executing-plans`、`superpowers:writing-plans`）仍可供 Claude autonomously invoke。该变更避免 Claude 调用一个本来只会重定向到 skill 的 command 所造成的混淆。

## v4.0.1 (2025-12-23)

### Fixes

**Clarified how to access skills in Claude Code**

修复一个 confusing pattern：Claude 会先通过 Skill tool invoke skill，然后又尝试单独 Read skill file。`using-superpowers` skill 现在明确说明 Skill tool 会直接加载 skill content，无需读取文件。

- 在 `using-superpowers` 中新增 “How to Access Skills” section。
- Instructions 中将 “read the skill” 改为 “invoke the skill”。
- 更新 slash commands，使用 fully qualified skill names（例如 `superpowers:brainstorming`）。

**Added GitHub thread reply guidance to receiving-code-review** (h/t @ralphbean)

新增说明：回复 inline review comments 时，应在原 thread 中回复，而不是作为 top-level PR comments。

**Added automation-over-documentation guidance to writing-skills** (h/t @EthanJStark)

新增 guidance：mechanical constraints 应自动化，而不是写进文档；skills 应保留给 judgment calls。

## v4.0.0 (2025-12-17)

### New Features

**Two-stage code review in subagent-driven-development**

Subagent workflows 现在在每个 task 后使用两个独立 review stages：

1. **Spec compliance review**：Skeptical reviewer 精确验证 implementation 是否匹配 spec。捕获 missing requirements 和 over-building。不会信任 implementer report，而是读取实际 code。

2. **Code quality review**：仅在 spec compliance 通过后运行。审查 clean code、test coverage、maintainability。

这能捕获常见 failure mode：代码写得很好，但不符合请求。Reviews 是 loops，不是 one-shot；如果 reviewer 发现 issues，implementer 修复后 reviewer 再检查。

其他 subagent workflow improvements：
- Controller 向 workers 提供完整 task text（不是 file references）。
- Workers 可以在 work 前以及 work 过程中提出 clarifying questions。
- 报告 completion 前进行 self-review checklist。
- Plan 在开始时读取一次，并提取到 TodoWrite。

`skills/subagent-driven-development/` 中的新 prompt templates：
- `implementer-prompt.md`：包含 self-review checklist，鼓励提问。
- `spec-reviewer-prompt.md`：根据 requirements 进行 skeptical verification。
- `code-quality-reviewer-prompt.md`：标准 code review。

**Debugging techniques consolidated with tools**

`systematic-debugging` 现在捆绑 supporting techniques 和 tools：
- `root-cause-tracing.md`：沿 call stack 反向追踪 bugs。
- `defense-in-depth.md`：在多层增加 validation。
- `condition-based-waiting.md`：用 condition polling 替换 arbitrary timeouts。
- `find-polluter.sh`：用于找出哪个 test 造成 pollution 的 bisection script。
- `condition-based-waiting-example.ts`：来自真实 debugging session 的完整 implementation。

**Testing anti-patterns reference**

`test-driven-development` 现在包含 `testing-anti-patterns.md`，覆盖：
- 测试 mock behavior 而不是 real behavior。
- 向 production classes 添加 test-only methods。
- 未理解 dependencies 就 mock。
- Incomplete mocks 隐藏 structural assumptions。

**Skill test infrastructure**

三个用于验证 skill behavior 的新 test frameworks：

`tests/skill-triggering/`：验证 skills 能从 naive prompts 触发，不需要 explicit naming。测试 6 个 skills，确保仅凭 descriptions 就足够。

`tests/claude-code/`：使用 `claude -p` 的 headless integration tests。通过 session transcript（JSONL）analysis 验证 skill usage。包含用于 cost tracking 的 `analyze-token-usage.py`。

`tests/subagent-driven-dev/`：使用两个完整 test projects 进行 end-to-end workflow validation：
- `go-fractals/`：带 Sierpinski/Mandelbrot 的 CLI tool（10 tasks）。
- `svelte-todo/`：带 localStorage 和 Playwright 的 CRUD app（12 tasks）。

### Major Changes

**DOT flowcharts as executable specifications**

用 DOT/GraphViz flowcharts 重写 key skills，并将其作为 authoritative process definition。Prose 成为 supporting content。

**The Description Trap**（记录在 `writing-skills`）：发现当 skill descriptions 包含 workflow summaries 时，它们会覆盖 flowchart content。Claude 会遵循短 description，而不是读取详细 flowchart。Fix：descriptions 必须只用于 trigger（“Use when X”），不包含 process details。

**Skill priority in using-superpowers**

当多个 skills 适用时，process skills（brainstorming、debugging）现在明确优先于 implementation skills。“Build X” 先触发 brainstorming，再触发 domain skills。

**brainstorming trigger strengthened**

Description 改为 imperative：“You MUST use this before any creative work—creating features, building components, adding functionality, or modifying behavior.”

### Breaking Changes

**Skill consolidation**：六个 standalone skills 已合并：
- `root-cause-tracing`、`defense-in-depth`、`condition-based-waiting` → bundled in `systematic-debugging/`
- `testing-skills-with-subagents` → bundled in `writing-skills/`
- `testing-anti-patterns` → bundled in `test-driven-development/`
- `sharing-skills` removed（obsolete）

### Other Improvements

- **render-graphs.js**：从 skills 中提取 DOT diagrams 并 render 为 SVG 的 tool。
- **Rationalizations table** in using-superpowers：Scannable format，包含新 entries：“I need more context first”、“Let me explore first”、“This feels productive”。
- **docs/testing.md**：用 Claude Code integration tests 测试 skills 的指南。

---

## v3.6.2 (2025-12-03)

### Fixed

- **Linux Compatibility**：修复 polyglot hook wrapper（`run-hook.cmd`），改用 POSIX-compliant syntax。
  - 将第 16 行 bash-specific `${BASH_SOURCE[0]:-$0}` 替换为标准 `$0`。
  - 解决 Ubuntu/Debian 系统中 `/bin/sh` 为 dash 时的 “Bad substitution” error。
  - 修复 #141。

---

## v3.5.1 (2025-11-24)

### Changed

- **OpenCode Bootstrap Refactor**：从 `chat.message` hook 切换为 `session.created` event 进行 bootstrap injection。
  - Bootstrap 现在通过 `session.prompt()` + `noReply: true` 在 session creation 时注入。
  - 明确告诉 model using-superpowers 已加载，防止重复加载 skill。
  - 将 bootstrap content generation 合并进 shared `getBootstrapContent()` helper。
  - 更干净的 single-implementation approach（移除 fallback pattern）。

---

## v3.5.0 (2025-11-23)

### Added

- **OpenCode Support**：为 OpenCode.ai 提供 native JavaScript plugin。
  - Custom tools：`use_skill` 和 `find_skills`。
  - Message insertion pattern，用于 context compaction 后的 skill persistence。
  - 通过 chat.message hook 自动注入 context。
  - session.compacted events 时自动 re-injection。
  - Three-tier skill priority：project > personal > superpowers。
  - Project-local skills support（`.opencode/skills/`）。
  - Shared core module（`lib/skills-core.js`），用于与 Codex code reuse。
  - 带 proper isolation 的 automated test suite（`tests/opencode/`）。
  - Platform-specific documentation（`docs/README.opencode.md`、`docs/README.codex.md`）。

### Changed

- **Refactored Codex Implementation**：现在使用 shared `lib/skills-core.js` ES module。
  - 消除 Codex 和 OpenCode 之间的 code duplication。
  - Skill discovery 和 parsing 的 single source of truth。
  - Codex 通过 Node.js interop 成功加载 ES modules。

- **Improved Documentation**：重写 README，清楚解释 problem/solution。
  - 移除 duplicate sections 和 conflicting information。
  - 添加完整 workflow description（brainstorm → plan → execute → finish）。
  - 简化 platform installation instructions。
  - 强调 skill-checking protocol，而不是 automatic activation claims。

---

## v3.4.1 (2025-10-31)

### Improvements

- 优化 superpowers bootstrap，消除 redundant skill execution。`using-superpowers` skill content 现在直接提供在 session context 中，并明确指导只对其他 skills 使用 Skill tool。这减少 overhead，并避免 agents 在 session start 已有内容的情况下仍手动执行 `using-superpowers` 的 confusing loop。

## v3.4.0 (2025-10-30)

### Improvements

- 简化 `brainstorming` skill，使其回归原始 conversational vision。移除 heavy 6-phase process 和 formal checklists，改为 natural dialogue：一次问一个问题，然后以 200-300 word sections 呈现 design 并验证。保留 documentation 和 implementation handoff features。

## v3.3.1 (2025-10-28)

### Improvements

- 更新 `brainstorming` skill，要求 autonomous recon before questioning，鼓励 recommendation-driven decisions，并防止 agents 把 prioritization 委托回 humans。
- 按 Strunk 的 “Elements of Style” principles 将 writing clarity improvements 应用于 `brainstorming` skill（omitted needless words、converted negative to positive form、improved parallel construction）。

### Bug Fixes

- 澄清 `writing-skills` guidance，使其指向正确的 agent-specific personal skill directories（Claude Code 使用 `~/.claude/skills`，Codex 使用 `~/.codex/skills`）。

## v3.3.0 (2025-10-28)

### New Features

**Experimental Codex Support**
- 新增 unified `superpowers-codex` script，包含 bootstrap/use-skill/find-skills commands。
- Cross-platform Node.js implementation（支持 Windows、macOS、Linux）。
- Namespaced skills：superpowers skills 使用 `superpowers:skill-name`，personal 使用 `skill-name`。
- Personal skills 在同名时 override superpowers skills。
- Clean skill display：显示 name/description，不暴露 raw frontmatter。
- Helpful context：显示每个 skill 的 supporting files directory。
- Codex tool mapping：TodoWrite→update_plan、subagents→manual fallback 等。
- 用 minimal AGENTS.md 进行 bootstrap integration，实现 automatic startup。
- 面向 Codex 的完整 installation guide 和 bootstrap instructions。

**与 Claude Code integration 的关键差异：**
- 使用单个 unified script，而不是 separate tools。
- Codex-specific equivalents 的 tool substitution system。
- 简化 subagent handling（manual work 而不是 delegation）。
- 更新 terminology：使用 “Superpowers skills” 而不是 “Core skills”。

### Files Added
- `.codex/INSTALL.md`：Codex users installation guide。
- `.codex/superpowers-bootstrap.md`：带 Codex adaptations 的 bootstrap instructions。
- `.codex/superpowers-codex`：包含所有 functionality 的 unified Node.js executable。

**Note:** Codex support 仍属 experimental。该 integration 提供 core superpowers functionality，但可能需根据 user feedback 继续 refinement。

## v3.2.3 (2025-10-23)

### Improvements

**Updated using-superpowers skill to use Skill tool instead of Read tool**
- 将 skill invocation instructions 从 Read tool 改为 Skill tool。
- 更新 description：“using Read tool” → “using Skill tool”。
- 更新 step 3：“Use the Read tool” → “Use the Skill tool to read and run”。
- 更新 rationalization list：“Read the current version” → “Run the current version”。

Skill tool 是 Claude Code 中调用 skills 的正确机制。此更新修正 bootstrap instructions，引导 agents 使用正确 tool。

### Files Changed
- Updated：`skills/using-superpowers/SKILL.md`：将 tool references 从 Read 改为 Skill。

## v3.2.2 (2025-10-21)

### Improvements

**Strengthened using-superpowers skill against agent rationalization**
- 添加 EXTREMELY-IMPORTANT block，用 absolute language 强调 mandatory skill checking。
  - “If even 1% chance a skill applies, you MUST read it”
  - “You do not have a choice. You cannot rationalize your way out.”
- 添加 MANDATORY FIRST RESPONSE PROTOCOL checklist。
  - agents 在任何 response 前必须完成的 5-step process。
  - 明确 “responding without this = failure” consequence。
- 添加 Common Rationalizations section，列出 8 个具体 evasion patterns。
  - “This is just a simple question” → WRONG
  - “I can check files quickly” → WRONG
  - “Let me gather information first” → WRONG
  - 以及另外 5 个常见 patterns。

这些变化针对观察到的 agent behavior：尽管说明明确，agents 仍会 rationalize 绕过 skill usage。强语言和预设 counter-arguments 旨在让 non-compliance 更难发生。

### Files Changed
- Updated：`skills/using-superpowers/SKILL.md`：新增三层 enforcement，防止 skill-skipping rationalization。

## v3.2.1 (2025-10-20)

### New Features

**Code reviewer agent now included in plugin**
- 向 plugin 的 `agents/` directory 添加 `superpowers:code-reviewer` agent。
- Agent 按 plans 和 coding standards 提供 systematic code review。
- 此前需要 users 拥有 personal agent configuration。
- 所有 skill references 已更新为 namespaced `superpowers:code-reviewer`。
- 修复 #55。

### Files Changed
- New：`agents/code-reviewer.md`：包含 review checklist 和 output format 的 Agent definition。
- Updated：`skills/requesting-code-review/SKILL.md`：引用 `superpowers:code-reviewer`。
- Updated：`skills/subagent-driven-development/SKILL.md`：引用 `superpowers:code-reviewer`。

## v3.2.0 (2025-10-18)

### New Features

**Design documentation in brainstorming workflow**
- 向 brainstorming skill 添加 Phase 4：Design Documentation。
- Design documents 现在会在 implementation 前写入 `docs/plans/YYYY-MM-DD-<topic>-design.md`。
- 恢复从原 brainstorming command 转换为 skill 时丢失的 functionality。
- Documents 会在 worktree setup 和 implementation planning 前写入。
- 已用 subagent 测试，验证在 time pressure 下仍能 comply。

### Breaking Changes

**Skill reference namespace standardization**
- 所有 internal skill references 现在都使用 `superpowers:` namespace prefix。
- 更新格式：`superpowers:test-driven-development`（之前只是 `test-driven-development`）。
- 影响所有 REQUIRED SUB-SKILL、RECOMMENDED SUB-SKILL 和 REQUIRED BACKGROUND references。
- 与使用 Skill tool invoke skills 的方式对齐。
- 更新文件：brainstorming、executing-plans、subagent-driven-development、systematic-debugging、testing-skills-with-subagents、writing-plans、writing-skills。

### Improvements

**Design vs implementation plan naming**
- Design documents 使用 `-design.md` suffix，防止 filename collisions。
- Implementation plans 继续使用现有 `YYYY-MM-DD-<feature-name>.md` format。
- 二者都保存在 `docs/plans/` directory 中，并通过 naming 明确区分。

## v3.1.1 (2025-10-17)

### Bug Fixes

- **Fixed command syntax in README** (#44)：更新所有 command references，使用正确 namespaced syntax（`/superpowers:brainstorm` 而不是 `/brainstorm`）。Plugin-provided commands 会由 Claude Code 自动 namespaced，以避免 plugins 之间冲突。

## v3.1.0 (2025-10-17)

### Breaking Changes

**Skill names standardized to lowercase**
- 所有 skill frontmatter `name:` fields 现在使用 lowercase kebab-case，与 directory names 匹配。
- 示例：`brainstorming`、`test-driven-development`、`using-git-worktrees`。
- 所有 skill announcements 和 cross-references 已更新为 lowercase format。
- 这确保 directory names、frontmatter 和 documentation 中命名一致。

### New Features

**Enhanced brainstorming skill**
- 新增 Quick Reference table，展示 phases、activities 和 tool usage。
- 新增可复制 workflow checklist，用于 tracking progress。
- 新增 decision flowchart，用于判断何时 revisit earlier phases。
- 新增 comprehensive AskUserQuestion tool guidance，并提供 concrete examples。
- 新增 “Question Patterns” section，解释何时使用 structured vs open-ended questions。
- 将 Key Principles 重构为 scannable table。

**Anthropic best practices integration**
- 新增 `skills/writing-skills/anthropic-best-practices.md`：Official Anthropic skill authoring guide。
- 在 writing-skills SKILL.md 中引用，用于 comprehensive guidance。
- 提供 progressive disclosure、workflows 和 evaluation patterns。

### Improvements

**Skill cross-reference clarity**
- 所有 skill references 现在使用显式 requirement markers：
  - `**REQUIRED BACKGROUND:**`：你必须理解的 prerequisites。
  - `**REQUIRED SUB-SKILL:**`：workflow 中必须使用的 Skills。
  - `**Complementary skills:**`：可选但有帮助的 related skills。
- 移除旧 path format（`skills/collaboration/X` → just `X`）。
- 用分类 relationships（Required vs Complementary）更新 Integration sections。
- 更新 cross-reference documentation，加入 best practices。

**Alignment with Anthropic best practices**
- 修复 description grammar 和 voice（完全使用 third-person）。
- 添加用于 scanning 的 Quick Reference tables。
- 添加 Claude 可复制和追踪的 workflow checklists。
- 对非显而易见的 decision points 合理使用 flowcharts。
- 改进 scannable table formats。
- 所有 skills 都远低于 500-line recommendation。

### Bug Fixes

- **Re-added missing command redirects**：恢复 v3.0 migration 中意外移除的 `commands/brainstorm.md` 和 `commands/write-plan.md`。
- 修复 `defense-in-depth` name mismatch（此前是 `Defense-in-Depth-Validation`）。
- 修复 `receiving-code-review` name mismatch（此前是 `Code-Review-Reception`）。
- 修复 `commands/brainstorm.md` 对正确 skill name 的 reference。
- 移除对不存在 related skills 的 references。

### Documentation

**writing-skills improvements**
- 更新 cross-referencing guidance，加入 explicit requirement markers。
- 添加对 Anthropic official best practices 的 reference。
- 改进 examples，展示 proper skill reference format。

## v3.0.1 (2025-10-16)

### Changes

我们现在使用 Anthropic first-party skills system。

## v2.0.2 (2025-10-12)

### Bug Fixes

- **Fixed false warning when local skills repo is ahead of upstream**：initialization script 过去会在 local repository commits ahead of upstream 时错误警告 “New skills available from upstream”。现在 logic 正确区分三种 git states：local behind（应 update）、local ahead（无 warning）和 diverged（应 warning）。

## v2.0.1 (2025-10-12)

### Bug Fixes

- **Fixed session-start hook execution in plugin context** (#8, PR #9)：hook 过去会以 “Plugin hook error” 静默失败，导致 skills context 无法加载。修复如下：
  - 在 Claude Code execution context 中 BASH_SOURCE unbound 时，使用 `${BASH_SOURCE[0]:-$0}` fallback。
  - 添加 `|| true`，在 filtering status flags 且 grep 结果为空时 graceful handle。

---

# Superpowers v2.0.0 Release Notes

## Overview

Superpowers v2.0 通过重大架构转变，让 skills 更易访问、更易维护，也更适合 community-driven 发展。

头条变化是 **skills repository separation**：所有 skills、scripts 和 documentation 都已从 plugin 移到独立 repository（[obra/superpowers-skills](https://github.com/obra/superpowers-skills)）。这让 superpowers 从 monolithic plugin 转变为管理 skills repository local clone 的 lightweight shim。Skills 会在 session start 自动更新。Users 通过标准 git workflows fork 并贡献改进。Skills library 可独立于 plugin version。

基础设施之外，本 release 新增九个聚焦 problem-solving、research 和 architecture 的 skills。我们以 imperative tone 和更清晰结构重写 core **using-skills** documentation，让 Claude 更容易理解何时以及如何使用 skills。**find-skills** 现在输出可直接粘贴到 Read tool 的 paths，减少 skills discovery workflow 中的摩擦。

Users 获得 seamless operation：plugin 自动处理 cloning、forking 和 updating。Contributors 会发现新架构让改进和分享 skills 变得非常简单。本 release 为 skills 作为 community resource 快速演化奠定基础。

## Breaking Changes

### Skills Repository Separation

**最大变化：** Skills 不再存在于 plugin 中。它们已移至单独 repository：[obra/superpowers-skills](https://github.com/obra/superpowers-skills)。

**这对你意味着：**

- **First install:** Plugin 自动 clone skills 到 `~/.config/superpowers/skills/`。
- **Forking:** setup 期间，如果已安装 `gh`，会提供 fork skills repo 的选项。
- **Updates:** Skills 在 session start 自动更新（可能时 fast-forward）。
- **Contributing:** 在 branches 上工作，本地 commit，向 upstream 提交 PR。
- **No more shadowing:** 旧 two-tier system（personal/core）由 single-repo branch workflow 取代。

**Migration:**

如果你已有 installation：
1. 旧 `~/.config/superpowers/.git` 会备份到 `~/.config/superpowers/.git.bak`。
2. 旧 skills 会备份到 `~/.config/superpowers/skills.bak`。
3. 会在 `~/.config/superpowers/skills/` 创建 obra/superpowers-skills 的 fresh clone。

### Removed Features

- **Personal superpowers overlay system**：由 git branch workflow 取代。
- **setup-personal-superpowers hook**：由 initialize-skills.sh 取代。

## New Features

### Skills Repository Infrastructure

**Automatic Clone & Setup** (`lib/initialize-skills.sh`)
- 首次运行时 clone obra/superpowers-skills。
- 如果安装了 GitHub CLI，则提供 fork creation。
- 正确设置 upstream/origin remotes。
- 处理从旧 installation migration。

**Auto-Update**
- 每次 session start 从 tracking remote fetch。
- 可能时自动 fast-forward merge。
- 当需要 manual sync（branch diverged）时通知。
- 使用 pulling-updates-from-skills-repository skill 进行 manual sync。

### New Skills

**Problem-Solving Skills** (`skills/problem-solving/`)
- **collision-zone-thinking**：强制组合无关概念，产生 emergent insights。
- **inversion-exercise**：翻转 assumptions，揭示 hidden constraints。
- **meta-pattern-recognition**：在 domains 间发现 universal principles。
- **scale-game**：在 extremes 上测试，以暴露 fundamental truths。
- **simplification-cascades**：寻找可消除多个 components 的 insights。
- **when-stuck**：dispatch 到正确 problem-solving technique。

**Research Skills** (`skills/research/`)
- **tracing-knowledge-lineages**：理解 ideas 如何随时间演化。

**Architecture Skills** (`skills/architecture/`)
- **preserving-productive-tensions**：保留多个 valid approaches，而不是 premature resolution。

### Skills Improvements

**using-skills (formerly getting-started)**
- 从 getting-started 重命名为 using-skills。
- 使用 imperative tone 完整重写（v4.0.0）。
- 将 critical rules 前置。
- 为所有 workflows 添加 “Why” explanations。
- references 中始终包含 /SKILL.md suffix。
- 更清晰地区分 rigid rules 与 flexible patterns。

**writing-skills**
- Cross-referencing guidance 从 using-skills 移入。
- 新增 token efficiency section（word count targets）。
- 改进 CSO（Claude Search Optimization）guidance。

**sharing-skills**
- 为新的 branch-and-PR workflow 更新（v2.0.0）。
- 移除 personal/core split references。

**pulling-updates-from-skills-repository** (new)
- 完整 upstream sync workflow。
- 替代旧 “updating-skills” skill。

### Tools Improvements

**find-skills**
- 现在输出带 /SKILL.md suffix 的 full paths。
- 让 paths 可直接用于 Read tool。
- 更新 help text。

**skill-run**
- 从 scripts/ 移到 skills/using-skills/。
- 改进 documentation。

### Plugin Infrastructure

**Session Start Hook**
- 现在从 skills repository location 加载。
- 在 session start 显示 full skills list。
- 打印 skills location info。
- 显示 update status（updated successfully / behind upstream）。
- 将 “skills behind” warning 移到 output 末尾。

**Environment Variables**
- `SUPERPOWERS_SKILLS_ROOT` 设置为 `~/.config/superpowers/skills`。
- 在所有 paths 中一致使用。

## Bug Fixes

- 修复 forking 时重复添加 upstream remote。
- 修复 find-skills 输出中 double “skills/” prefix。
- 从 session-start 移除 obsolete setup-personal-superpowers call。
- 修复 hooks 和 commands 中的 path references。

## Documentation

### README
- 为新 skills repository architecture 更新。
- 添加指向 superpowers-skills repo 的醒目 link。
- 更新 auto-update description。
- 修复 skill names 和 references。
- 更新 Meta skills list。

### Testing Documentation
- 新增 comprehensive testing checklist（`docs/TESTING-CHECKLIST.md`）。
- 创建 local marketplace config 用于 testing。
- 记录 manual testing scenarios。

## Technical Details

### File Changes

**Added:**
- `lib/initialize-skills.sh`：Skills repo initialization 和 auto-update。
- `docs/TESTING-CHECKLIST.md`：Manual testing scenarios。
- `.claude-plugin/marketplace.json`：Local testing config。

**Removed:**
- `skills/` directory（82 files）：现在位于 obra/superpowers-skills。
- `scripts/` directory：现在位于 obra/superpowers-skills/skills/using-skills/。
- `hooks/setup-personal-superpowers.sh`：Obsolete。

**Modified:**
- `hooks/session-start.sh`：从 ~/.config/superpowers/skills 使用 skills。
- `commands/brainstorm.md`：更新 paths 到 SUPERPOWERS_SKILLS_ROOT。
- `commands/write-plan.md`：更新 paths 到 SUPERPOWERS_SKILLS_ROOT。
- `commands/execute-plan.md`：更新 paths 到 SUPERPOWERS_SKILLS_ROOT。
- `README.md`：为新架构完整重写。

### Commit History

This release includes:
- 20+ commits for skills repository separation
- PR #1: Amplifier-inspired problem-solving and research skills
- PR #2: Personal superpowers overlay system (later replaced)
- Multiple skill refinements and documentation improvements

## Upgrade Instructions

### Fresh Install

```bash
# In Claude Code
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Plugin 会自动处理所有事项。

### Upgrading from v1.x

1. **Backup your personal skills**（如果有）：
   ```bash
   cp -r ~/.config/superpowers/skills ~/superpowers-skills-backup
   ```

2. **Update the plugin:**
   ```bash
   /plugin update superpowers
   ```

3. **On next session start:**
   - 旧 installation 会自动备份。
   - Fresh skills repo 会被 cloned。
   - 如果有 GitHub CLI，会提供 fork 选项。

4. **Migrate personal skills**（如果之前有）：
   - 在 local skills repo 中创建 branch。
   - 从 backup 复制 personal skills。
   - Commit 并 push 到 fork。
   - 考虑通过 PR 贡献回 upstream。

## What's Next

### For Users

- 探索新的 problem-solving skills。
- 尝试 branch-based workflow 来改进 skills。
- 向 community 贡献 skills。

### For Contributors

- Skills repository 现在位于 https://github.com/obra/superpowers-skills。
- Fork → Branch → PR workflow。
- 关于 documentation 的 TDD approach，请参阅 skills/meta/writing-skills/SKILL.md。

## Known Issues

目前没有。

## Credits

- Problem-solving skills inspired by Amplifier patterns
- Community contributions and feedback
- Extensive testing and iteration on skill effectiveness

---

**Full Changelog:** https://github.com/obra/superpowers/compare/dd013f6...main
**Skills Repository:** https://github.com/obra/superpowers-skills
**Issues:** https://github.com/obra/superpowers/issues
