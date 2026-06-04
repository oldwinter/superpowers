# Gemini CLI Tool Mapping

Skills 使用 Claude Code tool names。当你在 skill 中遇到这些名称时，使用你平台上的 equivalent：

| Skill references | Gemini CLI equivalent |
|-----------------|----------------------|
| `Read`（file reading） | `read_file` |
| `Write`（file creation） | `write_file` |
| `Edit`（file editing） | `replace` |
| `Bash`（run commands） | `run_shell_command` |
| `Grep`（search file content） | `grep_search` |
| `Glob`（search files by name） | `glob` |
| `TodoWrite`（task tracking） | `write_todos` |
| `Skill` tool（invoke a skill） | `activate_skill` |
| `WebSearch` | `google_web_search` |
| `WebFetch` | `web_fetch` |
| `Task` tool（dispatch subagent） | `@agent-name`（见 [Subagent support](#subagent-support)） |

## Subagent support

Gemini CLI 通过 `@` syntax 原生支持 subagents。使用 built-in `@generalist` agent dispatch 任意 task：它可访问所有 tools，并遵循你提供的 prompt。

当 skill 要求 dispatch 某个 named agent type 时，使用 `@generalist` 并填入该 skill prompt template 的完整 prompt：

| Skill instruction | Gemini CLI equivalent |
|-------------------|----------------------|
| `Task tool (superpowers:implementer)` | `@generalist` with the filled `implementer-prompt.md` template |
| `Task tool (superpowers:spec-reviewer)` | `@generalist` with the filled `spec-reviewer-prompt.md` template |
| `Task tool (superpowers:code-reviewer)` | `@code-reviewer`（bundled agent）或 `@generalist` with the filled review prompt |
| `Task tool (superpowers:code-quality-reviewer)` | `@generalist` with the filled `code-quality-reviewer-prompt.md` template |
| `Task tool (general-purpose)` with inline prompt | `@generalist` with your inline prompt |

### Prompt filling

Skills 提供带 placeholders 的 prompt templates，例如 `{WHAT_WAS_IMPLEMENTED}` 或 `[FULL TEXT of task]`。填完所有 placeholders，并把完整 prompt 作为 message 传给 `@generalist`。Prompt template 本身包含 agent role、review criteria 和 expected output format；`@generalist` 会遵循它。

### Parallel dispatch

Gemini CLI 支持 parallel subagent dispatch。当 skill 要求你并行 dispatch 多个 independent subagent tasks 时，在同一个 prompt 中一起请求所有这些 `@generalist` 或 named subagent tasks。Dependent tasks 保持 sequential，但不要仅为了保持更简单的 history 而串行化 independent subagent tasks。

## Additional Gemini CLI tools

这些 tools 在 Gemini CLI 中可用，但没有 Claude Code equivalent：

| Tool | Purpose |
|------|---------|
| `list_directory` | 列出 files 和 subdirectories |
| `save_memory` | 将 facts 持久化到 GEMINI.md，供未来 sessions 使用 |
| `ask_user` | 向用户请求 structured input |
| `tracker_create_task` | Rich task management（create, update, list, visualize） |
| `enter_plan_mode` / `exit_plan_mode` | 修改前切换到 read-only research mode |
