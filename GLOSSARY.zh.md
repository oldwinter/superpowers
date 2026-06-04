# 中文翻译术语表

本仓库的中文版本翻译面向用户和 agent 的自然语言内容，同时保留会影响运行、引用、触发和法律含义的专有内容。

## 保留原文

- 产品、组织、人名和品牌：Superpowers、Claude Code、Codex、Codex CLI、Codex App、Factory Droid、Gemini CLI、OpenCode、Cursor、GitHub Copilot CLI、Anthropic、Prime Radiant、Jesse Vincent。
- 仓库、package、plugin、extension、marketplace、harness 名称和命令：例如 `obra/superpowers`、`superpowers@superpowers-marketplace`、`/plugin install`、`gemini extensions install`。
- skill 名、目录名、文件路径、配置键、状态码、API 名、变量名：例如 `brainstorming`、`subagent-driven-development`、`TodoWrite`、`DONE_WITH_CONCERNS`。
- 开发方法缩写和固定术语：TDD、RED-GREEN-REFACTOR、YAGNI、DRY、PR、SHA、HEAD、main、dev。
- URL、license 名称和法律文本中的固定表达。

## 统一译法

| English | 中文译法 |
| --- | --- |
| agent | agent |
| coding agent | coding agent |
| human partner | human partner（必要时解释为“人类伙伴”） |
| skill | skill |
| harness | harness |
| subagent | subagent |
| workflow | 工作流 |
| checkpoint | checkpoint |
| worktree | worktree |
| workspace | workspace |
| branch | branch |
| spec | spec |
| design document | design document |
| implementation plan | 实现计划 |
| code review | code review |
| spec compliance | spec compliance |
| code quality | code quality |
| root cause | root cause |
| baseline | baseline |

## 翻译原则

- 行为指令保持强度，不弱化 MUST、NEVER、STOP 等约束。
- 代码块、命令、Graphviz/DOT label、测试 prompt 和示例输入默认保持原文，除非它们只是说明性 prose。
- skill frontmatter 中的 `name` 保持原样；`description` 可翻译说明部分，但不改 skill 名或触发关键词。
- 语气保留原项目风格：直接、强约束、面向 agent 行为塑形。
