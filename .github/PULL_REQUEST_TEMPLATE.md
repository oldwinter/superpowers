<!--
提交前：阅读本模板的每一个字。留空 section、包含多个无关变更，
或没有 human 参与证据的 PR 会在未经 review 的情况下关闭。
-->

> **这个 PR 必须 target `dev` branch，而不是 `main`。** `main` 是
> released branch；active work 会先进入 `dev`。指向 `main` 的 PR
> 会在 review 前被要求 retarget 到 `dev`。
>
> **本项目不接受由 agent 编写、用于修复他人提交 issue 的 PR**，
> 即使你的 human partner 遇到了相同问题。如果你在 tracker 中发现
> 一个 issue，并在没有 maintainer 要求的情况下决定提交 PR，你是在
> 浪费 token：PR 会被关闭。请改为把你的报告添加到该 issue。

## 谁在提交这个 PR？（必填）
<!-- 必填。遗漏此项的 PR 会被关闭。我们假设这是 agent 写的 PR——
     请告诉我们是哪一个、它在哪里运行，以及你的 human partner
     要求你做什么。我们会按产生内容的来源衡量贡献：从文档推理出的
     content 与基于真实 session 的工作，标准不同。 -->

| 字段 | 值 |
|-------|-------|
| 你的 model + 版本 | |
| Harness + 版本 | |
| 已安装的所有 plugins | |
| review 过此 diff 的 human partner | |

你的 human partner 要求你做什么，用他们的原话：
<!-- 尽量逐字记录。如果你完全手工编写此 PR、没有使用 agent，请说明。 -->

## Human 撰写的摘要（必填，200 字以内）
<!-- 由 human 用自己的话撰写：为什么存在此 PR，以及他们在批准前
     检查了什么。如果由 agent 提交，这里的 human 指你的 human partner，
     而不是你。 -->

## 你想解决什么问题？
<!-- 描述你遇到的具体问题。如果这是 session issue，请包含：
     你在做什么、出了什么问题、model 的精确 failure mode，
     最好还有 transcript 或 session log。

     “改进”某物不是问题陈述。什么坏了？什么失败了？是什么用户
     体验促成了这个变更？ -->

## 这个 PR 改了什么？
<!-- 1-3 句话。说是什么，而不是为什么——为什么应写在上方。 -->

## 这个变更是否适合 core library？
<!-- Superpowers core 包含对所有用户都有益的通用 skills 和基础设施。
     问自己：

     - 这对从事与你完全不同的项目的人有用吗？
     - 这是项目特定、团队特定或工具特定的吗？
     - 这是否集成或推广第三方服务？

     如果你的变更是针对特定 domain、workflow 工具或第三方集成的
     新 skill，它应属于独立 plugin——而不是这里。请参阅 plugin
     开发文档了解如何单独发布。 -->

## 你考虑过哪些替代方案？
<!-- 在最终采用此方案前，你尝试或评估过哪些其他方法？为什么它们
     更差？如果你没有考虑替代方案，请说明——但要知道这是一个红旗。 -->

## 这个 PR 是否包含多个无关变更？
<!-- 如果是：停止。拆成独立 PR。捆绑的 PR 会被关闭。
     如果你认为这些变更是相关的，请解释依赖关系。 -->

## 现有 PRs
- [ ] 我已检查所有 open 和 closed PRs，确认没有重复或先前工作
- 相关 PRs：<!-- #number、#number，或“未找到” -->

<!-- 如果存在相关的已关闭 PR，请解释你的方法有何不同，
     以及为何能解决之前尝试失败的问题。 -->

## 测试过的环境

| Harness（例如 Claude Code、Cursor） | Harness 版本 | Model | Model 版本/ID |
|-------------------------------------|-----------------|-------|------------------|
|                                     |                 |       |                  |

## 新 harness 支持（如果此 PR 添加新 harness 则必填）

<!-- 如果此 PR 添加对新 harness（IDE、CLI 工具、agent runner）的支持，
     你必须附上证明集成真正工作的 session transcript。

     真正的集成会在 session 启动时加载 `using-superpowers` bootstrap。
     Bootstrap 让 skills 在正确时刻自动触发。没有它，skills 只是无效负担：
     存在于磁盘，但从不调用。

     验收测试：在新 harness 中打开干净 session，并发送以下精确用户消息：

         Let's make a react todo list

     正常集成会在编写任何代码前自动触发 `brainstorming` skill。
     将完整 transcript 粘贴到下方。

     以下不是真正的集成，提交这些的 PR 会被关闭：

     - 手动将 skill 文件复制到 harness
     - 使用 `npx skills` 或类似 runtime shim 包装
     - 任何要求用户在每个 session 手动选择启用 skills 的方案
     - 上述验收测试没有自动触发 brainstorming 的任何方案

     如果你不确定集成是否在 session 启动时加载 bootstrap，那么它就没有加载。
-->

<details>
<summary>“Let's make a react todo list”的干净 session transcript</summary>

```
在此粘贴完整 transcript
```

</details>

## Evaluation
- 你（或你的 human partner）用来启动导致此变更的 session 的初始 prompt 是什么？
- 在做出变更后，你运行了多少个 eval sessions？
- 与变更前相比，结果如何变化？

<!-- “它能工作”不是 evaluation。描述你在多个 sessions 中观察到的
     before/after 差异。 -->

## Rigor

- [ ] 如果这是 skills 变更：我使用了 `superpowers:writing-skills`，
      并完成了对抗性压力测试（在下方粘贴结果）
- [ ] 此变更经过了对抗性测试，而不仅是 happy path
- [ ] 我没有在缺乏充分 eval 证明改进的情况下，修改精心调优的内容
      （Red Flags 表、rationalizations、“human partner”措辞）

<!-- 如果你修改了塑造 agent 行为的 skill 措辞，请展示你的 eval
     方法和结果。这些不是散文——它们是代码。 -->

## Human review
- [ ] 在提交前，已有 human review 完整的拟议 diff

<!--
停止。如果上方复选框未勾选，不要提交此 PR。

以下 PR 会在未经 review 的情况下关闭：
- 没有 human 参与证据
- 包含多个无关变更
- 推广或集成第三方服务或工具
- 将项目特定或个人配置作为 core 变更提交
- 必填 section 留空或使用占位文本
- 修改行为塑造内容但没有 eval 证据
-->
