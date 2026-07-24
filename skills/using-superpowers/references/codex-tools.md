## Subagent dispatch requires multi-agent support

添加到你的 Codex 配置（`~/.codex/config.toml`）：

```toml
[features]
multi_agent = true
```

这会为 `dispatching-parallel-agents` 和 `subagent-driven-development` 等 skills 启用 `spawn_agent`、`wait_agent` 和 `close_agent`。使用 subagent-driven-development 时，reviewer 返回结果后即可关闭；implementer 要保持开启，直到该任务 review 通过，因为 fix loop 会继续恢复同一个 implementer，然后再关闭。如果 harness 无法继续向已生成的 agent 发消息，每轮 fix 都派一个新的 implementer，并携带 brief path、report file 和 findings。

## Environment Detection

创建 worktrees 或 finish branches 的 skills 应在继续前用只读 git 命令检测环境：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` -> 已在 linked worktree 中（跳过创建）
- `BRANCH` 为空 -> detached HEAD（无法从 sandbox branch/push/PR）

各 skill 如何使用这些信号，见 `using-git-worktrees` Step 0 和 `finishing-a-development-branch` Step 1。

## Codex App Finishing

当 sandbox 阻止 branch/push 操作时（位于 externally managed worktree 的 detached HEAD），agent 会提交所有工作，并告知用户使用 App 原生控件：

- **“Create branch”**：命名分支，然后通过 App UI commit/push/PR
- **“Hand off to local”**：把工作转移到用户本地 checkout

agent 仍可运行测试、stage 文件，并输出建议的分支名、commit message 和 PR description 供用户复制。
