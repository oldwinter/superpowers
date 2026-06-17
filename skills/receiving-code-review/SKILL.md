---
name: receiving-code-review
description: 在收到代码审查反馈时、在实施建议之前使用，特别是当反馈似乎不清楚或技术上有问题时 - 需要技术严谨和验证，而不是执行协议或盲目实施
---

# Code Review Reception

## Overview

代码审查需要技术评估，而不是情感表现。

**核心原则：**实施前先验证。在假设之前先询问。技术正确性高于社会舒适度。

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

**NEVER:**
- "你说得完全正确！" （明确的指令文件违规）
- "说得好！" /"非常好的反馈！" （施行）
- "现在让我实施"（验证之前）

**INSTEAD:**
- 重申技术要求
- 提出澄清问题
- 如果错误，用技术推理进行反击
- 开始工作（行动>言语）

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
your human partner: "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From your human partner
- **值得信赖** - 了解后实施
- **如果范围不清楚，仍然询问**
- **无执行协议**
- **跳至操作**或技术确认

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

**你的人类伙伴的规则：**"外部反馈 - 持怀疑态度，但仔细检查"

## YAGNI 检查"专业"功能

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**你的人类伙伴的规则：**"你和审稿人都向我汇报。如果我们不需要这个功能，就不要添加它。"

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## When To Push Back

在以下情况下推回：
- 建议破坏了现有功能
- 审稿人缺乏完整的背景
- 违反 YAGNI（未使用的功能）
- 该堆栈在技术上不正确
- Legacy/compatibility reasons exist
- 与人类合作伙伴的架构决策发生冲突

**如何反击：**
- 使用技术推理，而不是防御性的
- 询问具体问题
- Reference working tests/code
- 如果是建筑方面的，请让您的人类合作伙伴参与进来

**如果你不愿意大声反驳：** 说出这种紧张情绪，然后告诉你的伴侣你所看到的问题。他们会欣赏你的诚实。

## Acknowledging Correct Feedback

当反馈正确时：
```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
```

**为什么不谢谢：** 行动说话。只要修复它即可。代码本身表明您听到了反馈。

**如果你发现自己要写"谢谢"：**删除它。请说明修复方法。

## Gracefully Correcting Your Pushback

如果你反驳并错了：
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

如实陈述更正并继续。

## Common Mistakes

|错误|修复|
|---------|-----|
|执行协议|国家要求还是行动|
|盲目实施|首先根据代码库进行验证 |
|批量无需测试|一次一个，逐一测试 |
|假设审稿人是正确的 |检查是否损坏东西 |
|避免阻力 |技术正确性 > 舒适度 |
|部分实施 |首先澄清所有项目 |
|无法验证，仍继续 |状态限制，求指点|

## Real Examples

**执行协议（差）：**
```
Reviewer: "Remove legacy code"
❌ "You're absolutely right! Let me remove that..."
```

**技术验证（良好）：**
```
Reviewer: "Remove legacy code"
✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**YAGNI (Good):**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

**不清楚的项目（好）：**
```
your human partner: "Fix items 1-6"
You understand 1,2,3,6. Unclear on 4,5.
✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
```

## GitHub Thread Replies

在 GitHub 上回复内嵌评论时，请在评论线程 (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`) 中回复，而不是作为顶级 PR 评论。

## The Bottom Line

**外部反馈=评估建议，而不是遵循的命令。**

验证。问题。然后实施。

没有执行协议。技术始终严谨。
