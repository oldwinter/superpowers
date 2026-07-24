---
name: requesting-code-review
description: 在完成任务、实现主要功能时或在合并之前使用以验证工作是否满足要求
---

# Requesting Code Review

派遣代码审阅者子代理，在问题级联之前发现问题。审阅者只获得为评估精确准备的上下文，而不是您的会话历史记录。

**核心原则：**早复习、常复习。

## When to Request Review

**Mandatory:**
- 子代理驱动开发中的每个任务之后
- 完成主要功能后
- 合并到主程序之前

**可选但有价值：**
- 当卡住时（新视角）
- 重构前（基线检查）
- 修复复杂的错误后

## How to Request

**1.获取 git SHA：**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2.派遣代码审阅者子代理：**

调度 `general-purpose` 子代理，填写 [code-reviewer.md](code-reviewer.md) 处的模板

**Placeholders:**
- `{DESCRIPTION}` - 您构建的内容的简要摘要
- `{PLAN_OR_REQUIREMENTS}` - 它应该做什么
- `{BASE_SHA}` - 开始提交
- `{HEAD_SHA}` - 结束提交

**3.根据反馈采取行动：**
- 立即修复关键问题
- 在继续之前修复重要问题
- 注意稍后的小问题
- 如果审稿人错了就退回（有推理）

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## 常见合理化借口

| 借口 | 事实 |
|------|------|
| “我直接自己看 diff 就行，不用派审阅者” | 你是协调者；在当前上下文里阅读全文会消耗继续驱动工作的上下文窗口。派出审阅子代理，让 diff 和评估留在它的上下文中，只把 findings 带回来。 |
| “审阅者需要我的完整会话历史才能理解变更” | 给它精确准备的上下文，而不是会话历史。这样审阅者会专注于工作产物，而不是你的思考过程。 |

## Red Flags

**Never:**
- 跳过评论，因为"很简单"
- 忽略关键问题
- 继续处理未解决的重要问题
- 用有效的技术反馈进行争论

**如果审稿人错误：**
- 用技术推理进行反击
- Show code/tests that prove it works
- Request clarification

请参阅模板：[code-reviewer.md](code-reviewer.md)
