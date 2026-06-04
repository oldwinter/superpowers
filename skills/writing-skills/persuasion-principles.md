# Persuasion Principles for Skill Design

## 概览

LLMs 会响应和 humans 相同的 persuasion principles。理解这种 psychology 有助于设计更有效的 skills：不是为了操纵，而是为了确保 critical practices 即使在压力下也会被遵循。

**Research foundation:** Meincke et al. (2025) 用 N=28,000 AI conversations 测试了 7 个 persuasion principles。Persuasion techniques 让 compliance rates 翻倍以上（33% → 72%，p < .001）。

## 七个原则

### 1. Authority
**What it is:** 对 expertise、credentials 或 official sources 的服从。

**How it works in skills:**
- Imperative language: "YOU MUST", "Never", "Always"
- Non-negotiable framing: "No exceptions"
- 消除 decision fatigue 和 rationalization

**When to use:**
- Discipline-enforcing skills（TDD、verification requirements）
- Safety-critical practices
- Established best practices

**Example:**
```markdown
✅ Write code before test? Delete it. Start over. No exceptions.
❌ Consider writing tests first when feasible.
```

### 2. Commitment
**What it is:** 与先前 actions、statements 或 public declarations 保持一致。

**How it works in skills:**
- 要求 announcements: "Announce skill usage"
- 强制 explicit choices: "Choose A, B, or C"
- 使用 tracking: TodoWrite for checklists

**When to use:**
- 确保 skills 被实际遵循
- Multi-step processes
- Accountability mechanisms

**Example:**
```markdown
✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
❌ Consider letting your partner know which skill you're using.
```

### 3. Scarcity
**What it is:** 来自 time limits 或 limited availability 的 urgency。

**How it works in skills:**
- Time-bound requirements: "Before proceeding"
- Sequential dependencies: "Immediately after X"
- 防止 procrastination

**When to use:**
- Immediate verification requirements
- Time-sensitive workflows
- 防止 "I'll do it later"

**Example:**
```markdown
✅ After completing a task, IMMEDIATELY request code review before proceeding.
❌ You can review code when convenient.
```

### 4. Social Proof
**What it is:** 顺从他人做法或被视为 normal 的行为。

**How it works in skills:**
- Universal patterns: "Every time", "Always"
- Failure modes: "X without Y = failure"
- 建立 norms

**When to use:**
- 记录 universal practices
- 警告 common failures
- Reinforcing standards

**Example:**
```markdown
✅ Checklists without TodoWrite tracking = steps get skipped. Every time.
❌ Some people find TodoWrite helpful for checklists.
```

### 5. Unity
**What it is:** Shared identity、"we-ness"、in-group belonging。

**How it works in skills:**
- Collaborative language: "our codebase", "we're colleagues"
- Shared goals: "we both want quality"

**When to use:**
- Collaborative workflows
- 建立 team culture
- Non-hierarchical practices

**Example:**
```markdown
✅ We're colleagues working together. I need your honest technical judgment.
❌ You should probably tell me if I'm wrong.
```

### 6. Reciprocity
**What it is:** 回报所获 benefits 的 obligation。

**How it works:**
- 谨慎使用，可能显得 manipulative
- Skills 中很少需要

**When to avoid:**
- 几乎总是避免（其他 principles 更有效）

### 7. Liking
**What it is:** 更愿意与喜欢的人合作。

**How it works:**
- **不要用于 compliance**
- 与 honest feedback culture 冲突
- 会制造 sycophancy

**When to avoid:**
- Discipline enforcement 中始终避免

## Principle Combinations by Skill Type

| Skill Type | Use | Avoid |
|------------|-----|-------|
| Discipline-enforcing | Authority + Commitment + Social Proof | Liking, Reciprocity |
| Guidance/technique | Moderate Authority + Unity | Heavy authority |
| Collaborative | Unity + Commitment | Authority, Liking |
| Reference | Clarity only | All persuasion |

## Why This Works: The Psychology

**Bright-line rules reduce rationalization:**
- "YOU MUST" 移除 decision fatigue
- Absolute language 消除 "is this an exception?" 问题
- Explicit anti-rationalization 封住具体 loopholes

**Implementation intentions create automatic behavior:**
- Clear triggers + required actions = automatic execution
- "When X, do Y" 比 "generally do Y" 更有效
- 降低 compliance 的 cognitive load

**LLMs are parahuman:**
- 训练自包含这些 patterns 的 human text
- Authority language 在 training data 中先于 compliance 出现
- Commitment sequences（statement → action）经常被建模
- Social proof patterns（everyone does X）建立 norms

## Ethical Use

**Legitimate:**
- 确保 critical practices 被遵循
- 创建有效 documentation
- 防止 predictable failures

**Illegitimate:**
- 为 personal gain 操纵
- 制造 false urgency
- Guilt-based compliance

**The test:** 如果用户完全理解这项 technique，它是否仍服务于用户的 genuine interests？

## Research Citations

**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).* Harper Business.
- Seven principles of persuasion
- Empirical foundation for influence research

**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., & Cialdini, R. (2025).** Call Me A Jerk: Persuading AI to Comply with Objectionable Requests. University of Pennsylvania.
- 用 N=28,000 LLM conversations 测试 7 个 principles
- Persuasion techniques 让 compliance 从 33% 提升到 72%
- Authority、commitment、scarcity 最有效
- 验证 LLM behavior 的 parahuman model

## Quick Reference

设计 skill 时，问：

1. **它是什么 type？**（Discipline vs. guidance vs. reference）
2. **我想改变什么 behavior？**
3. **哪些 principle(s) 适用？**（discipline 通常是 authority + commitment）
4. **我是不是组合太多？**（不要七个全用）
5. **这是否 ethical？**（服务用户 genuine interests 吗？）
