# Codex Tool Mapping

Skills 使用 Claude Code tool names。当你在 skill 中遇到这些名称时，使用你平台上的 equivalent：

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` tool（dispatch subagent） | `spawn_agent`（见 [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)） |
| 多个 `Task` calls（parallel） | 多个 `spawn_agent` calls |
| Task returns result | `wait_agent` |
| Task completes automatically | `close_agent` to free slot |
| `TodoWrite`（task tracking） | `update_plan` |
| `Skill` tool（invoke a skill） | Skills 原生加载，直接遵循 instructions |
| `Read`, `Write`, `Edit`（files） | 使用 native file tools |
| `Bash`（run commands） | 使用 native shell tools |

## Subagent dispatch requires multi-agent support

添加到你的 Codex config（`~/.codex/config.toml`）：

```toml
[features]
multi_agent = true
```

这会为 `dispatching-parallel-agents` 和 `subagent-driven-development` 等 skills 启用 `spawn_agent`、`wait_agent` 和 `close_agent`。

Legacy note: `rust-v0.115.0` 之前的 Codex builds 将 spawned-agent
waiting 暴露为 `wait`。当前 Codex 对 spawned agents 使用 `wait_agent`。
`wait` 这个名字现在属于 code-mode `exec/wait`，它通过 `cell_id` 恢复 yielded exec
cell；它不是 spawned-agent result tool。

## Environment Detection

创建 worktrees 或 finish branches 的 skills 应在继续前使用 read-only git commands 检测 environment：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → 已经在 linked worktree 中（跳过创建）
- `BRANCH` empty → detached HEAD（不能从 sandbox branch/push/PR）

各 skill 如何使用这些 signals，见 `using-git-worktrees` Step 0 和 `finishing-a-development-branch` Step 1。

## Codex App Finishing

当 sandbox 阻止 branch/push operations（externally managed worktree 中的 detached HEAD）时，agent 会 commit 所有 work，并告知用户使用 App native controls：

- **"Create branch"** — 命名 branch，然后通过 App UI commit/push/PR
- **"Hand off to local"** — 将工作转交到用户的 local checkout

Agent 仍然可以运行 tests、stage files，并输出建议的 branch names、commit messages 和 PR descriptions，供用户使用。
