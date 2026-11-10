# 让 Skills 对合理化免疫

属于 superpowers:writing-skills。当基线失败是纪律失败时使用：agent 知道规则，却在压力下跳过它。

## 让 Skills 对合理化免疫

执行纪律的 skills（如 TDD）需要抵抗合理化。Agent 很聪明，在压力下会找到漏洞。

**范围：** 这套工具用于纪律失败——agent 知道规则，却在压力下跳过它。对于输出形状错误或遗漏元素，基于禁止的防弹措施会适得其反；请改用“让形式匹配失败”中的形式。

**心理学说明：** 理解说服技巧为什么有效，有助于系统地应用它们。关于权威、承诺、稀缺、社会认同和统一原则的研究基础（Cialdini, 2021；Meincke et al., 2025），见本目录中的 persuasion-principles.md。

### 明确堵住每个漏洞

不要只陈述规则——禁止具体的绕过方式：

<Bad>
```markdown
Write code before test? Delete it.
```
</Bad>

<Good>
```markdown
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```
</Good>

### 处理“精神与文字”的争论

尽早加入基础原则：

```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

这会切断整类“我在遵循精神”的合理化说辞。

### 构建合理化表

从基线测试中捕获合理化说辞（见下文测试 section）。Agent 提出的每个借口都放入表中：

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
```

### 创建红旗列表

让 agent 在合理化时容易自检：

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**
```

### 为违规症状更新 SDO

在 description 中加入：你即将违反规则时的症状：

```yaml
description: use when implementing any feature or bugfix, before writing implementation code
```
