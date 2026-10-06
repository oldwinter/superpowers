# Claude Code Tool Notes

> 中文执行摘要：Claude Code 是 reference harness。只有在 human partner 明确要求降低 orchestration 成本，或说明 session model 不应承担协调时，才把整个 SDD plan 交给一个 mid-tier orchestrator subagent；不能只为单个 task 增加嵌套。Orchestrator 必须逐字返回 “Rulings I made”。以下英文保留为精确执行规范。

Claude Code is the reference harness: skills speak its vocabulary
(`Agent` for a subagent dispatch, todos, `Skill`). These notes cover the
one place Claude Code can run a plan cheaper than the skills' default
shape. It is opt-in by your human partner and changes nothing the skills
require.

## Cheaper orchestration for subagent-driven development

The controller session is the most expensive seat in a
superpowers:subagent-driven-development run: it reads every dispatch
result and every report, and it usually runs on the session's most
capable model. Claude Code supports nested subagents (three layers below
the main conversation by default; `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`
adjusts it), so the whole loop can run one layer down.

When your human partner asks for it — or has said the session model is
too expensive to spend on coordination — dispatch ONE orchestrator
subagent on a mid-tier model with the plan path and the instruction to
use superpowers:subagent-driven-development end to end. The orchestrator
dispatches its own implementers and reviewers per that skill's Model
Selection; the workspace and ledger live on disk, so nothing is lost to
the extra layer. Its final message must carry the "Rulings I made" list
verbatim — that list is how the decisions reach your human partner, and
you relay it, not summarize it.

Do this only for a whole plan. Nesting a single task's dispatch buys
nothing and adds a seat.
