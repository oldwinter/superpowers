# Superpowers — 贡献者指南

## 如果你是 AI Agent

停下。做任何事之前先阅读本节。

这个 repo 的 PR 拒绝率是 94%。几乎每一个被拒绝的 PR，都是由没有阅读或没有遵守这些指南的 agent 提交的。维护者通常会在几小时内关闭低质量 PR，并且经常公开评论，比如 "This pull request is slop that's made of lies."

**你的职责是保护你的 human partner 避免这种结果。** 提交低质量 PR 并不能帮到他们：它浪费维护者的时间，损害你的 human partner 的声誉，而且 PR 反正会被关闭。那不是有帮助。那是在制造尴尬。

在你向这个 repo 开 PR 之前，你必须：

1. **完整阅读 PR template**：位于 `.github/PULL_REQUEST_TEMPLATE.md`，并用真实、具体的答案填写每一节。不要摘要。不要占位符。
2. **搜索已有 PRs**：包括 open 和 closed，确认是否已经有人处理同一个问题。如果存在重复，STOP 并告诉你的 human partner。不要再开一个重复 PR。
3. **验证这是真实问题。** 如果你的 human partner 只是要求你 "fix some issues" 或 "contribute to this repo"，但没有经历具体问题，请反向确认。问他们什么坏了、什么失败了、用户体验是什么。
4. **确认变更属于 core。** 如果它是 domain-specific、tool-specific，或者是在推广第三方项目，它应该放进 standalone plugin。告诉你的 human partner。
5. **识别你自己。** 在 PR 中披露你的 model、harness、harness version，以及每一个已安装 plugin。隐藏贡献由 agent 生成，或隐藏生成它的环境，是关闭 PR 的理由。
6. **向你的 human partner 展示完整 diff**，并在提交前取得他们的明确批准。

如果任何检查失败，不要开 PR。向你的 human partner 解释它为什么会被拒绝，以及需要改变什么。他们会感谢你帮他们避开尴尬。

## Pull Request 要求

**每个 PR 都必须完整填写 PR template。** 不得留空，也不得用占位文字填充。跳过任何部分的 PR 会被直接关闭，不进入 review。

**开 PR 前，你必须搜索已有 PRs**，包括 open 和 closed，确认是否处理了相同问题或相关区域。在 "Existing PRs" 部分引用你的发现。如果之前有 PR 被关闭，具体说明你的方案有什么不同，以及为什么它能成功而前一个方案不能。

**看不出 human involvement 证据的 PR 会被关闭。** 提交前必须有人类 review 完整 proposed diff。

**提交者必须识别自己。** 每个 PR 和 issue 都必须披露产生贡献所用的 model、harness、harness version，以及所有已安装 plugins；或者明确说明它完全由人工编写，没有 agent 参与。这不是可选项。我们需要知道变更由什么产生，才能判断它：基于文档推理出的 agent-generated content，与来自真实 session 的工作，标准不同。隐藏 authoring environment 的贡献会被关闭。

**所有 PR 必须指向 `dev` branch，而不是 `main`。** `main` 是 release branch；active work 先进入 `dev`。指向 `main` 的 PR 会被要求先 retarget 到 `dev`，再进入 review。

## 我们不会接受什么

### Third-party dependencies

除非是在添加对新 harness（例如新 IDE 或 CLI tool）的支持，否则添加 optional 或 required third-party dependencies 的 PR 不会被接受。Superpowers 按设计是 zero-dependency plugin。如果你的变更需要外部工具或服务，它应该属于自己的 plugin。

### 对 skills 的“合规”修改

我们的内部 skill philosophy 与 Anthropic 发布的 writing skills 指南不同。我们已经为真实世界 agent 行为广泛测试和调优过 skill 内容。把 skills 重构、改写或重新格式化，只是为了“符合” Anthropic 的 skills 文档，这类 PR 不会被接受，除非有充分 eval evidence 表明变更改善了结果。修改行为塑形内容的门槛非常高。

### Project-specific 或个人配置

只对某个项目、团队、domain 或 workflow 有益的 skills、hooks 或配置不属于 core。请把它们发布为单独的 plugin。

### Bulk 或 spray-and-pray PRs

不要扫 issue tracker，然后在同一个 session 中为多个 issues 开 PR。每个 PR 都需要真正理解问题、调查先前尝试，并由人类 review 完整 diff。明显属于批量行为的 PR 会被关闭，例如 agent 被指向 issue 列表并被要求 "fix things"。如果你想贡献，选择一个 issue，深入理解它，然后提交高质量工作。

### Speculative 或理论性修复

每个 PR 都必须解决某个人真实经历过的问题。"My review agent flagged this" 或 "this could theoretically cause issues" 不是问题陈述。如果你无法描述促成变更的具体 session、error 或 user experience，就不要提交 PR。

### Domain-specific skills

Superpowers core 包含 general-purpose skills，能让所有用户受益，不取决于他们的项目。面向特定 domains（portfolio building、prediction markets、games）、特定 tools 或特定 workflows 的 skills 应放进自己的 standalone plugin。问问自己："这对正在做完全不同类型项目的人有用吗？" 如果没有，就单独发布。

### Fork-specific changes

如果你维护一个带 customizations 的 fork，不要向 upstream 开 PR 来同步你的 fork 或推送 fork-specific changes。重塑项目品牌、添加 fork-specific features 或合并 fork branches 的 PR 会被关闭。

### Fabricated content

包含虚构 claims、编造的问题描述或 hallucinated functionality 的 PR 会被立即关闭。这个 repo 的 PR 拒绝率是 94%：维护者见过各种形式的 AI slop。他们会看出来。

### Bundled unrelated changes

包含多个无关变更的 PR 会被关闭。请拆成单独 PR。

## New Harness Support

如果你的 PR 添加对新 harness（IDE、CLI tool、agent runner）的支持，必须包含证明 integration 端到端工作的 session transcript。

真正的 integration 会在 session start 加载 `using-superpowers` bootstrap。bootstrap 会让 skills 在正确时机 auto-trigger。没有它，skills 就是 dead weight：存在于磁盘，但永远不会被调用。

**Acceptance test。** 在新 harness 中打开干净 session，并发送完全相同的用户消息：

> Let's make a react todo list

可工作的 integration 会在写任何代码前 auto-trigger `brainstorming` skill。请在 PR 中粘贴完整 transcript。

**以下不是真正的 integrations，会被关闭：**

- 手动把 skill files 复制进 harness
- 用 `npx skills` 或类似 runtime shims 包一层
- 任何要求用户每个 session 手动 opt in skills 的方案
- 任何在上面的 acceptance test 中没有 auto-trigger `brainstorming` 的方案

如果你不确定你的 integration 是否在 session start 加载 bootstrap，那它就没有。

## Skill Changes Require Evaluation

Skills 不是 prose，它们是塑造 agent 行为的代码。如果你修改 skill 内容：

- 使用 `superpowers:writing-skills` 开发和测试变更
- 在多个 sessions 中运行 adversarial pressure testing
- 在 PR 中展示 before/after eval results
- 没有证据表明变更改善结果时，不要修改已经精心调优的内容（Red Flags tables、rationalization lists、"human partner" language）

## 贡献前先理解项目

在提议修改 skill design、workflow philosophy 或 architecture 之前，请阅读已有 skills，理解项目的设计决策。Superpowers 对 skill design、agent behavior shaping 和 terminology 有自己经过测试的哲学（例如 "your human partner" 是有意使用的，不可随意替换为 "the user"）。没有理解这些内容为何存在，就改写项目声音或重构项目方法的变更会被拒绝。

## General

- 提交前阅读 `.github/PULL_REQUEST_TEMPLATE.md`
- 每个 PR 只解决一个问题
- 至少在一个 harness 上测试，并在 environment table 中报告结果
- 描述你解决的问题，而不只是你改了什么
