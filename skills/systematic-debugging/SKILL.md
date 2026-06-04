---
name: systematic-debugging
description: 遇到任何 bug、test failure 或 unexpected behavior 时，在提出 fixes 前使用
---

# Systematic Debugging

## 概览

随机 fixes 浪费时间，还会制造新 bugs。快速 patches 会掩盖 underlying issues。

**核心原则：** ALWAYS find root cause before attempting fixes。Symptom fixes are failure。

**违反这个流程的字面要求，就是违反 debugging 的精神。**

## 铁律

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

如果你还没完成 Phase 1，就不能提出 fixes。

## 何时使用

用于任何 technical issue：
- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**尤其在这些情况下使用：**
- Under time pressure（emergencies 让猜测变得诱人）
- "Just one quick fix" 看起来很明显
- 你已经试过多个 fixes
- 前一个 fix 没有工作
- 你没有完全理解 issue

**不要因为这些理由跳过：**
- Issue 看起来简单（简单 bugs 也有 root causes）
- 你很赶（匆忙保证返工）
- Manager 要求 NOW 修好（systematic 比 thrashing 更快）

## 四个阶段

继续到下一阶段前，你必须完成每个阶段。

### Phase 1: Root Cause Investigation

**尝试任何 fix 之前：**

1. **仔细阅读 Error Messages**
   - 不要跳过 errors 或 warnings
   - 它们经常包含精确 solution
   - 完整阅读 stack traces
   - 记录 line numbers、file paths、error codes

2. **稳定 Reproduce**
   - 你能可靠触发它吗？
   - 精确 steps 是什么？
   - 每次都会发生吗？
   - 如果不可复现 → 收集更多 data，不要猜

3. **检查 Recent Changes**
   - 什么变化可能导致这个问题？
   - Git diff、recent commits
   - New dependencies、config changes
   - Environmental differences

4. **在 Multi-Component Systems 中收集 Evidence**

   **当 system 有多个 components（CI → build → signing、API → service → database）时：**

   **提出 fixes 前，添加 diagnostic instrumentation：**
   ```
   For EACH component boundary:
     - Log what data enters component
     - Log what data exits component
     - Verify environment/config propagation
     - Check state at each layer

   Run once to gather evidence showing WHERE it breaks
   THEN analyze evidence to identify failing component
   THEN investigate that specific component
   ```

   **Example (multi-layer system):**
   ```bash
   # Layer 1: Workflow
   echo "=== Secrets available in workflow: ==="
   echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"

   # Layer 2: Build script
   echo "=== Env vars in build script: ==="
   env | grep IDENTITY || echo "IDENTITY not in environment"

   # Layer 3: Signing script
   echo "=== Keychain state: ==="
   security list-keychains
   security find-identity -v

   # Layer 4: Actual signing
   codesign --sign "$IDENTITY" --verbose=4 "$APP"
   ```

   **This reveals:** 哪一层失败（secrets → workflow ✓，workflow → build ✗）

5. **Trace Data Flow**

   **当 error 位于 call stack 深处时：**

   完整 backward tracing technique 见同目录的 `root-cause-tracing.md`。

   **Quick version:**
   - Bad value 从哪里来？
   - 是谁用 bad value 调用了这里？
   - 持续向上追踪，直到找到 source
   - 在 source 修复，不要在 symptom 处修

### Phase 2: Pattern Analysis

**修复前先找到 pattern：**

1. **Find Working Examples**
   - 在同一 codebase 中定位类似的 working code
   - 有什么类似 broken 部分、但能工作的实现？

2. **Compare Against References**
   - 如果在实现某个 pattern，完整阅读 reference implementation
   - 不要 skim：读每一行
   - 完整理解 pattern 后再应用

3. **Identify Differences**
   - Working 和 broken 之间有什么不同？
   - 列出每个 difference，无论多小
   - 不要假设 "that can't matter"

4. **Understand Dependencies**
   - 它需要哪些其他 components？
   - 需要哪些 settings、config、environment？
   - 它做了哪些 assumptions？

### Phase 3: Hypothesis and Testing

**Scientific method：**

1. **Form Single Hypothesis**
   - 清楚陈述："I think X is the root cause because Y"
   - 写下来
   - 要具体，不要含糊

2. **Test Minimally**
   - 做能测试 hypothesis 的最小 change
   - 一次一个 variable
   - 不要一次修多个东西

3. **Verify Before Continuing**
   - 工作了吗？Yes → Phase 4
   - 没工作？形成 NEW hypothesis
   - 不要叠加更多 fixes

4. **When You Don't Know**
   - 说 "I don't understand X"
   - 不要假装知道
   - 求助
   - 继续 research

### Phase 4: Implementation

**修 root cause，不修 symptom：**

1. **Create Failing Test Case**
   - 最简单的 reproduction
   - 如果可能，写 automated test
   - 没有 framework 时写 one-off test script
   - 修复前必须有
   - 使用 `superpowers:test-driven-development` skill 写 proper failing tests

2. **Implement Single Fix**
   - 处理已识别 root cause
   - 一次一个 change
   - 不要 "while I'm here" improvements
   - 不要 bundled refactoring

3. **Verify Fix**
   - Test 现在 pass 吗？
   - 没有其他 tests broken 吗？
   - Issue 真的 resolved 吗？

4. **If Fix Doesn't Work**
   - STOP
   - 计数：你已经试过多少 fixes？
   - 如果 < 3：回到 Phase 1，带着新信息重新分析
   - **如果 ≥ 3：STOP 并质疑 architecture（见下面 step 5）**
   - 未讨论 architecture 前，不要尝试 Fix #4

5. **如果 3+ Fixes Failed：质疑 Architecture**

   **表示 architectural problem 的 pattern：**
   - 每个 fix 都在不同地方暴露新的 shared state/coupling/problem
   - Fixes 需要 "massive refactoring" 才能实现
   - 每个 fix 都在别处制造新 symptoms

   **STOP and question fundamentals:**
   - 这个 pattern 从根本上 sound 吗？
   - 我们是否 "sticking with it through sheer inertia"？
   - 应该 refactor architecture，还是继续修 symptoms？

   **尝试更多 fixes 前，先和你的 human partner 讨论**

   这不是 failed hypothesis，而是 wrong architecture。

## Red Flags - STOP and Follow Process

如果你发现自己在想：
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- 追踪 data flow 前就提出 solutions
- **"One more fix attempt"（已经试过 2+ 次时）**
- **每个 fix 都在不同地方暴露新问题**

**所有这些都意味着：STOP。回到 Phase 1。**

**如果 3+ fixes failed：** 质疑 architecture（见 Phase 4.5）

## your human partner's Signals You're Doing It Wrong

**注意这些 redirections：**
- "Is that not happening?" - 你在没有验证的情况下假设
- "Will it show us...?" - 你本该添加 evidence gathering
- "Stop guessing" - 你在不理解的情况下提出 fixes
- "Ultrathink this" - 质疑 fundamentals，而不只是 symptoms
- "We're stuck?"（frustrated）- 你的 approach 不工作

**看到这些时：** STOP。回到 Phase 1。

## 常见合理化借口

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too。Process 对简单 bugs 也很快。 |
| "Emergency, no time for process" | Systematic debugging 比 guess-and-check thrashing 更快。 |
| "Just try this first, then investigate" | 第一个 fix 会设定模式。从一开始就做对。 |
| "I'll write test after confirming fix works" | Untested fixes 不稳定。Test first 会证明它。 |
| "Multiple fixes at once saves time" | 无法隔离什么有效。还会制造新 bugs。 |
| "Reference too long, I'll adapt the pattern" | Partial understanding 保证 bugs。完整阅读。 |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause。 |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem。质疑 pattern，不要再修。 |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## 当流程揭示 "No Root Cause"

如果 systematic investigation 发现 issue 确实是 environmental、timing-dependent 或 external：

1. 你已经完成流程
2. 记录你调查了什么
3. 实现适当 handling（retry、timeout、error message）
4. 添加 monitoring/logging，供未来 investigation 使用

**但是：** 95% 的 "no root cause" cases 都是 incomplete investigation。

## Supporting Techniques

这些 techniques 是 systematic debugging 的一部分，位于本目录：

- **`root-cause-tracing.md`** - 沿 call stack 反向追踪 bugs，找到 original trigger
- **`defense-in-depth.md`** - 找到 root cause 后，在多层添加 validation
- **`condition-based-waiting.md`** - 用 condition polling 替代 arbitrary timeouts

**Related skills:**
- **superpowers:test-driven-development** - 用于创建 failing test case（Phase 4, Step 1）
- **superpowers:verification-before-completion** - 宣称成功前验证 fix worked

## Real-World Impact

来自 debugging sessions：
- Systematic approach: 15-30 分钟修复
- Random fixes approach: 2-3 小时 thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common
