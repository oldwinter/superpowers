# Document Review System Implementation Plan

> **For agentic workers:** REQUIRED: 使用 superpowers:subagent-driven-development（如果 subagents available）或 superpowers:executing-plans 逐步实现此 plan。

**Goal:** 向 brainstorming 和 writing-plans skills 添加 spec 与 plan document review loops。

**Architecture:** 在每个 skill directory 中创建 reviewer prompt templates。修改 skill files，在 document creation 后添加 review loops。使用 Task tool 和 general-purpose subagent dispatch reviewer。

**Tech Stack:** Markdown skill files、通过 Task tool 进行 subagent dispatch

**Spec:** docs/superpowers/specs/2026-01-22-document-review-system-design.md

---

## Chunk 1: Spec Document Reviewer

此 chunk 将 spec document reviewer 添加到 brainstorming skill。

### Task 1: Create Spec Document Reviewer Prompt Template

**Files:**
- Create: `skills/brainstorming/spec-document-reviewer-prompt.md`

- [ ] **Step 1:** 创建 reviewer prompt template file

```markdown
# Spec Document Reviewer Prompt Template

Use this template when dispatching a spec document reviewer subagent.

**Purpose:** Verify the spec is complete, consistent, and ready for implementation planning.

**Dispatch after:** Spec document is written to docs/superpowers/specs/

```
Task tool (general-purpose):
  description: "Review spec document"
  prompt: |
    You are a spec document reviewer. Verify this spec is complete and ready for planning.

    **Spec to review:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, "TBD", incomplete sections |
    | Coverage | Missing error handling, edge cases, integration points |
    | Consistency | Internal contradictions, conflicting requirements |
    | Clarity | Ambiguous requirements |
    | YAGNI | Unrequested features, over-engineering |

    ## CRITICAL

    Look especially hard for:
    - Any TODO markers or placeholder text
    - Sections saying "to be defined later" or "will spec when X is done"
    - Sections noticeably less detailed than others

    ## Output Format

    ## Spec Review

    **Status:** ✅ Approved | ❌ Issues Found

    **Issues (if any):**
    - [Section X]: [specific issue] - [why it matters]

    **Recommendations (advisory):**
    - [suggestions that don't block approval]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
```

- [ ] **Step 2:** 验证 file 已正确创建

Run: `cat skills/brainstorming/spec-document-reviewer-prompt.md | head -20`
Expected: 显示 header 和 purpose section

- [ ] **Step 3:** Commit

```bash
git add skills/brainstorming/spec-document-reviewer-prompt.md
git commit -m "feat: add spec document reviewer prompt template"
```

---

### Task 2: Add Review Loop to Brainstorming Skill

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

- [ ] **Step 1:** 读取当前 brainstorming skill

Run: `cat skills/brainstorming/SKILL.md`

- [ ] **Step 2:** 在 “After the Design” 后添加 review loop section

找到 “After the Design” section，并在 documentation 之后、implementation 之前添加新的 “Spec Review Loop” section：

```markdown
**Spec Review Loop:**
After writing the spec document:
1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
2. If ❌ Issues Found:
   - Fix the issues in the spec document
   - Re-dispatch reviewer
   - Repeat until ✅ Approved
3. If ✅ Approved: proceed to implementation setup

**Review loop guidance:**
- Same agent that wrote the spec fixes it (preserves context)
- If loop exceeds 5 iterations, surface to human for guidance
- Reviewers are advisory - explain disagreements if you believe feedback is incorrect
```

- [ ] **Step 3:** 验证 changes

Run: `grep -A 15 "Spec Review Loop" skills/brainstorming/SKILL.md`
Expected: 显示新的 review loop section

- [ ] **Step 4:** Commit

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat: add spec review loop to brainstorming skill"
```

---

## Chunk 2: Plan Document Reviewer

此 chunk 将 plan document reviewer 添加到 writing-plans skill。

### Task 3: Create Plan Document Reviewer Prompt Template

**Files:**
- Create: `skills/writing-plans/plan-document-reviewer-prompt.md`

- [ ] **Step 1:** 创建 reviewer prompt template file

```markdown
# Plan Document Reviewer Prompt Template

Use this template when dispatching a plan document reviewer subagent.

**Purpose:** Verify the plan chunk is complete, matches the spec, and has proper task decomposition.

**Dispatch after:** Each plan chunk is written

```
Task tool (general-purpose):
  description: "Review plan chunk N"
  prompt: |
    You are a plan document reviewer. Verify this plan chunk is complete and ready for implementation.

    **Plan chunk to review:** [PLAN_FILE_PATH] - Chunk N only
    **Spec for reference:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, incomplete tasks, missing steps |
    | Spec Alignment | Chunk covers relevant spec requirements, no scope creep |
    | Task Decomposition | Tasks atomic, clear boundaries, steps actionable |
    | Task Syntax | Checkbox syntax (`- [ ]`) on tasks and steps |
    | Chunk Size | Each chunk under 1000 lines |

    ## CRITICAL

    Look especially hard for:
    - Any TODO markers or placeholder text
    - Steps that say "similar to X" without actual content
    - Incomplete task definitions
    - Missing verification steps or expected outputs

    ## Output Format

    ## Plan Review - Chunk N

    **Status:** ✅ Approved | ❌ Issues Found

    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] - [why it matters]

    **Recommendations (advisory):**
    - [suggestions that don't block approval]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
```

- [ ] **Step 2:** 验证 file 已创建

Run: `cat skills/writing-plans/plan-document-reviewer-prompt.md | head -20`
Expected: 显示 header 和 purpose section

- [ ] **Step 3:** Commit

```bash
git add skills/writing-plans/plan-document-reviewer-prompt.md
git commit -m "feat: add plan document reviewer prompt template"
```

---

### Task 4: Add Review Loop to Writing-Plans Skill

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1:** 读取当前 skill file

Run: `cat skills/writing-plans/SKILL.md`

- [ ] **Step 2:** 添加 chunk-by-chunk review section

在 “Execution Handoff” section 前添加：

```markdown
## Plan Review Loop

After completing each chunk of the plan:

1. Dispatch plan-document-reviewer subagent for the current chunk
   - Provide: chunk content, path to spec document
2. If ❌ Issues Found:
   - Fix the issues in the chunk
   - Re-dispatch reviewer for that chunk
   - Repeat until ✅ Approved
3. If ✅ Approved: proceed to next chunk (or execution handoff if last chunk)

**Chunk boundaries:** Use `## Chunk N: <name>` headings to delimit chunks. Each chunk should be ≤1000 lines and logically self-contained.
```

- [ ] **Step 3:** 更新 task syntax examples，使用 checkboxes

将 Task Structure section 改为显示 checkbox syntax：

```markdown
### Task N: [Component Name]

- [ ] **Step 1:** Write the failing test
  - File: `tests/path/test.py`
  ...
```

- [ ] **Step 4:** 验证 review loop section 已添加

Run: `grep -A 15 "Plan Review Loop" skills/writing-plans/SKILL.md`
Expected: 显示新的 review loop section

- [ ] **Step 5:** 验证 task syntax examples 已更新

Run: `grep -A 5 "Task N:" skills/writing-plans/SKILL.md`
Expected: 显示 checkbox syntax `### Task N:`

- [ ] **Step 6:** Commit

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: add plan review loop and checkbox syntax to writing-plans skill"
```

---

## Chunk 3: Update Plan Document Header

此 chunk 更新 plan document header template，以引用新的 checkbox syntax requirements。

### Task 5: Update Plan Header Template in Writing-Plans Skill

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1:** 读取当前 plan header template

Run: `grep -A 20 "Plan Document Header" skills/writing-plans/SKILL.md`

- [ ] **Step 2:** 更新 header template，引用 checkbox syntax

plan header 应说明 tasks 和 steps 使用 checkbox syntax。更新 header comment：

```markdown
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Tasks and steps use checkbox (`- [ ]`) syntax for tracking.
```

- [ ] **Step 3:** 验证 change

Run: `grep -A 5 "For agentic workers:" skills/writing-plans/SKILL.md`
Expected: 显示更新后的 header，并提到 checkbox syntax

- [ ] **Step 4:** Commit

```bash
git add skills/writing-plans/SKILL.md
git commit -m "docs: update plan header to reference checkbox syntax"
```
