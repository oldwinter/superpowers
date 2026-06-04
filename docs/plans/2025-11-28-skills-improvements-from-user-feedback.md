# Skills Improvements from User Feedback

**Date:** 2025-11-28
**Status:** Draft
**Source:** 两个在真实 development scenarios 中使用 superpowers 的 Claude instances

---

## Executive Summary

两个 Claude instances 从实际 development sessions 中提供了详细 feedback。它们的 feedback 揭示了当前 skills 中的 **systematic gaps**：即使遵循 skills，仍有可预防 bugs 被 ship。

**Critical insight:** 这些是 problem reports，不只是 solution proposals。问题是真实的；解决方案需要认真评估。

**Key themes:**
1. **Verification gaps**：我们验证 operations succeed，但不验证它们是否达成 intended outcomes
2. **Process hygiene**：Background processes 会累积，并在 subagents 之间相互干扰
3. **Context optimization**：Subagents 收到过多无关信息
4. **Self-reflection missing**：handoff 前没有 prompt 要求 critique own work
5. **Mock safety**：Mocks 可能在没有 detection 的情况下偏离 interfaces
6. **Skill activation**：Skills 存在，但没有被 read/use

---

## Problems Identified

### Problem 1: Configuration Change Verification Gap

**What happened:**
- Subagent 测试 “OpenAI integration”
- 设置 `OPENAI_API_KEY` env var
- 得到 status 200 responses
- 报告 “OpenAI integration working”
- **BUT** response 包含 `"model": "claude-sonnet-4-20250514"`，实际仍在使用 Anthropic

**Root cause:**
`verification-before-completion` 检查 operations succeed，但不检查 outcomes 是否反映 intended configuration changes。

**Impact:** High：integration tests 产生 false confidence，bugs ship to production

**Example failure pattern:**
- Switch LLM provider → verify status 200 but don't check model name
- Enable feature flag → verify no errors but don't check feature is active
- Change environment → verify deployment succeeds but don't check environment vars

---

### Problem 2: Background Process Accumulation

**What happened:**
- session 中 dispatch 多个 subagents
- 每个 subagent 都启动 background server processes
- Processes 累积（4+ servers running）
- Stale processes 仍绑定 ports
- 后续 E2E test 命中带错误 config 的 stale server
- test results confusing/incorrect

**Root cause:**
Subagents 是 stateless 的：不知道 previous subagents 启动过哪些 processes。没有 cleanup protocol。

**Impact:** Medium-High：Tests 命中 wrong server，出现 false passes/failures，debugging 混乱

---

### Problem 3: Context Bloat in Subagent Prompts

**What happened:**
- Standard approach：给 subagent 完整 plan file 读取
- Experiment：只给 task + pattern + file + verify command
- Result：更快、更聚焦，single-attempt completion 更常见

**Root cause:**
Subagents 在无关 plan sections 上浪费 tokens 和 attention。

**Impact:** Medium：执行更慢，失败 attempts 更多

**What worked:**
```
You are adding a single E2E test to packnplay's test suite.

**Your task:** Add `TestE2E_FeaturePrivilegedMode` to `pkg/runner/e2e_test.go`

**What to test:** A local devcontainer feature that requests `"privileged": true`
in its metadata should result in the container running with `--privileged` flag.

**Follow the exact pattern of TestE2E_FeatureOptionValidation** (at the end of the file)

**After writing, run:** `go test -v ./pkg/runner -run TestE2E_FeaturePrivilegedMode -timeout 5m`
```

---

### Problem 4: No Self-Reflection Before Handoff

**What happened:**
- 添加 self-reflection prompt："Look at your work with fresh eyes - what could be better?"
- Task 5 的 implementer 识别出 failing test 是 implementation bug，而不是 test bug
- 追踪到 line 99：`strings.Join(metadata.Entrypoint, " ")` 创建了 invalid Docker syntax
- 如果没有 self-reflection，只会报告 “test fails”，不会给出 root cause

**Root cause:**
Implementers 在报告 completion 前不会自然停下来 critique own work。

**Impact:** Medium：implementer 本可捕获的 bugs 被 hand off 给 reviewer

---

### Problem 5: Mock-Interface Drift

**What happened:**
```typescript
// Interface defines close()
interface PlatformAdapter {
  close(): Promise<void>;
}

// Code (BUGGY) calls cleanup()
await adapter.cleanup();

// Mock (MATCHES BUG) defines cleanup()
vi.mock('web-adapter', () => ({
  WebAdapter: vi.fn().mockImplementation(() => ({
    cleanup: vi.fn().mockResolvedValue(undefined),  // Wrong!
  })),
}));
```
- Tests passed
- Runtime crashed: "adapter.cleanup is not a function"

**Root cause:**
Mock 是根据 buggy code 调用的内容推导出来的，而不是根据 interface definition。TypeScript 无法捕获 inline mocks 中错误的 method names。

**Impact:** High：Tests 给出 false confidence，runtime crashes

**Why testing-anti-patterns didn't prevent this:**
该 skill 覆盖了 testing mock behavior 和 mocking without understanding，但未覆盖 “derive mock from interface, not implementation” 这个具体 pattern。

---

### Problem 6: Code Reviewer File Access

**What happened:**
- Code reviewer subagent 被 dispatch
- 找不到 test file："The file doesn't appear to exist in the repository"
- 文件实际存在
- Reviewer 不知道应先 explicit read 它

**Root cause:**
Reviewer prompts 不包含 explicit file reading instructions。

**Impact:** Low-Medium：Reviews fail 或 incomplete

---

### Problem 7: Fix Workflow Latency

**What happened:**
- Implementer 在 self-reflection 中识别 bug
- Implementer 知道 fix
- 当前 workflow：report → I dispatch fixer → fixer fixes → I verify
- 额外 round-trip 增加 latency，但没有增加 value

**Root cause:**
当 implementer 已经诊断问题时，implementer 和 fixer roles 仍被 rigid separation。

**Impact:** Low：latency 增加，但无 correctness issue

---

### Problem 8: Skills Not Being Read

**What happened:**
- `testing-anti-patterns` skill 存在
- human 和 subagents 在写 tests 前都没有 read 它
- 它本可以防止部分 issues（虽然不是全部，见 Problem 5）

**Root cause:**
没有 enforcement 要求 subagents read relevant skills。Prompt 中也没有包含 skill reading。

**Impact:** Medium：如果不用，skill investment 就浪费了

---

## Proposed Improvements

### 1. verification-before-completion: Add Configuration Change Verification

**Add new section:**

```markdown
## Verifying Configuration Changes

When testing changes to configuration, providers, feature flags, or environment:

**Don't just verify the operation succeeded. Verify the output reflects the intended change.**

### Common Failure Pattern

Operation succeeds because *some* valid config exists, but it's not the config you intended to test.

### Examples

| Change | Insufficient | Required |
|--------|-------------|----------|
| Switch LLM provider | Status 200 | Response contains expected model name |
| Enable feature flag | No errors | Feature behavior actually active |
| Change environment | Deploy succeeds | Logs/vars reference new environment |
| Set credentials | Auth succeeds | Authenticated user/context is correct |

### Gate Function

```
BEFORE claiming configuration change works:

1. IDENTIFY: What should be DIFFERENT after this change?
2. LOCATE: Where is that difference observable?
   - Response field (model name, user ID)
   - Log line (environment, provider)
   - Behavior (feature active/inactive)
3. RUN: Command that shows the observable difference
4. VERIFY: Output contains expected difference
5. ONLY THEN: Claim configuration change works

Red flags:
  - "Request succeeded" without checking content
  - Checking status code but not response body
  - Verifying no errors but not positive confirmation
```

**Why this works:**
强制验证 INTENT，而不只是 operation success。

---

### 2. subagent-driven-development: Add Process Hygiene for E2E Tests

**Add new section:**

```markdown
## Process Hygiene for E2E Tests

When dispatching subagents that start services (servers, databases, message queues):

### Problem

Subagents are stateless - they don't know about processes started by previous subagents. Background processes persist and can interfere with later tests.

### Solution

**Before dispatching E2E test subagent, include cleanup in prompt:**

```
BEFORE starting any services:
1. Kill existing processes: pkill -f "<service-pattern>" 2>/dev/null || true
2. Wait for cleanup: sleep 1
3. Verify port free: lsof -i :<port> && echo "ERROR: Port still in use" || echo "Port free"

AFTER tests complete:
1. Kill the process you started
2. Verify cleanup: pgrep -f "<service-pattern>" || echo "Cleanup successful"
```

### Example

```
Task: Run E2E test of API server

Prompt includes:
"Before starting the server:
- Kill any existing servers: pkill -f 'node.*server.js' 2>/dev/null || true
- Verify port 3001 is free: lsof -i :3001 && exit 1 || echo 'Port available'

After tests:
- Kill the server you started
- Verify: pgrep -f 'node.*server.js' || echo 'Cleanup verified'"
```

### Why This Matters

- Stale processes serve requests with wrong config
- Port conflicts cause silent failures
- Process accumulation slows system
- Confusing test results (hitting wrong server)
```

**Trade-off analysis:**
- 向 prompts 增加 boilerplate
- 但能防止非常 confusing 的 debugging
- 对 E2E test subagents 来说值得

---

### 3. subagent-driven-development: Add Lean Context Option

**Modify Step 2: Execute Task with Subagent**

**Before:**
```
Read that task carefully from [plan-file].
```

**After:**
```
## Context Approaches

**Full Plan (default):**
Use when tasks are complex or have dependencies:
```
Read Task N from [plan-file] carefully.
```

**Lean Context (for independent tasks):**
Use when task is standalone and pattern-based:
```
You are implementing: [1-2 sentence task description]

File to modify: [exact path]
Pattern to follow: [reference to existing function/test]
What to implement: [specific requirement]
Verification: [exact command to run]

[Do NOT include full plan file]
```

**Use lean context when:**
- Task follows existing pattern (add similar test, implement similar feature)
- Task is self-contained (doesn't need context from other tasks)
- Pattern reference is sufficient (e.g., "follow TestE2E_FeatureOptionValidation")

**Use full plan when:**
- Task has dependencies on other tasks
- Requires understanding of overall architecture
- Complex logic that needs context
```

**Example:**
```
Lean context prompt:

"You are adding a test for privileged mode in devcontainer features.

File: pkg/runner/e2e_test.go
Pattern: Follow TestE2E_FeatureOptionValidation (at end of file)
Test: Feature with `"privileged": true` in metadata results in `--privileged` flag
Verify: go test -v ./pkg/runner -run TestE2E_FeaturePrivilegedMode -timeout 5m

Report: Implementation, test results, any issues."
```

**Why this works:**
减少 token usage，提升 focus，并在合适场景下更快完成。

---

### 4. subagent-driven-development: Add Self-Reflection Step

**Modify Step 2: Execute Task with Subagent**

**Add to prompt template:**

```
When done, BEFORE reporting back:

Take a step back and review your work with fresh eyes.

Ask yourself:
- Does this actually solve the task as specified?
- Are there edge cases I didn't consider?
- Did I follow the pattern correctly?
- If tests are failing, what's the ROOT CAUSE (implementation bug vs test bug)?
- What could be better about this implementation?

If you identify issues during this reflection, fix them now.

Then report:
- What you implemented
- Self-reflection findings (if any)
- Test results
- Files changed
```

**Why this works:**
在 handoff 前捕获 implementer 自己能发现的 bugs。已有 documented case：通过 self-reflection 识别了 entrypoint bug。

**Trade-off:**
每个 task 增加约 30 秒，但能在 review 前捕获 issues。

---

### 5. requesting-code-review: Add Explicit File Reading

**Modify the code-reviewer template:**

**Add at the beginning:**

```markdown
## Files to Review

BEFORE analyzing, read these files:

1. [List specific files that changed in the diff]
2. [Files referenced by changes but not modified]

Use Read tool to load each file.

If you cannot find a file:
- Check exact path from diff
- Try alternate locations
- Report: "Cannot locate [path] - please verify file exists"

DO NOT proceed with review until you've read the actual code.
```

**Why this works:**
Explicit instruction 可防止 “file not found” issues。

---

### 6. testing-anti-patterns: Add Mock-Interface Drift Anti-Pattern

**Add new Anti-Pattern 6:**

```markdown
## Anti-Pattern 6: Mocks Derived from Implementation

**The violation:**
```typescript
// Code (BUGGY) calls cleanup()
await adapter.cleanup();

// Mock (MATCHES BUG) has cleanup()
const mock = {
  cleanup: vi.fn().mockResolvedValue(undefined)
};

// Interface (CORRECT) defines close()
interface PlatformAdapter {
  close(): Promise<void>;
}
```

**Why this is wrong:**
- Mock encodes the bug into the test
- TypeScript can't catch inline mocks with wrong method names
- Test passes because both code and mock are wrong
- Runtime crashes when real object is used

**The fix:**
```typescript
// ✅ GOOD: Derive mock from interface

// Step 1: Open interface definition (PlatformAdapter)
// Step 2: List methods defined there (close, initialize, etc.)
// Step 3: Mock EXACTLY those methods

const mock = {
  initialize: vi.fn().mockResolvedValue(undefined),
  close: vi.fn().mockResolvedValue(undefined),  // From interface!
};

// Now test FAILS because code calls cleanup() which doesn't exist
// That failure reveals the bug BEFORE runtime
```

### Gate Function

```
BEFORE writing any mock:

  1. STOP - Do NOT look at the code under test yet
  2. FIND: The interface/type definition for the dependency
  3. READ: The interface file
  4. LIST: Methods defined in the interface
  5. MOCK: ONLY those methods with EXACTLY those names
  6. DO NOT: Look at what your code calls

  IF your test fails because code calls something not in mock:
    ✅ GOOD - The test found a bug in your code
    Fix the code to call the correct interface method
    NOT the mock

  Red flags:
    - "I'll mock what the code calls"
    - Copying method names from implementation
    - Mock written without reading interface
    - "The test is failing so I'll add this method to the mock"
```

**Detection:**

When you see runtime error "X is not a function" and tests pass:
1. Check if X is mocked
2. Compare mock methods to interface methods
3. Look for method name mismatches
```

**Why this works:**
直接处理 feedback 中出现的 failure pattern。

---

### 7. subagent-driven-development: Require Skills Reading for Test Subagents

**Add to prompt template when task involves testing:**

```markdown
BEFORE writing any tests:

1. Read testing-anti-patterns skill:
   Use Skill tool: superpowers:testing-anti-patterns

2. Apply gate functions from that skill when:
   - Writing mocks
   - Adding methods to production classes
   - Mocking dependencies

This is NOT optional. Tests that violate anti-patterns will be rejected in review.
```

**Why this works:**
确保 skills 被实际使用，而不是只是存在。

**Trade-off:**
每个 task 增加时间，但能防止整类 bugs。

---

### 8. subagent-driven-development: Allow Implementer to Fix Self-Identified Issues

**Modify Step 2:**

**Current:**
```
Subagent reports back with summary of work.
```

**Proposed:**
```
Subagent performs self-reflection, then:

IF self-reflection identifies fixable issues:
  1. Fix the issues
  2. Re-run verification
  3. Report: "Initial implementation + self-reflection fix"

ELSE:
  Report: "Implementation complete"

Include in report:
- Self-reflection findings
- Whether fixes were applied
- Final verification results
```

**Why this works:**
当 implementer 已经知道 fix 时减少 latency。Documented case：entrypoint bug 本可节省一次 round-trip。

**Trade-off:**
Prompt 稍复杂，但 end-to-end 更快。

---

## Implementation Plan

### Phase 1: High-Impact, Low-Risk（Do First）

1. **verification-before-completion: Configuration change verification**
   - 清晰新增，不改变 existing content
   - 处理 high-impact problem（tests 中 false confidence）
   - File: `skills/verification-before-completion/SKILL.md`

2. **testing-anti-patterns: Mock-interface drift**
   - 新增 anti-pattern，不修改 existing
   - 处理 high-impact problem（runtime crashes）
   - File: `skills/testing-anti-patterns/SKILL.md`

3. **requesting-code-review: Explicit file reading**
   - 简单添加到 template
   - 修复具体问题（reviewers can't find files）
   - File: `skills/requesting-code-review/SKILL.md`

### Phase 2: Moderate Changes（Test Carefully）

4. **subagent-driven-development: Process hygiene**
   - 新增 section，不改变 workflow
   - 处理 medium-high impact（test reliability）
   - File: `skills/subagent-driven-development/SKILL.md`

5. **subagent-driven-development: Self-reflection**
   - 改变 prompt template（higher risk）
   - 但已有 documented bug capture
   - File: `skills/subagent-driven-development/SKILL.md`

6. **subagent-driven-development: Skills reading requirement**
   - 增加 prompt overhead
   - 但确保 skills 被实际使用
   - File: `skills/subagent-driven-development/SKILL.md`

### Phase 3: Optimization（Validate First）

7. **subagent-driven-development: Lean context option**
   - 增加 complexity（two approaches）
   - 需要验证不会造成 confusion
   - File: `skills/subagent-driven-development/SKILL.md`

8. **subagent-driven-development: Allow implementer to fix**
   - 改变 workflow（higher risk）
   - Optimization，不是 bug fix
   - File: `skills/subagent-driven-development/SKILL.md`

---

## Open Questions

1. **Lean context approach:**
   - 是否应让它成为 pattern-based tasks 的 default？
   - 如何决定使用哪种 approach？
   - 是否存在过于 lean 而漏掉 important context 的风险？

2. **Self-reflection:**
   - 这会不会显著拖慢 simple tasks？
   - 是否应只应用于 complex tasks？
   - 如何防止 “reflection fatigue”，让它变成机械流程？

3. **Process hygiene:**
   - 应放在 subagent-driven-development，还是单独 skill？
   - 是否适用于 E2E tests 之外的 workflows？
   - 如何处理 process SHOULD persist 的场景（dev servers）？

4. **Skills reading enforcement:**
   - 是否应要求 ALL subagents read relevant skills？
   - 如何避免 prompts 变得过长？
   - 是否有 over-documenting 并失去 focus 的风险？

---

## Success Metrics

如何知道这些 improvements 有效？

1. **Configuration verification:**
   - 不再出现 “test passed but wrong config was used”
   - Jesse 不再说 “that's not actually testing what you think”

2. **Process hygiene:**
   - 不再出现 “test hit wrong server”
   - E2E test runs 中没有 port conflict errors

3. **Mock-interface drift:**
   - 不再出现 “tests pass but runtime crashes on missing method”
   - Mocks 和 interfaces 之间没有 method name mismatches

4. **Self-reflection:**
   - Measurable：implementer reports 是否包含 self-reflection findings？
   - Qualitative：进入 code review 的 bugs 是否减少？

5. **Skills reading:**
   - Subagent reports 引用 skill gate functions
   - Code review 中 anti-pattern violations 减少

---

## Risks and Mitigations

### Risk: Prompt Bloat
**Problem:** 加入所有这些 requirements 会让 prompts 过载
**Mitigation:**
- 分阶段 implementation（不要一次全部加入）
- 让部分新增内容 conditional（E2E hygiene 只用于 E2E tests）
- 考虑为不同 task types 使用 templates

### Risk: Analysis Paralysis
**Problem:** 太多 reflection/verification 会拖慢 execution
**Mitigation:**
- 保持 gate functions 快速（seconds，而不是 minutes）
- 让 lean context 初期 opt-in
- 监控 task completion times

### Risk: False Sense of Security
**Problem:** 遵循 checklist 并不保证 correctness
**Mitigation:**
- 强调 gate functions 是 minimums，不是 maximums
- 在 skills 中保留 “use judgment” language
- 说明 skills 捕获 common failures，不捕获所有 failures

### Risk: Skill Divergence
**Problem:** 不同 skills 给出 conflicting advice
**Mitigation:**
- 跨所有 skills review changes，确保 consistency
- 记录 skills 如何 interaction（Integration sections）
- 部署前用真实 scenarios 测试

---

## Recommendation

**Proceed with Phase 1 immediately:**
- verification-before-completion: Configuration change verification
- testing-anti-patterns: Mock-interface drift
- requesting-code-review: Explicit file reading

**Test Phase 2 with Jesse before finalizing:**
- 获取 self-reflection impact feedback
- 验证 process hygiene approach
- 确认 skills reading requirement 值得其 overhead

**Hold Phase 3 pending validation:**
- Lean context 需要 real-world testing
- Implementer-fix workflow change 需要 careful evaluation

这些 changes 处理了 users 记录的真实问题，同时尽量降低让 skills 变差的风险。
