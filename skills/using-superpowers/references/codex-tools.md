# Codex Tool Mapping

技能用行动说话（"派遣子代理"、"创建待办事项"、"读取文件"）。在 Codex 上，这些内容解析为以下工具。

|动作技能要求|法典等效项 |
|----------------------|------------------|
|读取文件 | `shell`（例如，`cat`、`head`、`tail`） — Codex 通过 shell | 读取文件
|创建/编辑/删除文件 | `apply_patch`（用于创建、更新、删除的结构化差异）|
|运行 shell 命令 | `shell` |
|搜索文件内容 | `shell`（例如，`grep`、`rg`）|
|按名称查找文件 | `shell`（例如，`find`、`ls`）|
|获取网址 | `shell` 与 `curl` / `wget` — Codex 没有本机获取工具 |
|搜索网络 | `web_search`（默认启用；可通过顶级 `web_search` 设置在 `config.toml` 中配置 — `live`、`cached` 或 `disabled`）|
|调用技能 |技能本地加载 - 只需按照说明操作即可 |
|调度子代理（`Subagent (general-purpose):` 模板）| `spawn_agent`（参见[Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)）|
|多个并行调度 |一次响应中多个 `spawn_agent` 调用 |
|等待子代理结果 | `wait_agent` |
|完成后释放子代理插槽 | `close_agent` |
|任务跟踪（"创建待办事项"、"标记完成"）| `update_plan` |

## Instructions file

当技能提到"您的说明文件"时，在 Codex 上，这是项目根目录下的 **`AGENTS.md`>**。 Codex 还读取 `~/.codex/AGENTS.md` 作为全局上下文，并且 `AGENTS.override.md`（在项目树中或 `~/.codex/` 中）在存在时优先。 Codex 从项目根目录一直走到当前工作目录，将一路上找到的 `AGENTS.md` 文件串联起来，一直到 `project_doc_max_bytes`（默认为 32 KiB）。

## Personal skills directory

用户级别技能位于**`$CODEX_HOME/skills/`**（默认`~/.codex/skills/`）。 Codex 还读取跨运行时路径 **`~/.agents/skills/`>** （与 Copilot CLI 和 Gemini CLI 共享）。当两个目录存在于同一范围时，Codex 会将它们作为单独的技能目录加载 - Codex 的文档当前不记录它们之间的优先级。每个技能都是一个包含 `SKILL.md` 的子目录（带有 `name` 和 `description` frontmatter）。

## Subagent dispatch requires multi-agent support

添加到您的 Codex 配置 (`~/.codex/config.toml`)：

```toml
[features]
multi_agent = true
```

这将为 `dispatching-parallel-agents` 和 `subagent-driven-development` 等技能启用 `spawn_agent`、`wait_agent` 和 `close_agent`。

遗留说明：Codex 在 `rust-v0.115.0` 暴露的衍生代理之前构建
等待`wait`。当前 Codex 使用 `wait_agent` 作为生成的代理。的
`wait` 名称现在属于代码模式 `exec/wait`，它恢复生成的 exec
单元格为`cell_id`； it is not the spawned-agent result tool.

## Environment Detection

创建工作树或完成分支的技能应该检测它们的
在继续之前具有只读 git 命令的环境：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → 已经在链接的工作树中（跳过创建）
- `BRANCH` 空 → 分离 HEAD（无法从沙箱分支/push/PR）

请参见`using-git-worktrees`步骤0和`finishing-a-development-branch`
第 1 步了解每种技能如何使用这些信号。

## Codex App Finishing

当沙箱阻止分支/push操作时（在一个
外部管理的工作树），代理提交所有工作并通知
用户使用应用程序的本机控件：

- **"创建分支"** — 命名分支，然后通过应用程序 UI 提交/push/PR
- **"移交到本地"** — 将工作转移到用户的本地结帐处

代理仍然可以运行测试、暂存文件并输出建议的分支
供用户复制的名称、提交消息和 PR 描述。
