---
name: diagnosing-superpowers
description: Use when a Superpowers session went wrong and your human partner wants to know why — repeated work, ignored plans, stumbles, poor results, a skill that didn't fire, “耗时太长”, “为什么这么贵”, “它在做什么” — or wants to build a bug report for the Superpowers maintainers, for the current session or a past one identified by id or path, on any harness
---

# Diagnosing Superpowers

## 概览

与 human partner 明确 session 中出了什么问题，读取磁盘上的 transcripts，并用证据报告发生了什么。你只负责报告，不诊断 Superpowers。由 triage bundle 或 issue 的人员决定 Superpowers 是否需要变更。

**核心原则：** 每项 finding 都必须引用 `path:line`。没有引用，就没有 finding。每个数字必须来自 transcript 或你实际运行的命令，绝不能凭记忆。

## 工作流

为每个 step 创建 todo。Steps 5-7 只在各自条件成立时运行。

1. **问题受理。** 一次只问一个问题，直到你能写出 statement，明确 session、已知的 turn 范围、partner 的预期、实际发生的情况，以及他们关注的 observable（wall-clock、tokens、重复操作、某个具体操作）。“耗时太长”只是 complaint，不是 problem statement。记录目标是否为 Superpowers bug report。
2. **定位。** 使用 `references/session-discovery.md`，把每个 session 解析为经验证的绝对 filesystem path。引用第一条 prompt 和 timestamp 确认历史 session，并列出每个被排除的 candidate 及原因，若没有则写 “none”。枚举 subagent transcripts。创建 `~/.superpowers/diagnosing-superpowers/<session-id>/`，告诉 partner 该路径，并按 environment 和 skill observation 的 provenance 规则填写其中的 `templates/case.md`。
3. **Triage。** 亲自读取报告问题附近的区域。然后按 dimension 并行 dispatch analyst subagents，每个接收 case 文件路径、`prompts/analyst-common.md`，以及 `prompts/` 中一个 dimension 文件：`skill-timeline.md`、`plan-adherence.md`、`repeated-work.md`、`stumbles.md`、`quality-evidence.md`、`request-conflicts.md`、`cost-and-time.md`。Transcript 很长时按 turn range 拆分 dimension。丢弃任何没有 `path:line` 的返回 finding。
4. **报告。** 按顺序填写 `templates/report.md` 的每个 section，写入 workspace，展示内容并给出路径。检查引用内容实际证明了什么，并保留 supporting case；symlink alias 不是冗余副本。
5. **GitHub issues：** 当 report §7 判断为 possible/likely，或 partner 明确要求时执行。按 `references/github-issues.md` 搜索 open 和 closed issues 中的相关症状。展示匹配项，并建议把报告补充到最接近的 issue。若无匹配，填写 `templates/issue.md`，写入 workspace，展示精确文本，并且只有获得批准后才创建 issue。`gh` 无法附加文件；若存在 bundle，给出路径，让 partner 在浏览器中附加。
6. **导出：** 仅在 partner 要求 bundle 时执行，绝不主动构建。如果受理目标是 bug report，只说明一次可按需提供脱敏 bundle，然后等待。询问 redaction level，并说明各级内容：skeleton（无 tool-result body）、evidence（仅保留 cited events 的 body）、full。按 `templates/bundle-README.md` 构建 bundle，先 dispatch `prompts/scrub.md`，再 dispatch `prompts/scrub-audit.md`，重复两者直到 audit 返回 CLEAN。完成 bundle template 的 evidence check 和 reconciliation，之后才能展示最终 scrub log、文件列表、privacy 和 evidence 结果。只有批准后才 archive（`zip -r` 或 `tar -czf`）。给出 archive path 时，要说明内容、指出 scrub log 中的替换，并明确脱敏可能漏项，partner 必须在分享前 review 每个文件。
7. **相似 sessions：** 仅在被要求时执行。把已确认 findings 转换为 signature，按 mtime 和 size 列出 candidates，找到 marker line numbers，对每个 candidate 并行 dispatch `prompts/similar-session.md`，并追加 report §9。

## 快速参考

七个 analysts 始终全部运行。下表说明 step 3 中你应先亲自读取的区域，以及 verdict 中优先呈现的 findings。

| Complaint | 先读并优先呈现 |
|---|---|
| “耗时太长” | cost-and-time、stumbles |
| “为什么做这些额外工作？” | repeated-work、plan-adherence |
| “为什么这么贵？” | cost-and-time |
| “它到底在做什么？”（仍在运行） | skill-timeline；在 coverage 标注 in-progress |
| “它忽略了 plan” | plan-adherence，先看 compaction lines |
| “Skill X 从未触发” | skill-timeline |

## Hard rules

- **Context safety。** 一条 transcript line 可能达到一 megabyte。每次读取任何 session 文件都必须遵循 `references/context-safety.md`。
- **只读。** 绝不修改、移动或删除 session 文件。
- **向 subagents 传递精确路径。** Subagent 所谓的 “current session” 是它自己的 session。必须传递绝对路径和 ids。
- **仅 human prompts。** Hook output、system reminders 和 tool results 都不是 partner 的话。在 subagent transcript 中，“user” 是 parent agent。
- **不诊断 Superpowers。** Report §7 只说明 involvement，然后停止。绝不命名某个 skill defect，也不提出变更。即使 partner 要求修复也不能跳过这一限制；指向 issue step，并说明可按需提供 bundle。也不要向 partner 提供建议。
- **批准门禁。** Partner 看到 scrub log 和文件列表前，不得 archive。其批准精确文本前，不得创建 issue 或 comment。
- **先受理，再分析。** Partner 回答之前，steps 2-7 都不能开始。如果他们不在，写下问题并停止。你代为重建的 statement 不算回答。若请求已明确限定范围，例如一个具体事件、当前运行状态、或要执行的分析，那么请求本身就是 statement：先回答，再询问。覆盖整个 session 的 “why” 只是 complaint。

## Red Flags

| 想法 | 事实 |
|---------|---------|
| “问题很明显，跳过 intake” | Problem statement 决定全部范围。必须询问。 |
| “他们不在，我来重建 statement” | 你无法重建他们的预期。写下问题并停止。 |
| “先扫描全部内容，最后再问” | 无范围扫描会把预算花在错误问题上。先问。 |
| “他们要 bug report，所以现在就构建 bundle” | Bundle 是打包后的 session 数据。只有明确要求时才构建。 |
| “只是小范围定点修改，不必重构” | 无论多小都不由你决定。报告证据，由 triager 决定。 |
| “每 token 价格众所周知” | 未从 transcript 计算出的数字都是捏造。引用来源，否则删除。 |
