---
name: writing-skills
description: 在创建新 skill、编辑现有 skill，或部署前验证 skill 是否工作时使用
---

# Writing Skills

## 概览

**编写 skill 就是应用于流程文档的测试驱动开发。**

**个人 skill 位于你的 runtime 的 skills 目录**（Claude Code 上是 `~/.claude/skills/`）——Codex、Copilot CLI 和 Gemini CLI 也都识别 `~/.agents/skills/` 作为跨 runtime 别名。其他 runtime 的路径见 [codex-tools.md](../using-superpowers/references/codex-tools.md) 或 [gemini-tools.md](../using-superpowers/references/gemini-tools.md)。

你编写测试用例（带 subagent 的压力场景），观察它们失败（基线行为），编写 skill（文档），观察测试通过（agent 遵守），然后重构（堵住漏洞）。

**核心原则：** 如果你没有观察过 agent 在没有 skill 时失败，你就不知道这个 skill 是否教了正确的东西。

**REQUIRED BACKGROUND:** 使用本 skill 前，你必须理解 superpowers:test-driven-development。该 skill 定义了基本的 RED-GREEN-REFACTOR 循环。本 skill 将 TDD 应用于文档。

**官方指导：** Anthropic 官方 skill 创作最佳实践见 references/anthropic-best-practices.md。本文档提供补充该 skill 中以 TDD 为中心的方法的额外模式和指南。

## 什么是 Skill？

**skill** 是经过验证的技术、模式或工具的参考指南。Skills 帮助未来的 agent 找到并应用有效方法。

**Skills 是：** 可复用的技术、模式、工具、参考指南

**Skills 不是：** 关于你曾经如何解决某个问题的叙事

## Skills 的 TDD 映射

| TDD 概念 | Skill 创建 |
|-------------|----------------|
| **测试用例** | 带 subagent 的压力场景 |
| **生产代码** | Skill 文档（SKILL.md） |
| **测试失败（RED）** | 没有 skill 时 agent 违反规则（基线） |
| **测试通过（GREEN）** | 有 skill 时 agent 遵守 |
| **重构** | 在保持遵守的同时堵住漏洞 |
| **先写测试** | 在编写 skill 之前运行基线场景 |
| **观察它失败** | 记录 agent 使用的精确合理化说辞 |
| **最小代码** | 编写针对这些具体违规的 skill |
| **观察它通过** | 验证 agent 现在遵守 |
| **重构循环** | 发现新的合理化 → 堵住 → 重新验证 |

整个 skill 创建过程遵循 RED-GREEN-REFACTOR。

## 何时创建 Skill

**创建时机：**
- 技术对你来说并不直观明显
- 你会在多个项目中再次参考
- 模式广泛适用（不是项目特定）
- 其他人会受益

**不要为以下情况创建：**
- 一次性解决方案
- 已在别处充分记录的标准实践
- 项目特定约定（放入你的 instructions 文件）
- 机械约束（如果可以用 regex/validation 强制执行，就自动化——把文档留给需要判断的情况）

## Skill 类型

### 技术
有可遵循步骤的具体方法（condition-based-waiting、root-cause-tracing）

### 模式
思考问题的方式（flatten-with-flags、test-invariants）

### 参考
API 文档、语法指南、工具文档（office docs）

## 目录结构

```
skills/
  skill-name/
    SKILL.md              # 主参考（必需）
    supporting-file.*     # 仅在需要时
```

**扁平命名空间** - 所有 skills 在一个可搜索的命名空间中

**单独文件用于：**
1. **重型参考**（100+ 行）- API 文档、完整语法
2. **可复用工具** - 脚本、实用工具、模板

**保持内联：**
- 原则和概念
- 代码模式（< 50 行）
- 其他所有内容

## 编写 SKILL.md

skill 的 `description` 只说明何时使用它：触发条件和症状，以“Use when...”开头。它绝不总结 skill 的工作流，因为读到工作流摘要的 agent 会照着摘要做，而不是阅读 skill。

当你编写或修改 skill 的 frontmatter、name 或 description，或需要缩减其大小时，阅读 [references/discovery.md](references/discovery.md)：SKILL.md 模板、description 和关键词指导、命名、token 预算，以及交叉引用其他 skills。

## 流程图

当你在 skill 中添加或修改流程图时，先阅读 [references/flowcharts.md](references/flowcharts.md)：流程图何时值得存在、graphviz 约定，以及如何渲染。

## 代码示例

**一个优秀示例胜过许多平庸示例**

选择最相关的语言：
- 测试技术 → TypeScript/JavaScript
- 系统调试 → Shell/Python
- 数据处理 → Python

**好示例：**
- 完整且可运行
- 注释良好，解释 WHY
- 来自真实场景
- 清晰展示模式
- 可直接改编（不是通用模板）

**不要：**
- 用 5+ 种语言实现
- 创建填空模板
- 编写生造示例

你擅长移植——一个优秀示例就够了。

## 文件组织

### 自包含 Skill
```
defense-in-depth/
  SKILL.md    # 所有内容内联
```
何时：所有内容都放得下，不需要重型参考

### 带可复用工具的 Skill
```
condition-based-waiting/
  SKILL.md    # 概览 + 模式
  example.ts  # 可改编的工作辅助代码
```
何时：工具是可复用代码，而不仅是叙述

### 带重型参考的 Skill
```
pptx/
  SKILL.md       # 概览 + 工作流
  pptxgenjs.md   # 600 行 API 参考
  ooxml.md       # 500 行 XML 结构
  scripts/       # 可执行工具
```
何时：参考材料太大，无法内联

在正文中通过解释器调用捆绑脚本（`bash scripts/tool.sh`、`node scripts/tool.js`），绝不要用裸路径：一些 harness 的 plugin 打包器会剥离可执行位，裸 `scripts/tool.sh` 在那里会因 `Permission denied` 失败。

## 铁律（与 TDD 相同）

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

这适用于新 skills 和对现有 skills 的编辑。

在测试前写 skill？删除它。重新开始。
编辑 skill 但不测试？同样的违规。

**没有例外：**
- 不因“简单添加”而例外
- 不因“只是加一个 section”而例外
- 不因“文档更新”而例外
- 不要把未测试的变更保留为“参考”
- 不要在运行测试时“改编”
- 删除就是删除

**REQUIRED BACKGROUND:** superpowers:test-driven-development skill 解释了为什么这很重要。同样的原则适用于文档。

## 测试所有 Skill 类型

不同 skill 类型需要不同的测试方法：

### 纪律执行型 Skills（规则/要求）

**示例：** TDD、verification-before-completion、designing-before-coding

**测试方式：**
- 学术问题：他们理解规则吗？
- 压力场景：他们在压力下遵守吗？
- 多种压力组合：时间 + 沉没成本 + 疲惫
- 识别合理化说辞并添加明确的反制

**成功标准：** Agent 在最大压力下遵守规则

### 技术型 Skills（操作指南）

**示例：** condition-based-waiting、root-cause-tracing、defensive-programming

**测试方式：**
- 应用场景：他们能正确应用技术吗？
- 变体场景：他们能处理边缘情况吗？
- 缺失信息测试：指令有空白吗？

**成功标准：** Agent 成功将技术应用于新场景

### 模式型 Skills（心智模型）

**示例：** reducing-complexity、information-hiding concepts

**测试方式：**
- 识别场景：他们能识别模式何时适用吗？
- 应用场景：他们能使用心智模型吗？
- 反例：他们知道何时不应应用吗？

**成功标准：** Agent 正确识别何时/如何应用模式

### 参考型 Skills（文档/API）

**示例：** API 文档、命令参考、库指南

**测试方式：**
- 检索场景：他们能找到正确信息吗？
- 应用场景：他们能正确使用找到的内容吗？
- 空白测试：常见用例覆盖了吗？

**成功标准：** Agent 找到并正确应用参考信息

## 跳过测试的常见合理化

| 借口 | 现实 |
|--------|---------|
| “Skill 显然很清楚” | 对你清楚 ≠ 对其他 agent 清楚。测试它。 |
| “这只是参考” | 参考可能有空白、不清楚的 section。测试检索。 |
| “测试是过度杀伤” | 未测试的 skills 一定有问题。总是如此。15 分钟测试节省数小时。 |
| “有问题再测试” | 有问题 = agent 无法使用 skill。部署前测试。 |
| “测试太繁琐” | 测试比在生产中调试坏 skill 更不繁琐。 |
| “我确信它很好” | 过度自信保证会有问题。仍然测试。 |
| “学术 review 就够了” | 阅读 ≠ 使用。测试应用场景。 |
| “没时间测试” | 部署未测试的 skill 会在以后浪费更多修复时间。 |

**所有这些都意味着：部署前测试。没有例外。**

## 让形式匹配失败

在编写指导之前，先分类基线失败。对一种失败类型有防弹效果的形式，对另一种类型会适得其反。

| 基线失败 | 正确形式 | 错误形式 |
|---|---|---|
| 在压力下跳过/违反规则（知道更好，仍然这样做） | 禁止 + 合理化表 + 红旗（见 references/bulletproofing.md） | 软指导（“更喜欢……”“考虑……”） |
| 遵守，但输出形状错误（臃肿的 prompt、埋没的结论、重述的 spec） | 正面配方或合同：按顺序说明输出是什么——它的各个部分 | 禁止清单（“不要重述”“绝不叙述”） |
| 从他们已经产出的东西中省略必需元素 | 结构性：他们填写的模板中的 REQUIRED 字段或槽位 | 模板附近的散文提醒 |
| 行为应取决于条件 | 以可观察谓词为条件的条件规则（“如果 brief 存在，就引用它”） | 无条件规则 + 豁免条款 |

**为什么禁止对塑造问题会适得其反：** 在竞争性激励下（“让 prompt 自包含”），agent 会与“不要 X”谈判。在针对 dispatch-prompt 指导的正面措辞测试中，禁止组产生的不想要内容明显多于配方组（分布完全分离），甚至比无指导对照组更差——请对自己的情况做微测试，而不是假设，但绝不要默认使用禁止。配方没有留下谈判空间：输出要么符合所述形状，要么不符合。

**无论选择哪种形式，规则如下：**
- **不要细微差别条款。** “除非重要，否则不要 X”会重新打开谈判——在同样的措辞测试中，给获胜配方追加一个细微差别条款，会把它从一致降为噪声。把真正的例外表达为以可观察谓词为条件的独立条件。
- **豁免条款不能限定范围。** “此限制不适用于代码块”仍然会压制代码块。如果输出的某部分必须豁免，请重构，使规则无法触及它。

## 防合理化

当基线失败是纪律失败时，在编写指导前阅读 [references/bulletproofing.md](references/bulletproofing.md)：堵住漏洞、精神与文字之辨、合理化表，以及红旗列表。

## Skills 的 RED-GREEN-REFACTOR

遵循 TDD 循环：

### RED：编写失败测试（基线）

在没有 skill 的情况下，用 subagent 运行压力场景。记录精确行为：
- 他们做了什么选择？
- 他们使用了什么合理化说辞（逐字）？
- 哪些压力触发了违规？

这就是“观察测试失败”——在编写 skill 之前，你必须看到 agent 自然会做什么。

### GREEN：编写最小 Skill

编写针对那些具体合理化说辞的 skill。不要为假设情况添加额外内容。

在有 skill 的情况下运行相同场景。Agent 现在应该遵守。

### REFACTOR：堵住漏洞

Agent 发现了新的合理化说辞？添加明确的反制。重新测试直到防弹。

### 在完整场景前微测试措辞

完整压力场景运行是最终门禁，但每次迭代都很慢且昂贵。先用微测试验证措辞本身：

1. **每次调用一个全新上下文样本**——原始 API 调用，或如果没有 API 访问权限，使用单次 subagent。System prompt = 指导将实际所处的真实上下文（完整 skill 或 prompt 模板，而不是孤立的指导）；user message = 一个会诱发失败的任务。
2. **始终包含无指导对照组。** 如果对照组没有表现出失败，就没有什么可修复的——停止，不要编写指导。
3. **每个变体 5+ 次重复。** 单次样本会说谎。
4. **手动阅读每个被标记的匹配项。** 如果愿意，可以程序化评分，但模板回显和引用的反例会伪装成命中；仅靠自动计数会同时高估失败和成功。
5. **方差是一个指标。** 当指导生效时，重复会收敛到相同形状。五次重复出现五种不同解释，意味着措辞没有约束力——先收紧形式，再增加文字。

微测试验证措辞；它们不能替代纪律型 skills 的压力场景。

**测试方法：** 完整测试方法见 [references/testing-skills-with-subagents.md](references/testing-skills-with-subagents.md)：
- 如何编写压力场景
- 压力类型（时间、沉没成本、权威、疲惫）
- 系统性地堵住漏洞
- 元测试技术

## 反模式

### ❌ 叙事示例
“在 2025-10-03 的 session 中，我们发现空 projectDir 导致……”
**为什么不好：** 太具体，不可复用

### ❌ 多语言稀释
example-js.js, example-py.py, example-go.go
**为什么不好：** 质量平庸，维护负担

### ❌ 流程图中的代码
```dot
step1 [label="import fs"];
step2 [label="read file"];
```
**为什么不好：** 无法复制粘贴，难以阅读

### ❌ 通用标签
helper1, helper2, step3, pattern4
**为什么不好：** 标签应有语义含义

## 停止：在进入下一个 Skill 之前

**编写任何 skill 后，你必须停止并完成部署流程。**

**不要：**
- 批量创建多个 skills 而不逐个测试
- 在当前 skill 验证前进入下一个
- 因为“批处理更高效”而跳过测试

**下面的部署清单对每个 skill 都是强制性的。**

部署未测试的 skills = 部署未测试的代码。这违反质量标准。

## Skill 创建清单（改编自 TDD）

**重要：为下面每个清单项创建一个 todo。**

**RED 阶段 - 编写失败测试：**
- [ ] 创建压力场景（纪律型 skills 使用 3+ 种组合压力）
- [ ] 在没有 skill 的情况下运行场景 - 逐字记录基线行为
- [ ] 识别合理化/失败的模式

**GREEN 阶段 - 编写最小 Skill：**
- [ ] Name 仅使用字母、数字、连字符（无括号/特殊字符）
- [ ] YAML frontmatter 包含必需的 `name` 和 `description` 字段（最多 1024 字符；见 [spec](https://agentskills.io/specification)）
- [ ] Description 以“Use when...”开头，并包含具体触发条件/症状
- [ ] Description 用第三人称书写
- [ ] 全文使用关键词以便搜索（错误、症状、工具）
- [ ] 清晰的概览和核心原则
- [ ] 针对 RED 中识别的具体基线失败
- [ ] 指导形式匹配失败类型（见“让形式匹配失败”）
- [ ] 对于行为塑造指导：措辞已针对无指导对照组进行微测试（5+ 次重复，每个被标记的匹配都手动阅读）——纯参考型 skills 不适用
- [ ] 代码内联或链接到单独文件
- [ ] 一个优秀示例（不是多语言）
- [ ] 在有 skill 的情况下运行场景 - 验证 agent 现在遵守

**REFACTOR 阶段 - 堵住漏洞：**
- [ ] 从测试中识别新的合理化说辞
- [ ] 添加明确的反制（如果是纪律型 skill）
- [ ] 从所有测试迭代中构建合理化表
- [ ] 创建红旗列表
- [ ] 重新测试直到防弹

**质量检查：**
- [ ] 仅在决策不明显时使用小型流程图
- [ ] 快速参考表
- [ ] 常见错误 section
- [ ] 没有叙事故事
- [ ] 支持文件仅用于工具或重型参考

**部署：**
- [ ] 将 skill 提交到 git 并推送到你的 fork（如果配置了）
- [ ] 考虑通过 PR 回馈（如果广泛有用）

## 发现工作流

未来的 agent 如何找到你的 skill：

1. **遇到问题**（“测试不稳定”）
2. **搜索 skills**（grep descriptions，浏览分类）
3. **找到 SKILL**（description 匹配）
4. **浏览概览**（这相关吗？）
5. **阅读模式**（快速参考表）
6. **加载示例**（仅在实现时）

**为此流程优化** - 把可搜索的词放在前面并反复出现。
