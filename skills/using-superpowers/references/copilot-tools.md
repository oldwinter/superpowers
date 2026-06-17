# Copilot CLI Tool Mapping

技能用行动说话（"派遣子代理"、"创建待办事项"、"读取文件"）。在 Copilot CLI 上，这些内容解析为以下工具。

|动作技能要求|副驾驶 CLI 等效项 |
|----------------------|----------------------|
|读取文件 | `view` |
|创建/编辑/删除文件 | `apply_patch`（Copilot CLI 没有单独的创建/edit/write 工具）|
|运行 shell 命令 | `bash` |
|搜索文件内容 | `rg`（ripgrep；Copilot CLI 不公开 `grep` 工具）|
|按名称查找文件 | `glob` |
|获取网址 | `web_fetch` |
|搜索网络 | `web_search` |
|调用技能 | `skill` |
|调度子代理（`Subagent (general-purpose):` 模板）| `task` 与 `agent_type: "general-purpose"`（其他接受的类型：`explore`、`task`、`code-review`、`research`、`configure-copilot`） |
|多个并行调度 |一次响应中多个 `task` 调用 |
|子代理状态/output/control | `read_agent`、`list_agents`、`write_agent` |
|任务跟踪（"创建待办事项"、"标记完成"）| `update_todo` |
|进入/退出计划模式|没有同等内容 - 留在主会议 |

## Instructions file

当技能提到"您的指令文件"时，在 Copilot CLI 上，这是存储库根目录下的 **`AGENTS.md`**。如果 `AGENTS.md` 和 `.github/copilot-instructions.md` 均存在，则 Copilot 会读取两者。

## Personal skills directory

用户级技能位于 **`~/.copilot/skills/`>**。 Copilot CLI 还可以识别与 Codex 和 Gemini CLI 共享的跨运行时别名 **`~/.agents/skills/`**。每个技能都是一个包含 `SKILL.md` 的子目录（带有 `name` 和 `description` frontmatter）。

## Async shell sessions

Copilot CLI 支持持久异步 shell 会话：

|工具|目的|
|------|---------|
| `bash` 与 `mode: "async"`（以及可选的 `detach: true`）|在后台启动长时间运行的命令；返回 `shellId` |
| `write_bash` |将输入发送到正在运行的异步会话 |
| `read_bash` |从异步会话读取输出 |
| `stop_bash` |终止异步会话 |
| `list_bash` |列出所有活动的 shell 会话 |

## Additional Copilot CLI tools

|工具|目的|
|------|---------|
| `store_memory` |为未来的会话保留有关代码库的事实 |
| `report_intent` |根据当前意图更新 UI 状态行 |
| `sql` |查询会话的 SQLite 数据库（todos、元数据）|
| `fetch_copilot_cli_documentation` |查找 Copilot CLI 文档 |
| GitHub MCP 工具 (`github-mcp-server-*`) |本机 GitHub API 访问（问题、PR、代码搜索）|
