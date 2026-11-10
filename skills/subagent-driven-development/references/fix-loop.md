# Fix Loop

属于 superpowers:subagent-driven-development。Task review 报告了 spec ❌、Critical 或 Important finding，或你确认某 ⚠️ 条目是真实缺口。

循环开始前，有两条路径会立即离开循环：

- 随进度把 Minor findings 记录到 progress ledger（`Task <N>: minor (deferred): <one-liner>`），并让最终整分支 review 查看该列表，以便判断哪些必须在 merge 前修复。没人阅读的汇总等于静默丢弃。Minor findings 永远不进入循环。
- 标记为 plan-mandated 的 finding——或任何与 plan 文本要求冲突的 finding——由你裁决：权衡 finding 与 plan 文本，以 spec 为约束性权威作出决定，并在行动前把 ruling 写入 ledger。不要因为 plan 要求就驳回 finding，也不要在没有记录 ruling 的情况下 dispatch 与 plan 冲突的修复。

其他所有内容进入循环。一个 fix round 是一次 fix dispatch 加一次 scoped re-review。每个 task 最多五轮：

**第 1-3 轮——恢复原 implementer。** 把未解决的 findings 逐字发给它。它的上下文仍然完整：它了解 task、代码和自己的选择。如果你的 harness 无法向活跃 subagent 再发消息，dispatch 一个全新 implementer，携带 brief 路径、report 文件路径和 findings——无论哪种方式，report 文件都是持久记忆。

**第 4-5 轮——用更强的 model dispatch 全新 implementer**（按 SKILL.md 的 Model Selection），携带 brief 路径、report 文件路径、未解决的 findings，以及这段说明：“之前的 implementer 已尝试此 task [N] 次；现在由你负责。阅读 report 文件了解尝试过什么。”一个在三次恢复后仍存活的循环，通常意味着 implementer 看不到自己的问题——换新眼睛并提升能力，一步完成。

**无论哪种方式，每一轮都要：** implementer 修复、重跑覆盖被修改代码的测试、把 fix report 追加到同一 report 文件，并返回简短契约。重新 dispatch reviewer 前，确认 fix report 包含覆盖测试、运行的命令和输出；三者齐全后只 dispatch 一次 re-review。在 fix 消息中点名覆盖测试文件——一行修复不需要整个 suite。

**Re-review 是 scoped 的。** 在你执行所在的 working tree 中，用绝对路径运行 `bash scripts/review-package PLAN_FILE FIX_BASE HEAD`（run it by its absolute path），其中 FIX_BASE 是上一次 review 看到的 head，并 dispatch [re-review-prompt.md](../re-review-prompt.md)，携带 findings 列表、brief、report 文件和打印出的 diff 路径。Re-reviewer 对每个 finding 给出 ADDRESSED 或 NOT ADDRESSED，并只标记 fix diff 中的新破坏。Fix diff 中新的 Critical/Important 破坏加入未解决 findings 列表。范围外观察作为 deferred minors 写入 ledger——它们绝不延长循环。

**每轮之后，** 向 ledger 追加：
`Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)`

绝不要在 controller session 中亲自修复 findings——你的上下文保持干净用于协调，而且 controller 的修复会跳过 review。

**Breaker。** 当第 5 轮的 re-review 仍有未解决 findings 时，停止 dispatch。自己裁决每个未解决 finding——你拥有 reviewer 所缺的 plan 和跨 task 上下文：

- **Reviewer 错了，或该点可争议：** 停放它——`Task <N>: parked — <finding> — Ruling: <why the code stands>`。最终 review 会看到双方。
- **真实，但没有下游依赖它：** 以同样方式停放，并在 ruling 中说明它真实但延后。
- **真实且 load-bearing**——后续 task 依赖它，或它揭示了 plan 缺陷：裁决能解除依赖工作的最小变更，记录为 `Task <N>: Ruling: <finding> — <what you decided and why>`，并带入下一个 task 的 dispatch。静默停放结构性失败，会让每个依赖 task 都建立在它之上。只有当缺陷使所有前进路径都只能猜测时才停止。

只在 cap 处裁决。提前裁决以结束循环，只是换了个名字的预判。每次裁决都是 ledger 条目——禁止静默丢弃。
