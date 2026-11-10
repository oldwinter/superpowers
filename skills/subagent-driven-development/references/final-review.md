# 最终 Review 与收尾

属于 superpowers:subagent-driven-development。plan 中的每个 task 都已完成。

最终整分支 review 也需要 package：在你执行所在的 working tree 中，用绝对路径运行 `bash scripts/review-package PLAN_FILE MERGE_BASE HEAD`（run it by its absolute path；MERGE_BASE 是分支开始时的 commit，例如 `git merge-base main HEAD`），并把打印出的路径放进最终 review dispatch，让最终 reviewer 读取一个文件，而不是用 git 命令重新推导分支 diff。用可用的最强 model dispatch（见 SKILL.md 的 Model Selection），使用 superpowers:requesting-code-review 的 [code-reviewer.md](../../requesting-code-review/code-reviewer.md)。让它查看 ledger 中 deferred-minor 和 parked 行，以便判断哪些必须在 merge 前修复。

如果最终整分支 review 返回 findings，dispatch 一个 fix subagent，携带完整 findings 列表——不要每个 finding 一个 fixer。逐 finding 的 fixer 会各自重建上下文并重跑 suite；真实 session 的最终 review fix wave 成本超过其所有 tasks 之和。然后对 fix wave 做且只做一次 scoped re-review（在你执行所在的 working tree 中，用绝对路径运行 `bash scripts/review-package PLAN_FILE FIX_BASE HEAD`（run it by its absolute path），范围是 fix range，模板为 [re-review-prompt.md](../re-review-prompt.md)）。按 fix loop 的 breaker 方式裁决任何残留 findings（references/fix-loop.md）：用 ruling 停放，或对 load-bearing 的 findings 作出裁决并记录你的决定。只有运行中 plan 的四个停止条件（SKILL.md 顶部）能让你在这里停下。不存在第二次 fix wave——残留的 load-bearing findings 会在 finishing-a-development-branch 展示选项时呈现给 human partner。

### 收尾

删除任何内容前，把 ledger 中每一条含 `Ruling:` 的行——preflight rulings、parked findings、breaker adjudications，全部——按作出顺序收集到最终消息的 “Rulings I made”，每条附上错误成本。列表必须完整：如果 ledger 中有 ruling，列表就必须有它。该列表是你代表 human partner 作出的决定到达他们的唯一渠道——他们阅读后可以重做你弄错的部分。随 workspace 一起消失的 ruling，就是秘密作出的决定。

当最终整分支 review 干净且其修复已 merge，删除该 plan 的 workspace（`rm -rf <workspace>`）——记录现在位于 git history。Sibling 目录属于其他 plans，不要触碰。

使用 superpowers:finishing-a-development-branch。
