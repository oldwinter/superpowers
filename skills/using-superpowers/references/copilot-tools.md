# Copilot CLI Tool Mapping

Skills 使用 Claude Code tool names。当你在 skill 中遇到这些名称时，使用你平台上的 equivalent：

| Skill references | Copilot CLI equivalent |
|-----------------|----------------------|
| `Read`（file reading） | `view` |
| `Write`（file creation） | `create` |
| `Edit`（file editing） | `edit` |
| `Bash`（run commands） | `bash` |
| `Grep`（search file content） | `grep` |
| `Glob`（search files by name） | `glob` |
| `Skill` tool（invoke a skill） | `skill` |
| `WebFetch` | `web_fetch` |
| `Task` tool（dispatch subagent） | `task` with `agent_type: "general-purpose"` or `"explore"` |
| 多个 `Task` calls（parallel） | 多个 `task` calls |
| Task status/output | `read_agent`, `list_agents` |
| `TodoWrite`（task tracking） | `sql` with built-in `todos` table |
| `WebSearch` | 无 equivalent，使用带 search engine URL 的 `web_fetch` |
| `EnterPlanMode` / `ExitPlanMode` | 无 equivalent，留在 main session |

## Async shell sessions

Copilot CLI 支持 persistent async shell sessions，它们没有直接的 Claude Code equivalent：

| Tool | Purpose |
|------|---------|
| `bash` with `async: true` | 在后台启动 long-running command |
| `write_bash` | 向 running async session 发送 input |
| `read_bash` | 读取 async session output |
| `stop_bash` | 终止 async session |
| `list_bash` | 列出所有 active shell sessions |

## Additional Copilot CLI tools

| Tool | Purpose |
|------|---------|
| `store_memory` | 为未来 sessions 持久化 codebase facts |
| `report_intent` | 更新 UI status line 的 current intent |
| `sql` | 查询 session SQLite database（todos, metadata） |
| `fetch_copilot_cli_documentation` | 查询 Copilot CLI documentation |
| GitHub MCP tools (`github-mcp-server-*`) | Native GitHub API access（issues, PRs, code search） |
