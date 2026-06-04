---
name: executing-plans
description: 当你有一份书面 implementation plan，并要在单独 session 中带 review checkpoints 执行时使用
---

# Executing Plans

## 概览

加载计划，严格 review，执行所有 tasks，完成后报告。

**开始时宣布：** "I'm using the executing-plans skill to implement this plan."

**注意：** 告诉你的 human partner，Superpowers 在能访问 subagents 时效果会好得多。如果运行在支持 subagent 的平台（例如 Claude Code 或 Codex），工作质量会显著更高。如果 subagents 可用，请使用 superpowers:subagent-driven-development，而不是这个 skill。

## 流程

### Step 1: 加载并 Review 计划
1. 读取 plan file
2. 严格 review：识别你对计划的任何问题或担忧
3. 如果有担忧：开始前先向你的 human partner 提出
4. 如果没有担忧：创建 TodoWrite 并继续

### Step 2: 执行 Tasks

对每个 task：
1. 标记为 in_progress
2. 严格遵循每个 step（plan 已拆成 bite-sized steps）
3. 按指定方式运行 verifications
4. 标记为 completed

### Step 3: 完成开发

所有 tasks 完成并验证后：
- 宣布："I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** 使用 superpowers:finishing-a-development-branch
- 遵循该 skill 验证测试、展示选项并执行选择

## 何时停下来求助

**遇到以下情况，立即 STOP 执行：**
- 遇到 blocker（缺少 dependency、test 失败、instruction 不清楚）
- 计划有 critical gaps，导致无法开始
- 你不理解某条 instruction
- Verification 反复失败

**要求澄清，而不是猜。**

## 何时回到前面步骤

**在以下情况回到 Review（Step 1）：**
- Partner 根据你的反馈更新了计划
- 基本方案需要重新思考

**不要硬闯 blockers**：停下来询问。

## 记住
- 先严格 review 计划
- 严格遵循计划 steps
- 不要跳过 verifications
- 当计划要求时引用 skills
- blocked 时停下，不要猜
- 没有用户明确同意，永远不要在 main/master branch 上开始 implementation

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - 确保存在 isolated workspace（创建或验证已有）
- **superpowers:writing-plans** - 创建本 skill 执行的计划
- **superpowers:finishing-a-development-branch** - 所有 tasks 完成后收尾开发
