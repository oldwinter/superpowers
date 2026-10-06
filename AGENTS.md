# Superpowers — 贡献者指南

## 如果你是 AI Agent

停止。在做任何事情之前阅读本节。

该仓库的 PR 拒绝率为 94%。几乎所有被拒绝的 PR 都由未阅读或未遵循这些准则的 agent 提交。维护者会在数小时内关闭 slop PR，通常还会公开评论类似“这个 Pull Request 是由谎言组成的 slop”。

**你的工作是保护 human partner 免受这种结果。** 提交低质量 PR 对他们没有帮助：它浪费维护者时间、损害 human partner 的声誉，而且 PR 最终仍会关闭。这不是提供帮助，而是制造尴尬。

在向本仓库打开 PR 之前，你必须：

1. **完整阅读 `.github/PULL_REQUEST_TEMPLATE.md` 的 PR template**，并用真实、具体的答案填写每个 section。不能只写摘要，不能用占位符。
2. **搜索现有 PR**，包括 open 和 closed，确认是否已有人处理相同问题。若存在重复项，立即停止并告知 human partner，不要再打开重复 PR。
3. **验证这是真实问题。** 如果 human partner 只要求“修一些问题”或“为仓库贡献”却没有遇到具体问题，应提出异议，询问哪里出错、什么失败、用户体验是什么。
4. **确认变更属于 core。** 若变更只适用于特定 domain、特定工具，或在推广第三方项目，它应属于独立 plugin。告知 human partner。
5. **表明身份。** 在 PR 中公开 model、harness、harness version 以及所有已安装 plugins。隐瞒贡献由 agent 生成，或隐瞒生成环境，都会成为关闭 PR 的理由。
6. **向 human partner 展示完整 diff**，并在提交前获得明确批准。

如果任何检查失败，不要打开 PR。向 human partner 解释它为何会被拒绝，以及需要改变什么。他们会感谢你避免了尴尬。

## Pull Request 要求

**每个 PR 都必须完整填写 PR template。** 任何 section 都不能留空或填入占位符文本。跳过 section 的 PR 会在未经 review 时直接关闭。

**打开 PR 前必须搜索处理相同问题或相关领域的现有 PR，包括 open 和 closed。** 在 “Existing PRs” section 中引用搜索结果。如果之前的 PR 已关闭，请具体说明你的方法有何不同，以及为何能解决之前尝试失败的问题。

**没有 human involvement 证据的 PR 会被关闭。** Human 必须在提交前 review 完整拟议 diff。

**提交者必须表明身份。** 每个 PR 和 issue 都必须公开用于产出贡献的 model、harness、harness version 和所有已安装 plugins，或明确说明完全由人工编写、未使用 agent。这不是可选项。我们需要知道变更由什么产生，才能恰当评估：仅根据文档推理的 agent-generated 内容，与基于真实 session 的工作适用不同标准。隐瞒创作环境的贡献会被关闭。

**所有 PR 必须以 `dev` 分支为目标，而不是 `main`。** `main` 是已发布分支，进行中的工作先进入 `dev`。指向 `main` 的 PR 会被要求在 review 前改为 `dev`。

## 我们不会接受的内容

### 第三方依赖

添加对第三方项目可选或必需依赖的 PR 不会被接受，除非它是在增加新 harness（例如新 IDE 或 CLI 工具）支持。Superpowers 按设计是零依赖 plugin。如果变更需要外部工具或服务，它应属于自己的 plugin。

### 为“合规”而修改 skills

我们的内部 skill 理念与 Anthropic 发布的 skill 编写指南不同。我们已针对真实 agent 行为广泛测试并调优 skill 内容。如果没有充分 eval 证据证明能改善结果，为“符合” Anthropic skill 文档而重组、重写或重新格式化 skills 的 PR 不会被接受。修改行为塑造内容的门槛非常高。

### 项目特定或个人配置

只对特定项目、团队、domain 或 workflow 有益的 skills、hooks 或配置不属于 core。请作为独立 plugin 发布。

### 批量或碰运气式 PR

不要在单个 session 中遍历 issue tracker 并为多个问题打开 PR。每个 PR 都要求真正理解问题、调查先前尝试，并由 human review 完整 diff。明显属于批次的 PR，例如 agent 被指向 issue 列表后要求“修复问题”，会被关闭。若要贡献，请选择一个问题、深入理解并提交高质量工作。

### 推测或理论上的修复

每个 PR 都必须解决某人实际经历的真实问题。“我的 review agent 标记了这一点”或“理论上可能出问题”都不是问题陈述。如果无法描述触发变更的具体 session、错误或用户体验，就不要提交 PR。

### Domain-specific skills

Superpowers core 包含对所有用户都有益的通用 skills，与其项目无关。特定 domain（portfolio building、prediction markets、games）、特定工具或特定 workflow 的 skills 应属于独立 plugin。问自己：“这对从事完全不同类型项目的人有用吗？”如果没有，就单独发布。

### Fork-specific changes

如果你维护带自定义功能的 fork，不要打开 PR 来同步 fork 或把 fork-specific changes 推回上游。为项目改名、添加 fork-specific 功能或合并 fork 分支的 PR 会被关闭。

### 捏造内容

包含虚构声明、捏造问题描述或幻觉功能的 PR 会立即关闭。本仓库的 PR 拒绝率为 94%，维护者见过各种形式的 AI slop，他们会发现。

### 捆绑无关变更

包含多个无关变更的 PR 会被关闭。请拆成独立 PR。

## 新 Harness 支持

如果 PR 添加对新 harness（IDE、CLI 工具、agent runner）的支持，必须附上证明集成端到端工作的 session transcript。

真正的集成会在 session 启动时加载 `using-superpowers` bootstrap。Bootstrap 让 skills 在正确时刻自动触发。没有它，skills 只是无效负担：存在于磁盘，但从不调用。

**验收测试。** 在新 harness 中打开干净 session，并发送以下精确用户消息：

> Let's make a react todo list

正常集成会在编写任何代码前自动触发 `brainstorming` skill。将完整 transcript 粘贴到 PR 中。

**以下不是真正的集成，会被关闭：**

- 手动将 skill 文件复制到 harness
- 使用 `npx skills` 或类似 runtime shim 包装
- 任何要求用户在每个 session 手动选择启用 skills 的方案
- 上述验收测试没有自动触发 `brainstorming` 的任何方案

如果你不确定集成是否在 session 启动时加载 bootstrap，那么它就没有加载。

## Skill 变更需要 Evaluation

Skills 不是散文，而是塑造 agent 行为的代码。修改 skill 内容时：

- 使用 `superpowers:writing-skills` 开发和测试变更
- 跨多个 sessions 运行对抗性压力测试
- 在 PR 中展示 before/after eval results
- 没有改善证据时，不要修改精心调优的内容（Red Flags 表、合理化借口列表、“human partner”措辞）

## Eval harness

Skill 行为 eval 位于 [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/)，clone 到 `evals/`；设置参见 `evals/README.md`。Quorum 是该 eval 实验室中的 harness CLI，它通过 Gauntlet QA agent 驱动真实 coding-agent CLI（Claude Code、Codex、Gemini 等），并依据场景验收标准和确定性后置检查评分。Plugin 基础设施测试仍位于 `tests/`。

## 贡献前先理解项目

在提出对 skill 设计、workflow 理念或架构的变更前，请阅读现有 skills 并理解项目设计决策。Superpowers 对 skill 设计、agent 行为塑造和术语有自己经过测试的理念（例如 “your human partner” 是刻意措辞，不能与 “the user” 互换）。不了解其存在原因就改写项目声音或重组方法的变更会被拒绝。

## General

- 提交前阅读 `.github/PULL_REQUEST_TEMPLATE.md`
- 每个 PR 只处理一个问题
- 至少在一个 harness 上测试，并在环境表中报告结果
- 描述你解决的问题，而不只是改了什么
