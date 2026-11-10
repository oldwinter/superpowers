---
name: Bug Report
about: 某些功能没有按预期工作
labels: bug
---

<!--
提交前：搜索 open 和 closed issues。仅 Windows SessionStart hook 就已被报告 29 次。
如果你的问题已存在，请在现有 issue 中添加评论或 reaction，而不是新建。
-->

- [ ] 我已搜索现有 issues，确认这不是重复问题

## 谁在提交此报告？（必填）
<!-- 你是谁？是否代表他人提交？如果 human partner 要求你做某件事，
     最终导致你提交此 issue，他们是谁，你的指令是什么？请尽量贴近他们的原话。 -->

## Human 撰写的摘要（必填，200 字以内）
<!-- 由 human 用自己的话撰写：出了什么问题，本应发生什么。
     如果由 agent 提交，这里的 human 指你的 human partner，而不是你。 -->

## 环境（必填）
<!-- 必填。我们假设这是 agent 提交的报告——请告诉我们是哪一个，
     以及它在哪里运行。我们会按产生 report 的来源衡量它。 -->

| 字段 | 值 |
|-------|-------|
| Superpowers 版本 | |
| Harness（Claude Code、Cursor 等） | |
| Harness 版本 | |
| 你的 model + 版本 | |
| 已安装的所有 plugins | |
| OS + shell | |

## 这是 Superpowers 问题还是 platform 问题？
<!-- Superpowers 是 plugin。一些被报告的“bug”实际上是底层 platform
     或 model 的问题。如果不确定，请尝试在未安装 Superpowers 的情况下复现。

     如果移除 Superpowers 后问题仍然存在，请向你的 platform 提交 issue。 -->

- [ ] 我已确认，未安装 Superpowers 时不会出现此问题

我如何验证未安装 Superpowers 时无法复现此问题：
<!-- 你在没有 Superpowers 时运行了什么，发生了什么。
     “未尝试”是诚实的回答；只勾选框而不填写这里则不是。 -->

## 发生了什么？
<!-- 请具体。“它不工作”不是 bug report。 -->

## 复现步骤
1.
2.
3.

## 预期行为
<!-- 本应发生什么？ -->

## 实际行为
<!-- 实际发生了什么？ -->

## Debug log 或对话 transcript
<!-- 能展示问题的 debug log 或对话 transcript 是最有帮助的材料。
     没有它，我们只能猜测。错误输出的截图也有帮助。 -->
