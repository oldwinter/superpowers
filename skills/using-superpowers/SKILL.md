---
name: using-superpowers
description: 开始任何对话时使用 - 确定如何查找和使用技能，要求在任何响应之前调用技能，包括澄清问题
---

<SUBAGENT-STOP>
如果您被派遣为子代理来执行特定任务，请跳过此技能。
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
如果您认为某项技能有 1% 的机会适用于您正在做的事情，那么您绝对必须调用该技能。

如果某项技能适用于您的任务，您就别无选择。你必须使用它。

这是没有商量余地的。这不是可选的。你无法合理化自己的出路。
</EXTREMELY-IMPORTANT>

## Instruction Priority

超能力技能会覆盖默认的系统提示行为，但**用户指令始终优先**：

1. **用户的显式指令**（CLAUDE.md、GEMINI.md、AGENTS.md、直接请求）- 最高优先级
2. **超能力技能** — 覆盖它们冲突的默认系统行为
3. **默认系统提示** — 最低优先级

如果CLAUDE.md、GEMINI.md或AGENTS.md说"不要使用TDD"并且技能说"总是使用TDD"，请按照用户的说明进行操作。用户处于控制之中。

## 如何访问 Skills

**切勿使用文件工具手动读取技能文件** - 始终使用平台的技能加载机制，以便正确激活技能。

**在克劳德代码中：** 使用 `Skill` 工具。当您调用一项技能时，它的内容将被加载并呈现给您 - 直接跟随它。

**在法典中：** 技能本地加载。按照技能激活时显示的说明进行操作。

**在 Copilot CLI 中：** 使用 `skill` 工具。技能是从安装的插件中​​自动发现的。

**在 Gemini CLI 中：** 技能通过 `activate_skill` 工具激活。 Gemini 在会话开始时加载技能元数据并按需激活完整内容。

**在其他环境中：** 检查您的平台文档以了解如何加载技能。

## Platform Adaptation

技能用行动来说话（"调度子代理"、"创建待办事项"、"读取文件"），而不是命名任何一个运行时的工具。有关每个平台的等效工具和指令文件约定，请参阅 [claude-code-tools.md](references/claude-code-tools.md)、[codex-tools.md](references/codex-tools.md)、[copilot-tools.md](references/copilot-tools.md)、[gemini-tools.md](references/gemini-tools.md)、[pi-tools.md](references/pi-tools.md) 和 [antigravity-tools.md](references/antigravity-tools.md)。 Gemini CLI 用户通过 GEMINI.md 自动加载工具映射。

# Using Skills

## The Rule

**在任何响应或操作之前调用相关或请求的技能。** 即使某项技能适用的可能性只有 1%，也意味着您应该调用该技能进行检查。如果调用的技能被证明不适合当前情况，则您不需要使用它。

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "About to enter plan mode?" [shape=doublecircle];
    "Already brainstormed?" [shape=diamond];
    "Invoke brainstorming skill" [shape=box];
    "Might any skill apply?" [shape=diamond];
    "Invoke the skill" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create a todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "About to enter plan mode?" -> "Already brainstormed?";
    "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
    "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
    "Invoke brainstorming skill" -> "Might any skill apply?";

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Invoke the skill" [label="yes, even 1%"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Invoke the skill" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create a todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create a todo per item" -> "Follow skill exactly";
}
```

## Red Flags

这些想法意味着停止——你正在合理化：

|思想|现实|
|---------|---------|
| "这只是一个简单的问题" |问题就是任务。检查技能。 |
| "我首先需要更多背景信息" |技能检查先于澄清问题。 |
| "让我先探索一下代码库"|技能告诉您如何探索。先检查一下。 |
| "我可以快速检查 git/files"|文件缺乏对话上下文。检查技能。 |
| "我先收集一下信息"|技能告诉您如何收集信息。 |
| "这不需要正式的技能" |如果存在技能，就使用它。 |
| "我记得这个技能"|技能不断发展。阅读当前版本。 |
| "这不算是任务"|行动=任务。检查技能。 |
| "技能太过分了"|简单的事情变得复杂。使用它。 |
| "我先做一件事" |做任何事情之前先检查一下。 |
| "这感觉很有成效" |无纪律的行动会浪费时间。技能可以防止这种情况发生。 |
| "我知道这意味着什么" |了解概念≠使用技能。调用它。 |

## Skill Priority

当可以应用多种技能时，请使用以下顺序：

1. **首先是流程技能**（头脑风暴、系统调试）-这些决定了如何处理任务
2. **实施技巧第二**（前端设计、mcp-builder）-这些指导执行

"让我们构建X"→首先集思广益，然后是实施技巧。
"修复这个错误"→首先系统调试，然后是特定领域的技能。

## Skill Types

**严格**（TDD，系统调试）：严格遵循。不要适应纪律。

**灵活**（模式）：根据具体情况调整原则。

技能本身会告诉你哪个。

## User Instructions

说明说的是"做什么"，而不是"如何做"。 "添加 X"或"修复 Y"并不意味着跳过工作流程。
