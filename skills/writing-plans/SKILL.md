---
name: writing-plans
description: 当你已经有 multi-step task 的 spec 或 requirements，并且尚未触碰代码时使用
---

# Writing Plans

## 概览

编写完整 implementation plans，假设执行工程师对我们的 codebase 零上下文，而且品味可疑。把他们需要知道的一切都写清楚：每个 task 要碰哪些文件、代码、测试、可能需要查看的 docs、如何测试。把完整计划拆成 bite-sized tasks。DRY。YAGNI。TDD。频繁 commits。

假设他们是熟练开发者，但几乎不了解我们的 toolset 或 problem domain。也假设他们不太懂好的 test design。

**开始时宣布：** "I'm using the writing-plans skill to create the implementation plan."

**Context:** 如果工作在 isolated worktree 中，它应该在执行阶段通过 `superpowers:using-git-worktrees` skill 创建。

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- （用户对 plan location 的偏好会覆盖这个默认值）

## Scope Check

如果 spec 覆盖多个独立 subsystems，它应该已经在 brainstorming 阶段拆成 sub-project specs。如果没有，建议把它拆成独立 plans，每个 subsystem 一份。每份 plan 都应该独立产出可工作、可测试的软件。

## 文件结构

定义 tasks 之前，先画清楚哪些文件会被创建或修改，以及每个文件负责什么。这一步会锁定 decomposition decisions。

- 设计边界清晰、接口明确的 units。每个文件都应该有一个清楚的责任。
- 你最擅长推理能一次装进 context 的代码；当文件聚焦时，你的 edits 更可靠。优先选择更小、更聚焦的文件，而不是什么都做的大文件。
- 会一起变化的文件应该放在一起。按责任拆分，不按 technical layer 拆分。
- 在 existing codebases 中，遵循既有 patterns。如果 codebase 使用大文件，不要单方面重构；但如果你正在修改的文件已经难以管理，把拆分纳入计划是合理的。

这个结构会指导 task decomposition。每个 task 都应该产出独立有意义的 self-contained changes。

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**每个 step 都是一个行动（2-5 分钟）：**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**每份 plan 都必须以这个 header 开头：**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## 不要占位符

每个 step 都必须包含工程师需要的实际内容。以下都是 **plan failures**，永远不要写：
- "TBD"、"TODO"、"implement later"、"fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above"（没有实际 test code）
- "Similar to Task N"（重复代码；工程师可能会乱序阅读 tasks）
- 只描述做什么却不展示怎么做的 steps（涉及代码的 steps 必须有 code blocks）
- 引用任何 task 中都没有定义的 types、functions 或 methods

## 记住
- 始终使用 exact file paths
- 每个 step 都给完整代码：如果 step 修改代码，就展示代码
- 精确 commands 和 expected output
- DRY、YAGNI、TDD、frequent commits

## Self-Review

写完整 plan 后，用 fresh eyes 看 spec，并对照检查 plan。这是你自己运行的 checklist，不是 subagent dispatch。

**1. Spec coverage:** 浏览 spec 的每个 section/requirement。你能指出哪个 task 实现它吗？列出任何 gaps。

**2. Placeholder scan:** 搜索 plan 中的 red flags，也就是上面 "No Placeholders" 部分的任何模式。修复它们。

**3. Type consistency:** 后续 tasks 中使用的 types、method signatures 和 property names，是否与前面 tasks 中定义的一致？Task 3 中叫 `clearLayers()`，Task 7 中却叫 `clearFullLayers()`，这就是 bug。

如果发现问题，直接 inline 修复。不需要重新 review，修完继续。如果发现某个 spec requirement 没有对应 task，就添加 task。

## Execution Handoff

保存 plan 后，提供执行选项：

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** 使用 superpowers:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** 使用 superpowers:executing-plans
- Batch execution with checkpoints for review
