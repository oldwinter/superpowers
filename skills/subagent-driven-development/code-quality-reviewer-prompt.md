# Code Quality Reviewer Prompt Template

分派 code quality reviewer subagent 时使用这个 template。

**Purpose:** 验证 implementation 是否 well-built（clean、tested、maintainable）。

**只有 spec compliance review 通过后才 dispatch。**

```
Task tool (general-purpose):
  Use template at requesting-code-review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**除了标准 code quality concerns，reviewer 还应该检查：**
- 每个 file 是否有一个清楚的责任和 well-defined interface？
- Units 是否被拆解到能独立理解和测试？
- Implementation 是否遵循 plan 中的 file structure？
- 这个 implementation 是否创建了已经很大的新 files，或显著增大 existing files？（不要标记 pre-existing file sizes，只关注这次 change 贡献了什么。）

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
