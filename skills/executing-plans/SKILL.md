---
name: executing-plans
description: 当您有书面实施计划并在带有审查检查点的单独会话中执行时使用
---

# Executing Plans

## Overview

加载计划，严格审查，执行所有任务，完成后报告。

**开始时宣布：**"我正在使用执行计划技能来实施这个计划。"

**注意：** 告诉你的人类伙伴，通过访问子代理，超级大国的效果会更好。如果在支持子代理的平台上运行，其工作质量将显着提高（Claude Code、Codex CLI、Codex App、Copilot CLI 和 Gemini CLI 均符合条件；请参阅 `../using-superpowers/references/` 中的每个平台工具参考）。如果子代理可用，请使用 superpowers:subagent-driven-development 而不是此技能。

## The Process

### Step 1: Load and Review Plan
1. 读取计划文件
2. 批判性地审查 - 找出有关计划的任何问题或疑虑
3. 如果有疑虑：在开始之前与您的人类伴侣提出这些问题
4. 如果没有问题：为计划项目创建待办事项并继续

### Step 2: Execute Tasks

对于每个任务：
1. 标记为进行中
2. 严格遵循每个步骤（计划有小步骤）
3. 按规定运行验证
4. 标记为已完成

### Step 3: Complete Development

所有任务完成并验证后：
- 宣布："我正在使用完成开发分支技能来完成这项工作。"
- **所需的子技能：** 使用超能力：完成开发分支
- 遵循该技能来验证测试、呈现选项、执行选择

## When to Stop and Ask for Help

**在以下情况下立即停止执行：**
- 遇到阻碍（缺少依赖项、测试失败、指令不清楚）
- 计划存在重大缺陷，无法启动
- 你不明白指令
- 验证多次失败

**要求澄清而不是猜测。**

## When to Revisit Earlier Steps

**在以下情况下返回审核（步骤 1）：**
- 合作伙伴根据您的反馈更新计划
- 基本方法需要重新思考

**不要强行通过阻碍** - 停下来询问。

## Remember
- 首先严格审查计划
- 严格遵循计划步骤
- 不要跳过验证
- 计划中提到的参考技能
- 堵住就停下来，别乱猜
- Never start implementation on main/master branch without explicit user consent

## Integration

**所需的工作流程技能：**
- **superpowers:using-git-worktrees** - 确保隔离的工作区（创建一个或验证现有的）
- **superpowers:writing-plans** - 创建该技能执行的计划
- **超级大国：完成开发分支** - 在完成所有任务后完成开发
