---
name: verification-before-completion
description: 即将宣称工作 complete、fixed 或 passing，或 commit/create PR 前使用 - 要求先运行 verification commands 并确认输出，再做任何成功声明；永远 evidence before assertions
---

# Verification Before Completion

## 概览

没有验证就宣称工作完成，是不诚实，不是高效。

**核心原则：** Evidence before claims，永远如此。

**违反这条规则的字面要求，就是违反这条规则的精神。**

## 铁律

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

如果你没有在本消息中运行 verification command，就不能宣称它通过。

## Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: 哪条 command 能证明这个 claim？
2. RUN: 执行完整 command（fresh, complete）
3. READ: 阅读完整输出，检查 exit code，统计 failures
4. VERIFY: 输出是否确认 claim？
   - If NO: 用 evidence 陈述实际状态
   - If YES: 带 evidence 陈述 claim
5. ONLY THEN: 做出 claim

Skip any step = lying, not verifying
```

## 常见失败

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | 之前的运行、"should pass" |
| Linter clean | Linter output: 0 errors | 部分检查、外推 |
| Build succeeds | Build command: exit 0 | Linter passing、logs look good |
| Bug fixed | 测试 original symptom: passes | 改了代码、假设已修复 |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- 使用 "should"、"probably"、"seems to"
- 验证前表达满意（"Great!"、"Perfect!"、"Done!" 等）
- 未验证就准备 commit/push/PR
- 相信 agent success reports
- 依赖 partial verification
- 想着 "just this once"
- 疲惫，想赶紧结束
- **任何暗示成功、但尚未运行 verification 的措辞**

## 防止合理化逃避

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | 独立验证 |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## 为什么这很重要

来自 24 条 failure memories：
- your human partner 说过 "I don't believe you" - trust broken
- Undefined functions shipped - 会 crash
- Missing requirements shipped - 功能不完整
- Time wasted on false completion → redirect → rework
- 违反："Honesty is a core value. If you lie, you'll be replaced."

## 何时应用

**ALWAYS before:**
- 任何 success/completion claims 的变体
- 任何满意表达
- 任何关于工作状态的正向陈述
- Committing、PR creation、task completion
- 移动到下一个 task
- Delegating to agents

**规则适用于：**
- 精确短语
- 改写和同义表达
- 成功的暗示
- 任何传达 completion/correctness 的 communication

## 底线

**验证没有捷径。**

运行命令。阅读输出。然后再 claim 结果。

这没有商量余地。
