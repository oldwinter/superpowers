# Gemini CLI Tool Mapping

技能用行动说话（"派遣子代理"、"创建待办事项"、"读取文件"）。在 Gemini CLI 上，这些解析为以下工具。

|动作技能要求| Gemini CLI 等效项 |
|----------------------|----------------------|
|读取文件 | `read_file` |
|一次读取多个文件 | `read_many_files` |
|创建一个新文件 | `write_file` |
|编辑文件 | `replace` |
|运行 shell 命令 | `run_shell_command` |
|搜索文件内容 | `grep_search` |
|按名称查找文件 | `glob` |
|列出文件和子目录 | `list_directory` |
|获取网址 | `web_fetch` |
|搜索网络 | `google_web_search` |
|调用技能 | `activate_skill` |
|调度子代理（`Subagent (general-purpose):` 模板）| `invoke_agent` 与 `agent_name: "generalist"`（可通过 `@generalist` 聊天语法调用 — 请参阅 [Subagent support](#subagent-support)）|
|多个并行调度 |同一响应中的多个 `invoke_agent` 调用 |
|任务跟踪（"创建待办事项"、"标记完成"）| `write_todos`（状态：待处理、进行中、已完成、已取消、已阻止）|

## Instructions file

当技能提到"您的指令文件"时，在 Gemini CLI 上，这是 **`GEMINI.md`>**。 Gemini CLI 分层加载 `GEMINI.md`：全局位于 `~/.gemini/GEMINI.md`、工作区目录及其祖先中的项目级文件以及工具访问这些目录中的文件时的子目录 `GEMINI.md` 文件。

## Personal skills directory

用户级技能位于 **`~/.gemini/skills/`**，**`~/.agents/skills/`** 作为跨运行时别名（与 Codex 和 Copilot CLI 共享）。当两个目录存在于同一范围时，`.agents/skills/` 优先。每个技能都是一个包含 `SKILL.md` 的子目录（带有 `name` 和 `description` frontmatter）。

## Subagent support

Gemini CLI 通过 `invoke_agent` 工具调度子代理，该工具采用 `agent_name` 和 `prompt` 参数。相同的调度也作为聊天语法快捷方式出现：输入 `@generalist <prompt>` 相当于使用 `agent_name: "generalist"` 调用 `invoke_agent`。内置代理名称包括 `generalist`、`cli_help`、`codebase_investigator` 和（启用浏览器工具）`browser_agent`。

使用 `Subagent (general-purpose):` 进行技能调度，并引用提示模板文件（例如 `superpowers:subagent-driven-development` 的 `./implementer-prompt.md`）或提供内联提示。在 Gemini CLI 上：

|技能派遣表| Gemini CLI 等效项 |
|---------------------|----------------------|
|引用 `*-prompt.md` 模板（实施者、任务审阅者、代码审阅者等）|填写模板，然后将 `invoke_agent` 与 `agent_name: "generalist"` 和填写的提示 |
|参考文献`superpowers:requesting-code-review`的`./code-reviewer.md` | `invoke_agent` 与 `agent_name: "generalist"` 以及已填写的审阅模板 |
|内联提示（未引用模板）| `invoke_agent` 与 `agent_name: "generalist"` 以及您的内联提示 |

### Prompt filling

技能提供带有占位符的提示模板，例如 `{WHAT_WAS_IMPLEMENTED}` 或 `[FULL TEXT of task]`。在将完整提示传递给 `invoke_agent` 之前，请填写所有占位符。提示模板本身包含代理的角色、审核标准和预期输出格式 - 子代理将遵循它。

### Parallel dispatch

Gemini CLI 支持并行子代理调度。在同一响应中发出多个 `invoke_agent` 调用（或在一个提示中发出多个 `@generalist` 调用）以并行运行独立的子代理工作。保持相关任务的顺序，但不要仅仅为了保留更简单的历史记录而序列化独立的子代理任务。

## Additional Gemini CLI tools

这些工具是 Gemini CLI 所独有的：

|工具|目的|
|------|---------|
| `save_memory`（旧版）|当 `experimental.memoryV2 = false` | 时，跨会话保留事实
| `get_internal_docs` |查找 Gemini CLI 的捆绑文档 |
| `ask_user` |向用户提出结构化问题（文本/单选/多选）|
| `enter_plan_mode` / `exit_plan_mode` |切换到和退出只读计划模式 |
| `update_topic` |更新当前对话的主题/战略意图元数据 |
| `complete_task` |发出 Gemini 子代理已完成的信号并将其结果返回给父代理 |
| `tracker_create_task`、`tracker_update_task`、`tracker_get_task`、`tracker_list_tasks`、`tracker_add_dependency`、`tracker_visualize` |具有依赖性和可视化支持的丰富任务跟踪器 |
| `read_mcp_resource`、`list_mcp_resources` | MCP资源访问 |
