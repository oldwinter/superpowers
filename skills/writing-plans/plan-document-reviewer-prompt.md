# Plan Document Reviewer Prompt Template

分派 plan document reviewer subagent 时使用这个 template。

**Purpose:** 验证 plan 是否 complete、matches the spec，并具备 proper task decomposition。

**Dispatch after:** 完整 plan 已写完。

```
Task tool (general-purpose):
  description: "Review plan document"
  prompt: |
    You are a plan document reviewer. Verify this plan is complete and ready for implementation.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs、placeholders、incomplete tasks、missing steps |
    | Spec Alignment | Plan covers spec requirements，没有 major scope creep |
    | Task Decomposition | Tasks 有 clear boundaries，steps actionable |
    | Buildability | Engineer 能否按此 plan 执行而不卡住？ |

    ## Calibration

    **只 flag 会在 implementation 中造成真实问题的 issues。**
    Implementer 构建错误内容或卡住才是 issue。
    Minor wording、stylistic preferences 和 "nice to have" suggestions 不是。

    除非存在 serious gaps，否则 approve：例如缺失 spec requirements、
    contradictory steps、placeholder content，或 tasks 含糊到无法执行。

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] - [why it matters for implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
