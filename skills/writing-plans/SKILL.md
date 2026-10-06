---
name: writing-plans
description: 当你已经有 multi-step task 的 spec 或 requirements，并且尚未触碰代码时使用
---

# Writing Plans

## 概览

为从未见过该 codebase 或 spec 的工程师编写 implementation plan。假设他们一旦知道精确接口和测试，就能用项目语言写出符合惯例的代码，也能在 plan 留白处做出合理选择。他们无法知道的是你已经作出的决定：哪些文件、哪些名称和 signature、spec 中哪些值、哪些测试能证明每个 task。把这些记录下来，将完整 plan 拆成 bite-sized tasks。DRY。YAGNI。TDD。频繁 commits。

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

Task 是自带测试周期、值得经过 fresh reviewer 门禁的最小单元。划分 task 边界时：
把 setup、configuration、scaffolding 和 documentation 步骤并入需要它们的交付 task；
只有当 reviewer 能够合理地拒绝一个 task、同时批准相邻 task 时才拆分。每个 task
都以可独立测试的交付物结束。

## Step Granularity

**每个 step 都是一个具有可检查结果的行动：**
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

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

## Review Focus

[The five input classes or failure modes the spec implies but no task's
tests exercise that are most likely to bite a person using this software
— one line each, naming the input or condition and the behavior a
reasonable person would expect, most likely first. The spec is a vision
document: it says what the software must do, not everything it will
meet, and its silence on an input is not permission for that input to
break the program. Write the list here, once, with the spec in front of
you. Then, for each line, add the test that pins it to the task that
owns the code, in that task's own step style.]

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

- [ ] **Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach when the signature and the test leave a choice
(which library call, which data structure); a code block only for an
algorithm they do not determine.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Step 应包含什么

当 implementer 能根据一个 step 恰好写出一种合理实现时，该 step 才算完整。这就是全部要求：明确，但不包办。每类 step 只携带消除歧义所需的信息：

- **测试 step：** 用代码给出测试名称和 assertions，其中包含 spec 的精确值。
- **代码 step：** 给出精确 signature（名称、参数、返回类型）、所在文件，以及 spec 固定的具体值。函数体由 implementer 编写；只有 signature 和测试无法确定算法，或 spec 固定了精确文案时，才给出函数体。
- **验证 step：** 给出要运行的命令和代表通过的输出。
- **对另一 task 的引用：** 由该 task 的 Interfaces block 说明使用什么；plan 不重复该 task 的代码。

Plan 是 implementer 无法独立作出的决定集合。比它所描述的代码还长的 plan，实际上是在代写代码。毫无决定的信息（`TBD`、`handle edge cases`、`add appropriate validation`、`write tests for the above`，或任何 task 都未定义的 type/function）则是相反的失败；self-review 必须捕获这两类问题。

## Self-Review

写完整 plan 后，用 fresh eyes 看 spec，并对照检查 plan。这是你自己运行的 checklist，不是 subagent dispatch。

**1. Spec coverage:** 浏览 spec 的每个 section/requirement。你能指出哪个 task 实现它吗？列出任何 gaps。

**2. Step scan:** 每个 step 都必须让 implementer 恰好写出一种合理实现，而且不能携带更多内容：没有作出任何决定的一行是缺口，signature 和测试已能确定却仍给出函数体则是在逐字转录。两者都要修复。

**3. Type consistency:** 后续 tasks 中使用的 types、method signatures 和 property names，是否与前面 tasks 中定义的一致？Task 3 中叫 `clearLayers()`，Task 7 中却叫 `clearFullLayers()`，这就是 bug。

**4. Review Focus:** 对 spec 暗示的每类输入或 failure mode，是否都有 task 的测试覆盖？把最可能伤害用户、但尚未覆盖的五项放入 Review Focus，并把每项对应的测试添加到负责该代码的 task。空 section 表示你检查后确实没找到，而不是跳过检查。

**5. Proportion:** 比较 plan 与 spec 的长度。比所实现 spec 长数倍的 plan 是程序转录稿，而不是 plan。如果 code block 占据文档大部分，请用 signature、测试名和 assertions 替换函数体，并确认每个 step 仍然无歧义。

发现问题就在原处修复，无需重新 review。若某个 spec requirement 没有对应 task，就添加该 task。

## Execution Handoff

保存并 self-review plan 后，提供链接供 human partner 阅读。如果他们已经明确给出执行方式，请让他们 review plan 并确认它准确表达需求；等待 review 后再实现，并继续使用已指定的方式。否则，请他们 review plan，并在实现前选择执行方式。

**When no execution method has already been supplied:**

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Please review the plan. Which execution approach would you prefer?**

- **Subagent-driven** - A fresh subagent implements each task and a fresh reviewer checks it before the next one starts, then a whole-branch review at the end. Most thorough; costs a fresh context per task and per review.
- **Native** - I implement every task myself in this session, the way this harness runs work, then one fresh reviewer on the most capable model checks the whole branch. Cheapest and fastest; no independent review until the end. Runs well with a mid-tier session model, since the plan carries the design.

**For this plan I recommend <one of the two>, because <one sentence from the plan: how much the tasks depend on each other's interfaces, how many there are, what a shipped mistake would cost>. Does the plan capture what you want, and which approach should we use?"**

**When an execution method has already been supplied:**

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Please review the plan. Does it capture what you want?"**

**If Subagent-driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development

**If Native chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
