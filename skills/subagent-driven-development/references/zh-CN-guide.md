# Subagent-Driven Development 中文导读

`SKILL.md` 是唯一的精确控制流规范，本页只解释本版（上游 v7.0.2）的关键变化，便于中文读者快速进入状态。两者冲突时，以 `SKILL.md` 的英文原文为准。

## Workspace 与 ledger

- SDD workspace 限定到单个 plan：`<repo-root>/.superpowers/sdd/<plan-basename>/`，其中保存该 plan 的 ledger、briefs 和 review packages。绝不要读写其他 plan 的目录。
- 进度以 ledger 为准，而不是 session 记忆或 todos。compaction 后从 ledger 和 `git log` 恢复。
- `git clean -fdx` 会销毁 workspace（它是 git-ignored scratch）；若发生这种情况，从 `git log` 恢复。

## Review fix loop

- 每项任务先复用原 implementer 修复三轮；第 4-5 轮改派能力更强的新 implementer。
- 每轮只做 scoped re-review，所有进度写入该 plan 的 ledger。
- 第 5 轮后必须裁决，或因 load-bearing finding 停止，不能无限重试。
- 最终整分支 review 只做一次 fix wave；残留 findings 按 fix loop 的 breaker 裁决，不存在第二次 fix wave。

## Ruling 与停止条件

Controller 不亲自修复 findings；dispatch 时必须明确指定 model，按任务复杂度选择档位。小型同形工作按 `references/batching.md` 合并为一次 dispatch。

遇到冲突、歧义或 plan 缺陷时作出 ruling 并写入 ledger，格式为 `Ruling: <决定> — <原因> — <判断错误时的代价>`，然后继续。

只有四类情况停下询问：不可逆或破坏性操作；安全敏感操作；worktree 之外的副作用（例如 merge、push 到共享分支、发布）；plan 损坏到任何前进路径都只能猜测。
