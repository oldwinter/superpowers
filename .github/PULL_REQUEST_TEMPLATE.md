<!--
SUBMIT 前：逐字阅读这个 template。PR 如果留空 sections、
包含多个无关 changes，或没有 human involvement 证据，会被关闭且不 review。
-->

> **这个 PR 必须 target `dev` branch，而不是 `main`。** `main` 是
> released branch；active work 会先进入 `dev`。指向 `main` 的 PR
> 会在 review 前被要求 retarget 到 `dev`。

## 谁在提交这个 PR？（required）
<!-- Required。遗漏此项的 PR 会被关闭。我们假设这是 agent 写的
     PR：请告诉我们是哪一个 agent，以及它在哪里运行。我们会按产生内容的来源
     衡量贡献：从文档推理出的 content 与真实 session 中形成的工作，
     标准不同。 -->

| Field | Value |
|-------|-------|
| Your model + version | |
| Harness + version | |
| All plugins installed | |
| Human partner who reviewed this diff | |

## 你想解决什么问题？
<!-- 描述你遇到的具体问题。如果这是 session
     issue，请包含：你在做什么、出了什么问题、model 的
     精确 failure mode，最好还有 transcript 或 session log。

     "Improving" 某个东西不是问题陈述。什么坏了？什么
     失败了？促成这个变更的 user experience 是什么？ -->

## 这个 PR 改了什么？
<!-- 1-3 句话。写 what，不写 why；why 放在上面。 -->

## 这个 change 适合 core library 吗？
<!-- Superpowers core 包含能让所有用户受益的 general-purpose skills 和 infrastructure。
     问问自己：

     - 这对正在做完全不同类型项目的人有用吗？
     - 这是 project-specific、team-specific 或 tool-specific 吗？
     - 这是否 integrate 或 promote third-party service？

     如果你的 change 是针对特定 domain、workflow tool 或 third-party integration
     的新 skill，它应该放进自己的 plugin，而不是这里。
     关于如何单独发布，见 plugin development docs。 -->

## 你考虑过哪些 alternatives？
<!-- 在选择这个 approach 前，你尝试或评估过哪些其他方案？
     它们为什么更差？如果没有考虑 alternatives，请直说，
     但要知道这是 red flag。 -->

## 这个 PR 是否包含多个无关 changes？
<!-- 如果是：停下。拆成单独 PRs。Bundled PRs 会被关闭。
     如果你认为这些 changes 相关，请解释 dependency。 -->

## Existing PRs
- [ ] 我已经 review 所有 open AND closed PRs，检查 duplicates 或 prior art
- Related PRs: <!-- #number, #number, or "none found" -->

<!-- 如果存在 related closed PR，请解释你的 approach 有什么不同，
     以及为什么它能成功而对方没有。 -->

## Environment tested

| Harness (e.g. Claude Code, Cursor) | Harness version | Model | Model version/ID |
|-------------------------------------|-----------------|-------|------------------|
|                                     |                 |       |                  |

## New harness support（如果这个 PR 添加新 harness，则 required）

<!-- 如果这个 PR 添加对新 harness（IDE、CLI tool、agent
     runner）的支持，你必须包含证明 integration 实际可用的
     session transcript。

     真正的 integration 会在 session start 加载 `using-superpowers` bootstrap。
     bootstrap 会让 skills auto-trigger。没有它，skills 就是 dead weight：
     存在于磁盘，但不会在正确时机被调用。

     ACCEPTANCE TEST：在新 harness 中打开 clean session，并发送
     完全相同的用户消息：

         Let's make a react todo list

     可工作的 integration 会在写任何 code 前 auto-trigger `brainstorming` skill。
     请在下面粘贴完整 transcript。

     这些不是真正的 integrations，包含它们的 PR 会被关闭：

     - 手动把 skill files 复制进 harness
     - 用 `npx skills` 或类似 at-runtime shims 包装
     - 任何要求用户每个 session 手动 opt in skills 的方案
     - 任何在上面的 test 中没有 auto-trigger brainstorming 的方案

     如果你不确定 integration 是否在 session start 加载 bootstrap，
     那它就没有。
-->

<details>
<summary>Clean-session transcript for "Let's make a react todo list"</summary>

```
paste the complete transcript here
```

</details>

## Evaluation
- 你（或你的 human partner）用来启动导致此 change 的 session 的 initial prompt 是什么？
- 完成 change 后，你运行了多少 eval sessions？
- 和 change 前相比，outcomes 有什么变化？

<!-- "It works" 不是 evaluation。描述你在多个 sessions 中观察到的 before/after difference。 -->

## Rigor

- [ ] 如果这是 skills change：我使用了 `superpowers:writing-skills` 并
      完成 adversarial pressure testing（把结果粘贴在下面）
- [ ] 这个 change 经过 adversarial testing，而不只是 happy path
- [ ] 我没有在缺少 extensive evals 表明 change 是 improvement 的情况下，
      修改 carefully-tuned content（Red Flags table、
      rationalizations、"human partner" language）

<!-- 如果你修改了塑造 agent 行为的 skills wording，请展示你的
     eval methodology 和 results。这些不是 prose，而是 code。 -->

## Human review
- [ ] Human 已在 submission 前 review 完整 proposed diff

<!--
STOP。如果上面的 checkbox 没有勾选，不要提交这个 PR。

PR 会在不 review 的情况下被关闭，如果它们：
- 没有 human involvement 证据
- 包含多个无关 changes
- Promote 或 integrate third-party services or tools
- 把 project-specific 或 personal configuration 作为 core changes 提交
- Required sections 留空或使用 placeholder text
- 修改 behavior-shaping content 却没有 eval evidence
-->
