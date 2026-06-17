# Persuasion Principles for Skill Design

## Overview

法学硕士遵循与人类相同的说服原则。了解这种心理可以帮助您设计更有效的技能 - 不是操纵，而是确保即使在压力下也能遵循关键实践。

**研究基础：** Meincke et al. (2025) 用 N=28,000 人工智能对话测试了 7 条说服原则。说服技巧使遵守率提高了一倍以上 (33% → 72%, p < .001)。

## The Seven Principles

### 1. Authority
**它是什么：** 对专业知识、证书或官方来源的尊重。

**技能如何发挥作用：**
- 命令式语言："你必须"、"从不"、"总是"
- 不可协商的框架："没有例外"
- 消除决策疲劳和合理化

**何时使用：**
- 纪律执行技能（TDD、验证要求）
- Safety-critical practices
- Established best practices

**Example:**
```markdown
✅ Write code before test? Delete it. Start over. No exceptions.
❌ Consider writing tests first when feasible.
```

### 2. Commitment
**它是什么：** 与之前的行动、声明或公开声明保持一致。

**技能如何发挥作用：**
- 需要公告："公告技能使用情况"
- 强制明确的选择："选择 A、B 或 C"
- 使用跟踪：清单中的待办事项

**何时使用：**
- 确保技能得到实际遵循
- Multi-step processes
- Accountability mechanisms

**Example:**
```markdown
✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
❌ Consider letting your partner know which skill you're using.
```

### 3. Scarcity
**它是什么：** 由于时间限制或可用性有限而产生的紧迫性。

**它在 skills 中如何工作：**
- 有时间限制的要求："在继续之前"
- 顺序依赖："紧接在 X 之后"
- Prevents procrastination

**何时使用：**
- 立即验证要求
- Time-sensitive workflows
- 防止"我稍后再做"

**Example:**
```markdown
✅ After completing a task, IMMEDIATELY request code review before proceeding.
❌ You can review code when convenient.
```

### 4. Social Proof
**它是什么：** 遵循他人的行为或被认为是正常的行为。

**技能如何发挥作用：**
- 通用模式："每次"、"总是"
- 故障模式："X 没有 Y = 故障"
- Establishes norms

**何时使用：**
- 记录普遍做法
- 关于常见故障的警告
- Reinforcing standards

**Example:**
```markdown
✅ Checklists without todo tracking = steps get skipped. Every time.
❌ Some people find a todo list helpful for checklists.
```

### 5. Unity
**它是什么：** 共享身份、"我们"、群体归属感。

**技能如何发挥作用：**
- 协作语言："我们的代码库"、"我们是同事"
- 共同目标："我们都想要质量"

**何时使用：**
- Collaborative workflows
- 建立团队文化
- Non-hierarchical practices

**Example:**
```markdown
✅ We're colleagues working together. I need your honest technical judgment.
❌ You should probably tell me if I'm wrong.
```

### 6. Reciprocity
**它是什么：** 返还收到的福利的义务。

**它是如何工作的：**
- 谨慎使用 - 会感到被操纵
- 很少需要的技能

**何时避免：**
- 几乎总是（其他原则更有效）

### 7. Liking
**它是什么：** 偏好与我们喜欢的人合作。

**它是如何工作的：**
- **请勿用于合规性**
- 与诚实反馈文化的冲突
- Creates sycophancy

**何时避免：**
- 始终为执行纪律

## Principle Combinations by Skill Type

|技能类型|使用 |避免 |
|------------|-----|-------|
|纪律执行 |权威+承诺+社会证明|喜欢，互惠|
|指导/technique |适度权威+团结|重磅权威|
|协作|团结+承诺|权威、喜欢|
|参考|仅清晰度 |全部说服|

## Why This Works: The Psychology

**明确的规则减少了合理化：**
- "你必须"消除决策疲劳
- 绝对语言消除了"这是一个例外吗？"问题
- 明确的反合理化反制措施堵住了具体漏洞

**实施意图创造自动行为：**
- 明确的触发器+所需的操作=自动执行
- "当 X 时，做 Y"比"通常做 Y"更有效
- 减少合规认知负担

**法学硕士是超人类：**
- 对包含这些模式的人类文本进行训练
- 训练数据中的权威语言优先于合规性
- 经常建模的承诺序列（陈述→行动）
- 社会证明模式（每个人都做 X）建立规范

## Ethical Use

**Legitimate:**
- 确保遵循关键实践
- 创建有效的文档
- 防止可预测的故障

**Illegitimate:**
- 操纵谋取个人利益
- 制造虚假的紧迫感
- Guilt-based compliance

**测试：** 如果用户完全理解该技术，它是否能满足用户的真正兴趣？

## Research Citations

**Cialdini, R. B. (2021)。** *影响力：说服心理学（新的和扩展的）。* 哈珀商业杂志。
- 七大说服原则
- 影响力研究的实证基础

**Meincke, L.、Shapiro, D.、Duckworth, A. L.、Mollick, E.、Mollick, L. 和 Cialdini, R. (2025)。** 叫我混蛋：说服 AI 遵守令人反感的请求。宾夕法尼亚大学。
- 通过 N=28,000 LLM 对话测试了 7 个原则
- 通过说服技巧，服从性提高了 33% → 72%
- 权威、承诺、稀缺最有效
- 验证 LLM 行为的超人类模型

## Quick Reference

设计技能时，询问：

1. **它是什么类型？**（纪律、指导、参考）
2. **我想改变什么行为？**
3. **适用哪些原则？**（通常是权威+纪律承诺）
4. **我是否组合了太多？**（不要使用所有七个）
5. **这符合道德吗？**（服务于用户的真正利益？）
