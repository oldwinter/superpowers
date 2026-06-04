---
name: requesting-code-review
description: 完成 tasks、实现 major features，或 merge 前验证工作是否满足 requirements 时使用
---

# Requesting Code Review

分派一个 code reviewer subagent，在问题扩散前抓住它们。Reviewer 会获得精心组织的上下文来做评估，而不是继承你的 session history。这样 reviewer 会专注于 work product，而不是你的思考过程，同时保留你自己的 context 用于继续协调工作。

**核心原则：** 早 review，经常 review。

## 何时请求 Review

**Mandatory:**
- subagent-driven development 中每个 task 之后
- 完成 major feature 之后
- merge 到 main 之前

**Optional but valuable:**
- 卡住时（fresh perspective）
- refactoring 前（baseline check）
- 修复 complex bug 后

## 如何请求

**1. 获取 git SHAs：**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. 分派 code reviewer subagent：**

使用 Task tool，类型设为 `general-purpose`，填写 `code-reviewer.md` 中的 template。

**Placeholders:**
- `{DESCRIPTION}` - 简短概括你构建了什么
- `{PLAN_OR_REQUIREMENTS}` - 它应该做什么
- `{BASE_SHA}` - 起始 commit
- `{HEAD_SHA}` - 结束 commit

**3. 处理反馈：**
- 立即修复 Critical issues
- 继续前修复 Important issues
- 记录 Minor issues，稍后处理
- 如果 reviewer 错了，用 reasoning 反驳

## 示例

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

## 与 Workflows 集成

**Subagent-Driven Development:**
- 每个 task 后 review
- 在问题叠加前抓住它们
- 修复后再进入下一个 task

**Executing Plans:**
- 每个 task 后或自然 checkpoint 处 review
- 获取反馈、应用反馈、继续

**Ad-Hoc Development:**
- merge 前 review
- 卡住时 review

## Red Flags

**Never:**
- 因为 "it's simple" 就跳过 review
- 忽略 Critical issues
- 带着未修复的 Important issues 继续
- 和有效的技术反馈争辩

**如果 reviewer 错了：**
- 用技术 reasoning 反驳
- 展示能证明它工作的 code/tests
- 请求 clarification

Template 见：requesting-code-review/code-reviewer.md
