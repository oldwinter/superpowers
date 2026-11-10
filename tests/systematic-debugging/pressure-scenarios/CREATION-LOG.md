# Creation Log: Systematic Debugging Skill

这是一个 reference example，展示如何提取、组织并 bulletproof 一个 critical skill。

## Source Material

从 `~/.claude/CLAUDE.md` 提取 debugging framework：
- 4-phase systematic process（Investigation → Pattern Analysis → Hypothesis → Implementation）
- Core mandate: ALWAYS find root cause, NEVER fix symptoms
- Rules designed to resist time pressure and rationalization

## Extraction Decisions

**What to include:**
- 完整 4-phase framework 和所有 rules
- Anti-shortcuts（"NEVER fix symptom", "STOP and re-analyze"）
- Pressure-resistant language（"even if faster", "even if I seem in a hurry"）
- 每个 phase 的 concrete steps

**What to leave out:**
- Project-specific context
- 同一 rule 的重复 variations
- Narrative explanations（压缩成 principles）

## Structure Following skill-creation/SKILL.md

1. **Rich when_to_use** - 包含 symptoms 和 anti-patterns
2. **Type: technique** - 带 steps 的 concrete process
3. **Keywords** - "root cause", "symptom", "workaround", "debugging", "investigation"
4. **Flowchart** - "fix failed" → re-analyze vs add more fixes 的 decision point
5. **Phase-by-phase breakdown** - Scannable checklist format
6. **Anti-patterns section** - What NOT to do（对这个 skill 很关键）

## Bulletproofing Elements

Framework 设计为能在压力下抵抗 rationalization：

### Language Choices
- "ALWAYS" / "NEVER"（不是 "should" / "try to"）
- "even if faster" / "even if I seem in a hurry"
- "STOP and re-analyze"（明确 pause）
- "Don't skip past"（捕获实际 behavior）

### Structural Defenses
- **Phase 1 required** - 不能跳到 implementation
- **Single hypothesis rule** - 强制思考，防止 shotgun fixes
- **Explicit failure mode** - "IF your first fix doesn't work" 搭配 mandatory action
- **Anti-patterns section** - 展示 shortcuts 具体长什么样

### Redundancy
- Root cause mandate 出现在 overview + when_to_use + Phase 1 + implementation rules
- "NEVER fix symptom" 在不同 contexts 中出现 4 次
- 每个 phase 都有 explicit "don't skip" guidance

## Testing Approach

按 skills/meta/testing-skills-with-subagents 创建 4 个 validation tests：

### Test 1: Academic Context (No Pressure)
- Simple bug，没有 time pressure
- **Result:** Perfect compliance，complete investigation

### Test 2: Time Pressure + Obvious Quick Fix
- User "in a hurry"，symptom fix 看起来简单
- **Result:** 抵抗 shortcut，遵循完整 process，找到 real root cause

### Test 3: Complex System + Uncertainty
- Multi-layer failure，不清楚是否能找到 root cause
- **Result:** Systematic investigation，追踪所有 layers，找到 source

### Test 4: Failed First Fix
- Hypothesis 不工作，有诱惑继续加 fixes
- **Result:** 停下、重新分析、形成 new hypothesis（no shotgun）

**All tests passed.** No rationalizations found.

## Iterations

### Initial Version
- 完整 4-phase framework
- Anti-patterns section
- "fix failed" decision 的 flowchart

### Enhancement 1: TDD Reference
- 添加 skills/testing/test-driven-development 链接
- 添加说明：TDD 的 "simplest code" ≠ debugging 的 "root cause"
- 防止 methodologies 混淆

## Final Outcome

Bulletproof skill：
- ✅ 明确要求 root cause investigation
- ✅ 抵抗 time pressure rationalization
- ✅ 为每个 phase 提供 concrete steps
- ✅ 明确展示 anti-patterns
- ✅ 在多个 pressure scenarios 下测试
- ✅ 澄清与 TDD 的关系
- ✅ Ready for use

## Key Insight

**最重要的 bulletproofing:** Anti-patterns section 展示当下感觉合理的具体 shortcuts。当 Claude 想 "I'll just add this one quick fix" 时，看到 exact pattern 被列为 wrong，会制造 cognitive friction。

## Usage Example

遇到 bug 时：
1. Load skill: skills/debugging/systematic-debugging
2. Read overview（10 sec）- reminded of mandate
3. Follow Phase 1 checklist - forced investigation
4. 如果想 skip - see anti-pattern, stop
5. Complete all phases - root cause found

**Time investment:** 5-10 minutes
**Time saved:** 数小时 symptom-whack-a-mole

---

*Created: 2025-10-03*
*Purpose: Reference example for skill extraction and bulletproofing*
