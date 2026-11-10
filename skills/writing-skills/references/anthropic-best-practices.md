# Skill authoring best practices

> 了解如何编写客服人员可以成功发现和使用的有效技能。

好的技能是简洁的、结构良好的，并且经过实际使用的测试。本指南提供实用的创作决策，帮助您编写客服人员可以有效发现和使用的技能。

有关技能如何发挥作用的概念背景，请参阅[Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)。

## Core principles

### Concise is key

[context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) 是一项公共物品。您的技能与您的代理需要了解的其他所有内容共享上下文窗口，包括：

* 系统提示
* Conversation history
* 其他技能的元数据
* 您的实际要求

并非您技能中的每个标记都会立即产生费用。启动时，仅预加载所有技能的元数据（名称和描述）。代理仅在技能相关时才读取SKILL.md，并且仅在需要时读取其他文件。然而，SKILL.md 中的简洁性仍然很重要：一旦代理加载它，每个令牌都会与对话历史记录和其他上下文竞争。

**默认假设**：智能体已经非常聪明

仅添加尚未添加的上下文代理。挑战每一条信息：

* "特工真的需要这个解释吗？"
* "我可以假设特工知道这一点吗？"
* "这一段是否证明其代币成本合理？"

**好例子：简洁**（大约 50 个标记）：

````markdown  theme={null}
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber

使用 pdfplumber.open("file.pdf") 作为 pdf：
    文本 = pdf.pages[0].extract_text()
```
````

**不好的例子：太冗长**（大约 150 个标记）：

```markdown  theme={null}
## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available for PDF processing, but we
recommend pdfplumber because it's easy to use and handles most cases well.
First, you'll need to install it using pip. Then you can use the code below...
```

简洁版本假设代理知道 PDF 是什么以及图书馆如何工作。

### Set appropriate degrees of freedom

将具体程度与任务的脆弱性和可变性相匹配。

**高自由度**（基于文本的说明）：

Use when:

* 多种方法均有效
* 决定取决于具体情况
* 启发式指导方法

Example:

```markdown  theme={null}
## Code review process

1. Analyze the code structure and organization
2. Check for potential bugs or edge cases
3. Suggest improvements for readability and maintainability
4. Verify adherence to project conventions
```

**中等自由度**（带有参数的伪代码或脚本）：

Use when:

* 存在首选模式
* 一些变化是可以接受的
* 配置影响行为

Example:

````markdown  theme={null}
## Generate report

Use this template and customize as needed:

```python
defgenerate_report（数据，格式="markdown"，include_charts=True）：
    # Process data
    # Generate output in specified format
    # Optionally include visualizations
```
````

**低自由度**（特定脚本，很少或没有参数）：

Use when:

* 操作脆弱且容易出错
* 一致性至关重要
* 必须遵循特定的顺序

Example:

````markdown  theme={null}
## Database migration

Run exactly this script:

```bash
python scripts/migrate.py --verify --backup
```

Do not modify the command or add additional flags.
````

**类比**：将代理视为探索路径的机器人：

* **两边都是悬崖的窄桥**：只有一条安全的前进道路。提供具体的护栏和准确的指示（低自由度）。示例：必须按精确顺序运行的数据库迁移。
* **开阔的场地，没有危险**：许多道路通向成功。给出总体方向并信任代理找到最佳路线（高自由度）。示例：代码审查，其中上下文决定最佳方法。

### Test with all models you plan to use

技能充当模型的补充，因此有效性取决于底层模型。使用您计划使用的所有模型来测试您的技能。

**按模型测试注意事项**：

* **克劳德俳句**（快速、经济）：该技能是否提供了足够的指导？
* **Claude Sonnet**（平衡）：技能是否清晰且高效？
* **Claude Opus**（强力推理）：技能是否避免过度解释？

对于 Opus 来说完美的方法可能对于 Haiku 来说需要更多细节。如果您计划在多个模型中使用您的技能，请瞄准适用于所有模型的说明。

## Skill structure

<Note>
  **YAML Frontmatter**：SKILL.md frontmatter 需要两个字段：

  * `name` - 人类可读的技能名称（最多 64 个字符）
  * `description` - 一行描述技能的作用以及何时使用它（最多 1024 个字符）

  有关完整的技能结构详细信息，请参阅[Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure)。
</Note>

### Naming conventions

使用一致的命名模式使技能更易于参考和讨论。我们建议使用**动名词形式**（动词 + -ing）作为技能名称，因为这清楚地描述了技能提供的活动或功能。

**良好的命名示例（动名词形式）**：

* "处理 PDF"
* "分析电子表格"
* "管理数据库"
* "测试代码"
* "编写文档"

**Acceptable alternatives**:

* 名词短语："PDF 处理"、"电子表格分析"
* 以行动为导向："处理 PDF"、"分析电子表格"

**Avoid**:

* 模糊的名称："Helper"、"Utils"、"Tools"
* 过于笼统："文档"、"数据"、"文件"
* 您的技能集合中的模式不一致

一致的命名可以更轻松地：

* 文档和对话中的参考技巧
* 一目了然地了解技能的作用
* 整理和搜索多种技能
* 维护专业、有凝聚力的技能库

### Writing effective descriptions

`description` 字段支持技能发现，并且应包括技能的用途和使用时间。

<Warning>
  **始终以第三人称写作**。描述被注入到系统提示中，不一致的观点会导致发现问题。

  * **好：**"处理 Excel 文件并生成报告"
  * **避免：**"我可以帮你处理Excel文件"
  * **避免：**"您可以使用它来处理 Excel 文件"
</Warning>

**具体并包括关键术语**。包括该技能的作用以及何时使用该技能的特定触发器/contexts。

每项技能都有一个描述字段。描述对于技能选择至关重要：代理使用它从潜在的 100 多个可用技能中选择正确的技能。您的描述必须提供足够的详细信息，以便代理知道何时选择此技能，而 SKILL.md 的其余部分则提供实施细节。

Effective examples:

**PDF处理技巧：**

```yaml  theme={null}
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

**Excel分析技巧：**

```yaml  theme={null}
description: Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files.
```

**Git 提交助手技能：**

```yaml  theme={null}
description: Generate descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
```

避免诸如此类的模糊描述：

```yaml  theme={null}
description: Helps with documents
```

```yaml  theme={null}
description: Processes data
```

```yaml  theme={null}
description: Does stuff with files
```

### Progressive disclosure patterns

SKILL.md 充当概述，根据需要向客服人员提供详细材料，例如入职指南中的目录。有关渐进式披露如何工作的说明，请参阅概述中的 [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work)。

**Practical guidance:**

* 将 SKILL.md 主体控制在 500 行以下，以获得最佳性能
* 当接近此限制时，将内容拆分为单独的文件
* 使用以下模式有效地组织指令、代码和资源

#### Visual overview: From simple to complex

基本技能从包含元数据和指令的 SKILL.md 文件开始：

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=87782ff239b297d9a9e8e1b72ed72db9" alt="Simple SKILL.md file showing YAML frontmatter and markdown body" data-og-width="2048" width="2048" data-og-height="1153" height="1153" data-path="images/agent-skills-simple-file.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=c61cc33b6f5855809907f7fda94cd80e 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=90d2c0c1c76b36e8d485f49e0810dbfd 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=ad17d231ac7b0bea7e5b4d58fb4aeabb 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f5d0a7a3c668435bb0aee9a3a8f8c329 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0e927c1af9de5799cfe557d12249f6e6 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=46bbb1a51dd4c8202a470ac8c80a893d 2500w" />

随着您的技能增长，您可以捆绑代理仅在需要时加载的其他内容：

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=a5e0aa41e3d53985a7e3e43668a33ea3" alt="Bundling additional reference files like reference.md and forms.md." data-og-width="2048" width="2048" data-og-height="1327" height="1327" data-path="images/agent-skills-bundling-content.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f8a0e73783e99b4a643d79eac86b70a2 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=dc510a2a9d3f14359416b706f067904a 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=82cd6286c966303f7dd914c28170e385 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=56f3be36c77e4fe4b523df209a6824c6 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=d22b5161b2075656417d56f41a74f3dd 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=3dd4bdd6850ffcc96c6c45fcb0acd6eb 2500w" />

完整的 Skill 目录结构可能如下所示：

```
pdf/
├── SKILL.md              # Main instructions (loaded when triggered)
├── FORMS.md              # Form-filling guide (loaded as needed)
├── reference.md          # API reference (loaded as needed)
├── examples.md           # Usage examples (loaded as needed)
└── scripts/
    ├── analyze_form.py   # Utility script (executed, not loaded)
    ├── fill_form.py      # Form filling script
    └── validate.py       # Validation script
```

#### Pattern 1: High-level guide with references

````markdown  theme={null}
---
name: PDF Processing
description: Extracts text and tables from PDF files, fills forms, and merges documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
---

# PDF Processing

## Quick start

Extract text with pdfplumber:
```python
import pdfplumber
使用 pdfplumber.open("file.pdf") 作为 pdf：
    文本 = pdf.pages[0].extract_text()
```

## Advanced features

**Form filling**: See [FORMS.md](FORMS.md) for complete guide
**API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
**Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
````

代理仅在需要时加载 FORMS.md、REFERENCE.md 或 EXAMPLES.md。

#### Pattern 2: Domain-specific organization

对于具有多个领域的技能，请按领域组织内容，以避免加载不相关的上下文。当用户询问销售指标时，代理只需要读取与销售相关的模式，而不是财务或营销数据。这使得令牌使用量保持在较低水平并集中于上下文。

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

````markdown SKILL.md theme={null}
# BigQuery Data Analysis

## Available datasets

**Finance**: Revenue, ARR, billing → See [reference/finance.md](reference/finance.md)
**Sales**: Opportunities, pipeline, accounts → See [reference/sales.md](reference/sales.md)
**Product**: API usage, features, adoption → See [reference/product.md](reference/product.md)
**Marketing**: Campaigns, attribution, email → See [reference/marketing.md](reference/marketing.md)

## Quick search

Find specific metrics using grep:

```bash
grep -i "收入" reference/finance.md
grep -i"管道"reference/sales.md
grep -i "api 用法" reference/product.md
```
````

#### Pattern 3: Conditional details

显示基本内容，高级内容链接：

```markdown  theme={null}
# DOCX Processing

## Creating documents

Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents

For simple edits, modify the XML directly.

**For tracked changes**: See [REDLINING.md](REDLINING.md)
**For OOXML details**: See [OOXML.md](OOXML.md)
```

仅当用户需要这些功能时，代理才会读取REDLINING.md或OOXML.md。

### Avoid deeply nested references

当从其他引用的文件引用文件时，代理可能会部分读取文件。当遇到嵌套引用时，代理可能会使用诸如 `head -100` 之类的命令来预览内容而不是读取整个文件，从而导致信息不完整。

**Keep references one level deep from SKILL.md**.所有参考文件应直接从SKILL.md链接，以确保代理在需要时读取完整的文件。

**坏例子：太深了**：

```markdown  theme={null}
# SKILL.md
See [advanced.md](advanced.md)...

# advanced.md
See [details.md](details.md)...

# details.md
Here's the actual information...
```

**好例子：一层深**：

```markdown  theme={null}
# SKILL.md

**Basic usage**: [instructions in SKILL.md]
**Advanced features**: See [advanced.md](advanced.md)
**API reference**: See [reference.md](reference.md)
**Examples**: See [examples.md](examples.md)
```

### Structure longer reference files with table of contents

对于超过 100 行的参考文件，请在顶部包含目录。 This ensures agents can see the full scope of available information even when previewing with partial reads.

**Example**:

```markdown  theme={null}
# API Reference

## Contents
- Authentication and setup
- Core methods (create, read, update, delete)
- Advanced features (batch operations, webhooks)
- Error handling patterns
- Code examples

## Authentication and setup
...

## Core methods
...
```

然后，代理可以读取完整的文件或根据需要跳转到特定部分。

有关此基于文件系统的架构如何实现渐进式披露的详细信息，请参阅下面高级部分中的 [Runtime environment](#runtime-environment) 部分。

## Workflows and feedback loops

### Use workflows for complex tasks

将复杂的操作分解为清晰、连续的步骤。对于特别复杂的工作流程，请提供一个清单，代理可以将其复制到其响应中并在进展过程中进行核对。

**Example 1: Research synthesis workflow** (for Skills without code):

````markdown  theme={null}
## Research synthesis workflow

Copy this checklist and track your progress:

```
Research Progress:
- [ ] 步骤一：阅读所有源文档
- [ ] 第 2 步：确定关键主题
- [ ] 步骤 3：交叉引用权利要求
- [ ] 步骤 4：创建结构化摘要
- [ ] 步骤 5：验证引文
```

**Step 1: Read all source documents**

Review each document in the `sources/` directory. Note the main arguments and supporting evidence.

**Step 2: Identify key themes**

Look for patterns across sources. What themes appear repeatedly? Where do sources agree or disagree?

**Step 3: Cross-reference claims**

For each major claim, verify it appears in the source material. Note which source supports each point.

**Step 4: Create structured summary**

Organize findings by theme. Include:
- Main claim
- Supporting evidence from sources
- Conflicting viewpoints (if any)

**Step 5: Verify citations**

Check that every claim references the correct source document. If citations are incomplete, return to Step 3.
````

此示例展示了工作流如何应用于不需要代码的分析任务。检查表模式适用于任何复杂的多步骤流程。

**示例 2：PDF 表单填写工作流程**（针对代码技能）：

````markdown  theme={null}
## PDF form filling workflow

Copy this checklist and check off items as you complete them:

```
Task Progress:
- [ ] 第 1 步：分析表单（运行 analyze_form.py）
- [ ] 步骤 2：创建字段映射（编辑 fields.json）
- [ ] 步骤 3：验证映射（运行 validate_fields.py）
- [ ] 第 4 步：填写表格（运行 fill_form.py）
- [ ] 步骤 5：验证输出（运行 verify_output.py）
```

**Step 1: Analyze the form**

Run: `python scripts/analyze_form.py input.pdf`

This extracts form fields and their locations, saving to `fields.json`.

**Step 2: Create field mapping**

Edit `fields.json` to add values for each field.

**Step 3: Validate mapping**

Run: `python scripts/validate_fields.py fields.json`

Fix any validation errors before continuing.

**Step 4: Fill the form**

Run: `python scripts/fill_form.py input.pdf fields.json output.pdf`

**Step 5: Verify output**

Run: `python scripts/verify_output.py output.pdf`

If verification fails, return to Step 2.
````

清晰的步骤可防止代理跳过关键验证。该清单可帮助您和客服人员跟踪多步骤工作流程的进度。

### Implement feedback loops

**常见模式**：运行验证器→修复错误→重复

这种模式极大地提高了输出质量。

**Example 1: Style guide compliance** (for Skills without code):

```markdown  theme={null}
## Content review process

1. Draft your content following the guidelines in STYLE_GUIDE.md
2. Review against the checklist:
   - Check terminology consistency
   - Verify examples follow the standard format
   - Confirm all required sections are present
3. If issues found:
   - Note each issue with specific section reference
   - Revise the content
   - Review the checklist again
4. Only proceed when all requirements are met
5. Finalize and save the document
```

这显示了使用参考文档而不是脚本的验证循环模式。 The "validator" is STYLE\_GUIDE.md, and the agent performs the check by reading and comparing.

**Example 2: Document editing process** (for Skills with code):

```markdown  theme={null}
## Document editing process

1. Make your edits to `word/document.xml`
2. **Validate immediately**: `python ooxml/scripts/validate.py unpacked_dir/`
3. If validation fails:
   - Review the error message carefully
   - Fix the issues in the XML
   - Run validation again
4. **Only proceed when validation passes**
5. Rebuild: `python ooxml/scripts/pack.py unpacked_dir/ output.docx`
6. Test the output document
```

验证循环尽早发现错误。

## Content guidelines

### Avoid time-sensitive information

Don't include information that will become outdated:

**坏例子：时间敏感**（会出错）：

```markdown  theme={null}
If you're doing this before August 2025, use the old API.
After August 2025, use the new API.
```

**好例子**（使用"旧模式"部分）：

```markdown  theme={null}
## Current method

Use the v2 API endpoint: `api.example.com/v2/messages`

## Old patterns

<details>
<summary>Legacy v1 API (deprecated 2025-08)</summary>

The v1 API used: `api.example.com/v1/messages`

This endpoint is no longer supported.
</details>
```

The old patterns section provides historical context without cluttering the main content.

### Use consistent terminology

选择一个术语并在整个技能中使用它：

**好 - 一致**：

* 始终"API端点"
* 永远是"田野"
* 总是"提取"

**不好 - 不一致**：

* 混合"API端点"，"URL"，"API路由"，"路径"
* 混合"字段"、"框"、"元素"、"控件"
* 混合"提取"、"拉"、"获取"、"检索"

一致性有助于代理理解并遵循指示。

## Common patterns

### Template pattern

提供输出格式的模板。将严格程度与您的需求相匹配。

**对于严格要求**（例如 API 响应或数据格式）：

````markdown  theme={null}
## Report structure

ALWAYS use this exact template structure:

```markdown
# [Analysis Title]

## Executive summary
[主要发现的一段概述]

## Key findings
- 找到 1 并提供支持数据
- 发现 2 有支持数据
- 发现 3 并提供支持数据

## Recommendations
1. 具体可行的建议
2. 具体可行的建议
```
````

**为了灵活指导**（当适应有用时）：

````markdown  theme={null}
## Report structure

Here is a sensible default format, but use your best judgment based on the analysis:

```markdown
# [Analysis Title]

## Executive summary
[Overview]

## Key findings
[根据您的发现调整部分]

## Recommendations
【根据具体情况量身定制】
```

Adjust sections as needed for the specific analysis type.
````

### Examples pattern

For Skills where output quality depends on seeing examples, provide input/output pairs just like in regular prompting:

````markdown  theme={null}
## Commit message format

Generate commit messages following these examples:

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
```
feat(auth)：实现基于 JWT 的身份验证

Add login endpoint and token validation middleware
```

**Example 2:**
Input: Fixed bug where dates displayed incorrectly in reports
Output:
```
fix(reports): correct date formatting in timezone conversion

在报告生成过程中一致使用 UTC 时间戳
```

**Example 3:**
Input: Updated dependencies and refactored error handling
Output:
```
chore: update dependencies and refactor error handling

- 将lodash升级到4.17.21
- 跨端点标准化错误响应格式
```

Follow this style: type(scope): brief description, then detailed explanation.
````

与单独的描述相比，示例可以帮助代理更清楚地理解所需的风格和详细程度。

### Conditional workflow pattern

引导代理通过决策点：

```markdown  theme={null}
## Document modification workflow

1. Determine the modification type:

   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow:
   - Use docx-js library
   - Build document from scratch
   - Export to .docx format

3. Editing workflow:
   - Unpack existing document
   - Modify XML directly
   - Validate after each change
   - Repack when complete
```

<Tip>
  如果工作流程变得庞大或复杂且包含许多步骤，请考虑将它们推送到单独的文件中，并告诉代理根据手头的任务读取适当的文件。
</Tip>

## Evaluation and iteration

### Build evaluations first

**在编写大量文档之前创建评估。**这可确保您的技能解决实际问题，而不是记录想象的问题。

**Evaluation-driven development:**

1. **找出差距**：让您的代理在没有技能的情况下执行代表性任务。记录特定的失败或缺失的上下文
2. **创建评估**：构建三个场景来测试这些差距
3. **建立基线**：在没有技能的情况下衡量座席的绩效
4. **编写最少的说明**：创建足够的内容来弥补差距并通过评估
5. **迭代**：执行评估、与基线进行比较并完善

这种方法可确保您解决实际问题，而不是预测可能永远不会实现的需求。

**Evaluation structure**:

```json  theme={null}
{
  "skills": ["pdf-processing"],
  "query": "Extract all text from this PDF file and save it to output.txt",
  "files": ["test-files/document.pdf"],
  "expected_behavior": [
    "Successfully reads the PDF file using an appropriate PDF processing library or command-line tool",
    "Extracts text content from all pages in the document without missing any pages",
    "Saves the extracted text to a file named output.txt in a clear, readable format"
  ]
}
```

<Note>
  此示例演示了使用简单测试规则的数据驱动评估。我们目前不提供运行这些评估的内置方法。用户可以创建自己的评价体系。评估是衡量技能有效性的事实来源。
</Note>

### Develop Skills iteratively with the agent

最有效的技能开发过程涉及代理本身。与一个实例（"特工 A"）合作创建一项将由其他实例（"特工 B"）使用的技能。代理 A 帮助您设计和完善指令，而代理 B 在实际任务中测试它们。这是有效的，因为底层模型了解如何编写有效的代理指令以及代理需要什么信息。

**创建新技能：**

1. **无需技能即可完成任务**：使用正常提示与特工 A 一起解决问题。在工作时，您自然会提供背景信息、解释偏好并分享程序知识。注意您反复提供的信息。

2. **确定可重用模式**：完成任务后，确定您提供的上下文对未来类似的任务有用。

   **示例**：如果您进行了 BigQuery 分析，您可能已经提供了表名称、字段定义、过滤规则（例如"始终排除测试帐户"）和常见查询模式。

3. **要求代理 A 创建一项技能**："创建一项技能来捕获我们刚刚使用的 BigQuery 分析模式。包括表架构、命名约定以及有关过滤测试帐户的规则。"

   <Tip>
     现代代理本身就理解技能格式和结构。 You don't need special system prompts or a "writing skills" skill to get help creating Skills.只需要求代理创建一项技能，它就会生成结构正确的 SKILL.md 内容以及适当的 frontmatter 和 body 内容。
   </Tip>

4. **简洁性审查**：检查代理 A 是否没有添加不必要的解释。询问："删除有关胜率含义的解释 - 代理已经知道这一点。"

5. **Improve information architecture**: Ask Agent A to organize the content more effectively. For example: "Organize this so the table schema is in a separate reference file. We might add more tables later."

6. **Test on similar tasks**: Use the Skill with Agent B (a fresh instance with the Skill loaded) on related use cases. Observe whether Agent B finds the right information, applies rules correctly, and handles the task successfully.

7. **基于观察进行迭代**：如果代理 B 遇到困难或错过了某些内容，请返回给代理 A 并提供具体信息："当代理使用此技能时，它忘记按 Q4 的日期进行过滤。我们是否应该添加有关日期过滤模式的部分？"

**迭代现有技能：**

当提高技能时，同样的层次模式继续存在。您可以交替使用：

* **与特工A合作**（帮助完善技能的专家）
* **使用 Agent B 进行测试**（使用技能执行实际工作的 Agent）
* **观察特工 B 的行为**并将见解反馈给特工 A

1. **在真实工作流程中使用技能**：为代理 B（已加载技能）提供实际任务，而不是测试场景

2. **观察代理 B 的行为**：注意它在哪里挣扎、成功或做出意外选择

   **示例观察**："当我向代理 B 索要区域销售报告时，它编写了查询，但忘记过滤掉测试帐户，即使技能提到了此规则。"

3. **返回特工 A 寻求改进**：分享当前的 SKILL.md 并描述您观察到的情况。问："当我要求提供区域报告时，我注意到代理 B 忘记过滤测试帐户。技能中提到了过滤，但可能还不够突出？"

4. **查看代理 A 的建议**：代理 A 可能会建议重新组织以使规则更加突出，使用"必须过滤"而不是"始终过滤"等更强硬的语言，或者重组工作流程部分。

5. **应用并测试更改**：使用代理 A 的改进更新技能，然后使用代理 B 根据类似请求再次测试

6. **根据使用情况重复**：当遇到新场景时，继续此观察-优化-测试循环。每次迭代都会根据真实的代理行为而不是假设来提高技能。

**收集团队反馈：**

1. 与队友分享技能并观察其使用情况
2. 问：技能是否会按预期激活？指示是否清楚？缺少什么？
3. 纳入反馈以解决您自己的使用模式中的盲点

**为什么这种方法有效**：代理 A 了解代理需求，您提供领域专业知识，代理 B 通过实际使用揭示差距，迭代细化基于观察到的行为而不是假设来提高技能。

### Observe how agents navigate Skills

当您迭代技能时，请注意代理在实践中如何实际使用它们。注意：

* **意外的探索路径**：代理是否按照您没有预料到的顺序读取文件？这可能表明您的结构并不像您想象的那么直观
* **错过连接**：代理是否无法遵循对重要文件的引用？您的链接可能需要更明确或更突出
* **过度依赖某些部分**：如果代理重复读取同一文件，请考虑该内容是否应该放在主 SKILL.md 中
* **忽略的内容**：如果代理从不访问捆绑文件，则它可能是不必要的或在主要说明中信号不佳

基于这些观察而不是假设进行迭代。技能元数据中的"名称"和"描述"尤其重要。代理在决定是否触发技能来响应当前任务时使用这些。确保它们清楚地描述了该技能的用途以及何时使用该技能。

## Anti-patterns to avoid

### Avoid Windows-style paths

始终在文件路径中使用正斜杠，即使在 Windows 上也是如此：

* ✓ **好**：`scripts/helper.py`，`reference/guide.md`
* ✗ **避免**：`scripts\helper.py`、`reference\guide.md`

Unix 样式路径适用于所有平台，而 Windows 样式路径会在 Unix 系统上导致错误。

### Avoid offering too many options

除非必要，否则不要提出多种方法：

````markdown  theme={null}
**Bad example: Too many choices** (confusing):
"You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or..."

**Good example: Provide a default** (with escape hatch):
"Use pdfplumber for text extraction:
```python
import pdfplumber
```

For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."
````

## Advanced: Skills with executable code

以下部分重点介绍包含可执行脚本的技能。如果您的技能仅使用降价指令，请跳至[Checklist for effective Skills](#checklist-for-effective-skills)。

### 解决了，别乱扔

为技能编写脚本时，请处理错误情况，而不是向代理下注。

**好例子：明确处理错误**：

```python  theme={null}
def process_file(path):
    """Process a file, creating it if it doesn't exist."""
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        # Create file with default content instead of failing
        print(f"File {path} not found, creating default")
        with open(path, 'w') as f:
            f.write('')
        return ''
    except PermissionError:
        # Provide alternative instead of failing
        print(f"Cannot access {path}, using default")
        return ''
```

**坏例子：转给经纪人**：

```python  theme={null}
def process_file(path):
    # Just fail and let the agent figure it out
    return open(path).read()
```

配置参数也应该合理化并记录在案，以避免"巫术常数"（奥斯特豪特定律）。如果您不知道正确的值，代理将如何确定它？

**很好的例子：自我记录**：

```python  theme={null}
# HTTP requests typically complete within 30 seconds
# Longer timeout accounts for slow connections
REQUEST_TIMEOUT = 30

# Three retries balances reliability vs speed
# Most intermittent failures resolve by the second retry
MAX_RETRIES = 3
```

**坏例子：幻数**：

```python  theme={null}
TIMEOUT = 47  # Why 47?
RETRIES = 5   # Why 5?
```

### Provide utility scripts

即使您的代理可以编写脚本，预制脚本也具有以下优点：

**实用程序脚本的优点**：

* 比生成的代码更可靠
* 保存令牌（无需在上下文中包含代码）
* 节省时间（无需生成代码）
* 确保不同用途的一致性

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=4bbc45f2c2e0bee9f2f0d5da669bad00" alt="Bundling executable scripts alongside instruction files" data-og-width="2048" width="2048" data-og-height="1154" height="1154" data-path="images/agent-skills-executable-scripts.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=9a04e6535a8467bfeea492e517de389f 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=e49333ad90141af17c0d7651cca7216b 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=954265a5df52223d6572b6214168c428 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=2ff7a2d8f2a83ee8af132b29f10150fd 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=48ab96245e04077f4d15e9170e081cfb 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0301a6c8b3ee879497cc5b5483177c90 2500w" />

上图显示了可执行脚本如何与指令文件一起工作。指令文件 (forms.md) 引用脚本，代理可以执行它而无需将其内容加载到上下文中。

**重要区别**：在您的指示中明确代理人是否应该：

* **执行脚本**（最常见）："运行`analyze_form.py`以提取字段"
* **将其作为参考**（对于复杂逻辑）："请参阅`analyze_form.py`了解字段提取算法"

对于大多数实用程序脚本，首选执行，因为它更可靠、更高效。有关脚本执行工作原理的详细信息，请参阅下面的 [Runtime environment](#runtime-environment) 部分。

**Example**:

````markdown  theme={null}
## Utility scripts

**analyze_form.py**: Extract all form fields from PDF

```bash
python scripts/analyze_form.py input.pdf > fields.json
```

Output format:
```json
{
  "字段名称"：{"类型"："文本"，"x"：100，"y"：200}，
  "签名"：{"类型"："sig"，"x"：150，"y"：500}
}
```

**validate_boxes.py**: Check for overlapping bounding boxes

```bash
python scripts/validate_boxes.py fields.json
# 返回："OK"或列出冲突
```

**fill_form.py**: Apply field values to PDF

```bash
python scripts/fill_form.py input.pdf fields.json output.pdf
```
````

### Use visual analysis

当输入可以呈现为图像时，让代理分析它们：

````markdown  theme={null}
## Form layout analysis

1. Convert PDF to images:
   ```bash
   python scripts/pdf_to_images.py form.pdf
   ```

2. Analyze each page image to identify form fields
3. The agent can see field locations and types visually
````

<Note>
  在此示例中，您需要编写 `pdf_to_images.py` 脚本。
</Note>

代理视觉功能有助于理解布局和结构。

### Create verifiable intermediate outputs

当代理执行复杂的、开放式的任务时，他们可能会犯错误。 "计划-验证-执行"模式通过让代理首先以结构化格式创建计划，然后在执行之前使用脚本验证该计划，从而尽早捕获错误。

**示例**：想象一下要求代理根据电子表格更新 PDF 中的 50 个表单字段。如果没有验证，它可能会引用不存在的字段、创建冲突的值、错过必填字段或错误地应用更新。

**解决方案**：使用上面显示的工作流程模式（PDF 表单填写），但添加一个中间 `changes.json` 文件，该文件在应用更改之前进行验证。工作流程变为：分析 → **创建计划文件** → **验证计划** → 执行 → 验证。

**为什么这种模式有效：**

* **及早发现错误**：验证在应用更改之前发现问题
* **机器可验证**：脚本提供客观验证
* **可逆规划**：代理可以迭代计划而不触及原始计划
* **清晰调试**：错误消息指向特定问题

**何时使用**：批量操作、破坏性更改、复杂的验证规则、高风险操作。

**实施提示**：使用特定的错误消息（例如"未找到字段‘signature\_date’。可用字段：customer\_name、order\_total、signature\_date\_signed"）使验证脚本变得详细，以帮助代理解决问题。

### Package dependencies

技能在代码执行环境中运行，具有特定于平台的限制：

* **claude.ai**：可以从 npm 和 PyPI 安装软件包并从 GitHub 存储库中提取
* **Anthropic API**：没有网络访问权限，也没有运行时包安装

列出 SKILL.md 中所需的软件包，并验证它们在 [code execution tool documentation](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool) 中是否可用。

### Runtime environment

技能在具有文件系统访问、bash 命令和代码执行功能的代码执行环境中运行。有关此架构的概念解释，请参阅概述中的[The Skills architecture](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#the-skills-architecture)。

**这如何影响您的创作：**

**客服人员如何获取技能：**

1. **元数据预加载**：启动时，所有技能的 YAML frontmatter 中的名称和描述都会加载到系统提示符中
2. **按需读取文件**：代理使用其文件读取工具在需要时访问文件系统中的 SKILL.md 和其他文件
3. **高效执行脚本**：实用程序脚本可以通过 bash 执行，而无需将其完整内容加载到上下文中。只有脚本的输出消耗令牌
4. **大文件没有上下文惩罚**：参考文件、数据或文档在实际读取之前不会消耗上下文标记

* **文件路径很重要**：代理像文件系统一样导航您的技能目录。使用正斜杠 (`reference/guide.md`)，而不是反斜杠
* **以描述性方式命名文件**：使用指示内容的名称：`form_validation_rules.md`，而不是 `doc2.md`
* **组织发现**：按域或功能构建目录
  * 好：`reference/finance.md`、`reference/sales.md`
  * 坏：`docs/file1.md`，`docs/file2.md`
* **捆绑全面的资源**：包括完整的API文档、广泛的示例、大型数据集；在访问之前没有上下文惩罚
* **首选用于确定性操作的脚本**：编写 `validate_form.py` 而不是要求代理生成验证代码
* **明确执行意图**：
  * "运行 `analyze_form.py` 提取字段"（执行）
  * "提取算法参见`analyze_form.py`"（作为参考阅读）
* **测试文件访问模式**：通过测试真实请求来验证代理是否可以导航您的目录结构

**Example:**

```
bigquery-skill/
├── SKILL.md (overview, points to reference files)
└── reference/
    ├── finance.md (revenue metrics)
    ├── sales.md (pipeline data)
    └── product.md (usage analytics)
```

当用户询问收入时，代理读取 SKILL.md，查看对 `reference/finance.md` 的引用，并调用 bash 来读取该文件。 sales.md 和 product.md 文件保留在文件系统上，在需要之前消耗零上下文令牌。这种基于文件系统的模型使得渐进式公开成为可能。代理可以导航并有选择地准确加载每个任务所需的内容。

有关技术架构的完整详细信息，请参阅技能概述中的 [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work)。

### MCP tool references

如果您的技能使用 MCP（模型上下文协议）工具，请始终使用完全限定的工具名称，以避免"找不到工具"错误。

**Format**: `ServerName:tool_name`

**Example**:

```markdown  theme={null}
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
Use the GitHub:create_issue tool to create issues.
```

Where:

* `BigQuery` 和 `GitHub` 是 MCP 服务器名称
* `bigquery_schema` 和 `create_issue` 是这些服务器中的工具名称

如果没有服务器前缀，代理可能无法找到该工具，尤其是当多个 MCP 服务器可用时。

### Avoid assuming tools are installed

不要假设软件包可用：

````markdown  theme={null}
**Bad example: Assumes installation**:
"Use the pdf library to process the file."

**Good example: Explicit about dependencies**:
"Install required package: `pip install pypdf`

Then use it:
```python
从 pypdf 导入 PdfReader
reader = PdfReader("文件.pdf")
```"
````

## Technical notes

### YAML frontmatter requirements

SKILL.md frontmatter 需要 `name`（最多 64 个字符）和 `description`（最多 1024 个字符）字段。有关完整的结构详细信息，请参阅[Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure)。

### Token budgets

将 SKILL.md 正文保持在 500 行以下，以获得最佳性能。如果您的内容超出此范围，请使用前面描述的渐进式披露模式将其拆分为单独的文件。有关架构详细信息，请参阅[Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work)。

## Checklist for effective Skills

在分享技能之前，请验证：

### Core quality

* [ ] 描述具体并包含关键术语
* [ ] 描述包括该技能的用途以及何时使用该技能
* [ ] SKILL.md 正文低于 500 行
* [ ] 其他详细信息位于单独的文件中（如果需要）
* [ ] 没有时间敏感的信息（或在"旧模式"部分）
* [ ] Consistent terminology throughout
* [ ] 例子是具体的，而不是抽象的
* [ ] 文件引用深一层
* [ ] 适当使用渐进式披露
* [ ] 工作流程步骤清晰

### Code and scripts

* [ ] 脚本解决问题而不是向代理下注
* [ ] 错误处理是明确且有帮助的
* [ ] 没有"巫毒常量"（所有值均合理）
* [ ] 说明中列出了所需的软件包并验证为可用
* [ ] 脚本有清晰的文档
* [ ] 没有 Windows 风格的路径（全是正斜杠）
* [ ] 关键操作的验证/verification步骤
* [ ] 包含针对质量关键任务的反馈循环

### Testing

* [ ] At least three evaluations created
* [ ] 使用 Haiku、Sonnet 和 Opus 进行测试
* [ ] 经过真实使用场景测试
* [ ] 纳入团队反馈（如果适用）

## Next steps

<CardGroup cols={2}>
  <Card title="Get started with Agent Skills" icon="rocket" href="https://platform.claude.com/docs/en/agents-and-tools/agent-skills/quickstart">
    创建你的第一个技能
  </Card>

  <Card title="Use Skills in Claude Code" icon="terminal" href="https://code.claude.com/docs/en/skills">
    在 Claude Code 中创建和管理技能
  </Card>

  <Card title="Use Skills with the API" icon="code" href="https://platform.claude.com/docs/en/build-with-claude/skills-guide">
    Upload and use Skills programmatically
  </Card>
</CardGroup>
