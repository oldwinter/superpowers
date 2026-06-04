# Document Review System Design

## Overview

向 superpowers workflow 添加两个新的 review stages：

1. **Spec Document Review**：brainstorming 之后、writing-plans 之前
2. **Plan Document Review**：writing-plans 之后、implementation 之前

二者都遵循 implementation reviews 使用的 iterative loop pattern。

## Spec Document Reviewer

**Purpose:** 验证 spec 完整、一致，并已准备好进入 implementation planning。

**Location:** `skills/brainstorming/spec-document-reviewer-prompt.md`

**What it checks for:**

| Category | What to Look For |
|----------|------------------|
| Completeness | TODOs、placeholders、"TBD"、incomplete sections |
| Coverage | Missing error handling、edge cases、integration points |
| Consistency | Internal contradictions、conflicting requirements |
| Clarity | Ambiguous requirements |
| YAGNI | Unrequested features、over-engineering |

**Output format:**
```
## Spec Review

**Status:** Approved | Issues Found

**Issues (if any):**
- [Section X]: [issue] - [why it matters]

**Recommendations (advisory):**
- [suggestions that don't block approval]
```

**Review loop:** Issues found -> brainstorming agent fixes -> re-review -> repeat until approved。

**Dispatch mechanism:** 使用 Task tool，并设置 `subagent_type: general-purpose`。reviewer prompt template 提供完整 prompt。brainstorming skill 的 controller dispatch reviewer。

## Plan Document Reviewer

**Purpose:** 验证 plan 完整、匹配 spec，并具备合适的 task decomposition。

**Location:** `skills/writing-plans/plan-document-reviewer-prompt.md`

**What it checks for:**

| Category | What to Look For |
|----------|------------------|
| Completeness | TODOs、placeholders、incomplete tasks |
| Spec Alignment | Plan covers spec requirements、no scope creep |
| Task Decomposition | Tasks atomic、clear boundaries |
| Task Syntax | Checkbox syntax on tasks and steps |
| Chunk Size | Each chunk under 1000 lines |

**Chunk definition:** chunk 是 plan document 中一组逻辑相关 tasks，由 `## Chunk N: <name>` headings 分隔。writing-plans skill 会基于 logical phases（例如 "Foundation"、"Core Features"、"Integration"）创建这些 boundaries。每个 chunk 都应足够 self-contained，便于独立 review。

**Spec alignment verification:** reviewer 会收到：
1. plan document（或 current chunk）
2. spec document path，作为 reference

reviewer 读取二者，并比较 requirements coverage。

**Output format:** 与 spec reviewer 相同，但 scope 限定在 current chunk。

**Review process (chunk-by-chunk):**
1. Writing-plans 创建 chunk N
2. Controller dispatch plan-document-reviewer，并传入 chunk N content 和 spec path
3. Reviewer 读取 chunk 和 spec，返回 verdict
4. 如果有 issues：writing-plans agent 修复 chunk N，回到 step 2
5. 如果 approved：继续 chunk N+1
6. 重复直到所有 chunks approved

**Dispatch mechanism:** 与 spec reviewer 相同：Task tool with `subagent_type: general-purpose`。

## Updated Workflow

```
brainstorming -> spec -> SPEC REVIEW LOOP -> writing-plans -> plan -> PLAN REVIEW LOOP -> implementation
```

**Spec Review Loop:**
1. Spec complete
2. Dispatch reviewer
3. If issues: fix -> goto 2
4. If approved: proceed

**Plan Review Loop:**
1. Chunk N complete
2. Dispatch reviewer for chunk N
3. If issues: fix -> goto 2
4. If approved: next chunk or implementation

## Markdown Task Syntax

Tasks 和 steps 使用 checkbox syntax：

```markdown
- [ ] ### Task 1: Name

- [ ] **Step 1:** Description
  - File: path
  - Command: cmd
```

## Error Handling

**Review loop termination:**
- 没有 hard iteration limit；loops 会持续到 reviewer approve。
- 如果 loop 超过 5 iterations，controller 应向 human 暴露此情况并请求 guidance。
- human 可以选择：continue iterating、approve with known issues 或 abort。

**Disagreement handling:**
- Reviewers 是 advisory：他们 flag issues，但不直接 block。
- 如果 agent 认为 reviewer feedback 不正确，应在 fix 中解释原因。
- 如果同一 issue 的 disagreement 持续 3 iterations，则 surface to human。

**Malformed reviewer output:**
- Controller 应验证 reviewer output 具有 required fields（Status，适用时还有 Issues）。
- 如果 malformed，re-dispatch reviewer，并说明 expected format。
- 2 次 malformed responses 后，surface to human。

## Files to Change

**New files:**
- `skills/brainstorming/spec-document-reviewer-prompt.md`
- `skills/writing-plans/plan-document-reviewer-prompt.md`

**Modified files:**
- `skills/brainstorming/SKILL.md`：在 spec written 后添加 review loop
- `skills/writing-plans/SKILL.md`：添加 chunk-by-chunk review loop，更新 task syntax examples
