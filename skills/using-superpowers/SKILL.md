---
name: using-superpowers
description: 开始任何对话时使用 - 确立如何查找和使用 skills，要求在任何响应之前调用 skill，包括澄清问题
---

<SUBAGENT-STOP>
如果你是被派遣来执行特定任务的 subagent，请忽略此 skill。
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
如果你认为某项 skill 哪怕只有 1% 的可能适用于当前工作，也绝对必须调用该 skill。

如果某项 skill 适用于你的任务，你没有选择。你必须使用它。

这不可协商。你不能为自己找理由绕过去。
</EXTREMELY-IMPORTANT>

## The Rule

**在任何响应或操作之前调用相关或被请求的 skills**，包括澄清问题、探索代码库或检查文件。如果事实证明它不适合当前情况，你不必继续使用它。

**进入 plan mode 之前：** 如果你还没有 brainstorm，请先调用 brainstorming skill。

然后宣布“Using [skill] to [purpose]”，并严格遵循该 skill。如果它有 checklist，就为每一项创建 todo。

## Skill Priority

当多个 skills 适用时，process skills 优先；它们决定方法，然后由 implementation skills（frontend-design 等）执行。Brainstorming 和 systematic-debugging 是 Superpowers 最常见的 process skills，但这条规则适用于所有 skills。

- “Let's build X” -> 先用 superpowers:brainstorming，再用 implementation skills。
- “Fix this bug” -> 先用 superpowers:systematic-debugging，再用领域 skills。

## Red Flags

出现这些想法意味着停下；你正在合理化跳过流程：

| Thought | Reality |
|---------|---------|
| “这只是一个简单问题” | 问题也是任务。检查 skills。 |
| “我需要先了解更多上下文” | skill 检查先于澄清问题。 |
| “让我先探索代码库” | skills 会告诉你如何探索。先检查。 |
| “我可以快速检查 git/files” | 文件缺少对话上下文。检查 skills。 |
| “我先收集信息” | skills 会告诉你如何收集信息。 |
| “这不需要正式 skill” | 如果 skill 存在，就使用它。 |
| “我记得这个 skill” | skills 会演进。读取当前版本。 |
| “这不算任务” | 行动就是任务。检查 skills。 |
| “这个 skill 太重了” | 简单事情会变复杂。使用它。 |
| “我先做这一件小事” | 做任何事之前先检查。 |
| “这感觉很有产出” | 无纪律的行动会浪费时间。skills 用来防止这一点。 |
| “我知道它是什么意思” | 理解概念不等于使用 skill。调用它。 |

## Platform Adaptation

如果你的 harness 出现在这里，请读取对应参考文件了解特殊说明：

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`
- Hermes Agent: `references/hermes-tools.md`

## User Instructions

用户指令（CLAUDE.md、AGENTS.md、GEMINI.md 等文件，以及直接请求）优先于 skills；skills 则优先于默认行为。只有当你的人类伙伴明确要求跳过 skill workflow 或 instruction 时，才跳过它们。
