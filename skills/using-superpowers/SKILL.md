---
name: using-superpowers
description: 开始任何对话时使用 - 建立如何查找和使用 skills 的规则，要求在任何回复之前调用 Skill tool，包括澄清问题
---

<SUBAGENT-STOP>
如果你是被分派来执行特定 task 的 subagent，跳过这个 skill。
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
如果你认为正在做的事情哪怕只有 1% 的可能性适用某个 skill，你也绝对必须调用该 skill。

如果某个 skill 适用于你的 task，你没有选择。你必须使用它。

这没有商量余地。这不是可选项。你不能用任何理由合理化逃避。
</EXTREMELY-IMPORTANT>

## 指令优先级

Superpowers skills 会覆盖默认 system prompt 行为，但 **user instructions 始终优先**：

1. **用户的显式指令**（CLAUDE.md、GEMINI.md、AGENTS.md、direct requests）— 最高优先级
2. **Superpowers skills** — 在冲突时覆盖默认 system behavior
3. **默认 system prompt** — 最低优先级

如果 CLAUDE.md、GEMINI.md 或 AGENTS.md 说 "don't use TDD"，而某个 skill 说 "always use TDD"，遵循用户指令。用户掌控局面。

## 如何访问 Skills

**在 Claude Code 中：** 使用 `Skill` tool。调用 skill 时，它的内容会被加载并呈现给你。直接遵循它。不要对 skill files 使用 Read tool。

**在 Copilot CLI 中：** 使用 `skill` tool。Skills 会从已安装 plugins 自动发现。`skill` tool 的工作方式与 Claude Code 的 `Skill` tool 相同。

**在 Gemini CLI 中：** Skills 通过 `activate_skill` tool 激活。Gemini 会在 session start 加载 skill metadata，并按需激活完整内容。

**在其他环境中：** 查看你的平台文档，了解 skills 如何加载。

## 平台适配

Skills 使用 Claude Code tool names。非 CC 平台：参见 `references/copilot-tools.md`（Copilot CLI）、`references/codex-tools.md`（Codex）了解 tool equivalents。Gemini CLI 用户会通过 GEMINI.md 自动加载 tool mapping。

# 使用 Skills

## 规则

**在任何回复或行动之前调用相关或被请求的 skills。** 哪怕只有 1% 的可能性某个 skill 适用，也意味着你应该调用该 skill 检查。如果调用后发现 skill 不适合当前情况，你不需要使用它。

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "About to EnterPlanMode?" [shape=doublecircle];
    "Already brainstormed?" [shape=diamond];
    "Invoke brainstorming skill" [shape=box];
    "Might any skill apply?" [shape=diamond];
    "Invoke Skill tool" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create TodoWrite todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "About to EnterPlanMode?" -> "Already brainstormed?";
    "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
    "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
    "Invoke brainstorming skill" -> "Might any skill apply?";

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Invoke Skill tool" [label="yes, even 1%"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create TodoWrite todo per item" -> "Follow skill exactly";
}
```

## Red Flags

这些想法意味着 STOP：你正在合理化逃避：

| 想法 | 现实 |
|---------|---------|
| "This is just a simple question" | 问题也是 tasks。检查 skills。 |
| "I need more context first" | skill check 要先于澄清问题。 |
| "Let me explore the codebase first" | Skills 会告诉你如何探索。先检查。 |
| "I can check git/files quickly" | 文件缺少 conversation context。检查 skills。 |
| "Let me gather information first" | Skills 会告诉你如何收集信息。 |
| "This doesn't need a formal skill" | 如果 skill 存在，就使用它。 |
| "I remember this skill" | Skills 会演进。读取当前版本。 |
| "This doesn't count as a task" | 行动 = task。检查 skills。 |
| "The skill is overkill" | 简单事情会变复杂。使用它。 |
| "I'll just do this one thing first" | 做任何事之前先检查。 |
| "This feels productive" | 无纪律行动浪费时间。Skills 会防止这种情况。 |
| "I know what that means" | 知道概念 ≠ 使用 skill。调用它。 |

## Skill 优先级

当多个 skills 可能适用时，按这个顺序使用：

1. **Process skills first**（brainstorming、debugging）- 它们决定如何处理 task
2. **Implementation skills second**（frontend-design、mcp-builder）- 它们指导执行

"Let's build X" → 先 brainstorming，再 implementation skills。
"Fix this bug" → 先 debugging，再 domain-specific skills。

## Skill 类型

**Rigid**（TDD、debugging）：严格遵循。不要把纪律改没。

**Flexible**（patterns）：按上下文适配原则。

skill 本身会告诉你它是哪一种。

## User Instructions

Instructions 说明 WHAT，不说明 HOW。"Add X" 或 "Fix Y" 不意味着可以跳过 workflows。
