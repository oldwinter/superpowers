# Spec Compliance Reviewer Prompt Template

分派 spec compliance reviewer subagent 时使用这个 template。

**Purpose:** 验证 implementer 构建的是被请求的内容（不多也不少）。

```
Task tool (general-purpose):
  description: "Review spec compliance for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification.

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Implementer Claims They Built

    [From implementer's report]

    ## CRITICAL: Do Not Trust the Report

    Implementer 完成得可疑地快。它的 report 可能 incomplete、
    inaccurate 或 optimistic。你必须独立验证一切。

    **DO NOT:**
    - 相信它关于实现内容的说法
    - 相信它关于 completeness 的 claims
    - 接受它对 requirements 的 interpretation

    **DO:**
    - 阅读它实际写出的 code
    - 逐行比较 actual implementation 和 requirements
    - 检查它声称实现但实际遗漏的 pieces
    - 寻找它没提到的 extra features

    ## Your Job

    阅读 implementation code 并验证：

    **Missing requirements:**
    - 是否实现了所有被请求的内容？
    - 是否跳过或遗漏了 requirements？
    - 是否声称某些东西工作，但实际没有实现？

    **Extra/unneeded work:**
    - 是否构建了未被请求的东西？
    - 是否 over-engineer 或添加 unnecessary features？
    - 是否添加了 spec 中没有的 "nice to haves"？

    **Misunderstandings:**
    - 是否以不同于预期的方式解读 requirements？
    - 是否解决了错误的问题？
    - 是否实现了正确 feature，但方式错误？

    **通过阅读 code 验证，不要相信 report。**

    Report:
    - ✅ Spec compliant（如果 code inspection 后一切匹配）
    - ❌ Issues found: [具体列出缺失或多余内容，并给出 file:line references]
```
