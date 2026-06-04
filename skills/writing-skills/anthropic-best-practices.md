# Skill 编写最佳实践

> 学习如何编写有效的 Skills，让 Claude 能够发现并成功使用它们。

好的 Skills 应当简洁、结构清晰，并经过真实使用场景测试。本指南提供实用的编写决策，帮助你写出 Claude 能发现并有效使用的 Skills。

关于 Skills 工作方式的概念背景，请参阅 [Skills overview](/en/docs/agents-and-tools/agent-skills/overview)。

## 核心原则

### 简洁是关键

[context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) 是公共资源。你的 Skill 会与 Claude 需要知道的其他所有内容共享 context window，包括：

* system prompt
* conversation history
* 其他 Skills 的 metadata
* 用户的实际请求

并不是 Skill 里的每个 token 都会立即产生成本。启动时，所有 Skills 只会预加载 metadata（name 和 description）。Claude 只有在 Skill 相关时才读取 SKILL.md，并且只在需要时读取额外文件。不过，SKILL.md 保持简洁仍然重要：一旦 Claude 加载它，每个 token 都会和 conversation history 以及其他 context 竞争空间。

**默认假设**：Claude 已经非常聪明。

只添加 Claude 尚不知道的 context。逐条挑战每一份信息：

* “Claude 真的需要这段解释吗？”
* “我能否假设 Claude 已经知道这件事？”
* “这段内容值得占用这些 token 吗？”

**好例子：简洁**（约 50 tokens）：

````markdown  theme={null}
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

**坏例子：过于冗长**（约 150 tokens）：

```markdown  theme={null}
## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available for PDF processing, but we
recommend pdfplumber because it's easy to use and handles most cases well.
First, you'll need to install it using pip. Then you can use the code below...
```

简洁版本假设 Claude 已经知道 PDF 是什么，也知道 library 如何工作。

### 设置合适的自由度

让具体程度匹配任务的脆弱性和可变性。

**高自由度**（文本型说明）：

适用于：

* 多种做法都有效
* 决策取决于 context
* 主要依靠 heuristic 指导

示例：

```markdown  theme={null}
## Code review process

1. Analyze the code structure and organization
2. Check for potential bugs or edge cases
3. Suggest improvements for readability and maintainability
4. Verify adherence to project conventions
```

**中等自由度**（带参数的 pseudocode 或 scripts）：

适用于：

* 存在偏好的模式
* 允许一定变化
* 配置会影响行为

示例：

````markdown  theme={null}
## Generate report

Use this template and customize as needed:

```python
def generate_report(data, format="markdown", include_charts=True):
    # Process data
    # Generate output in specified format
    # Optionally include visualizations
```
````

**低自由度**（具体 scripts，少量或无参数）：

适用于：

* 操作脆弱且容易出错
* 一致性至关重要
* 必须遵循特定顺序

示例：

````markdown  theme={null}
## Database migration

Run exactly this script:

```bash
python scripts/migrate.py --verify --backup
```

Do not modify the command or add additional flags.
````

**类比**：把 Claude 想成一个正在探索路径的机器人：

* **两侧都是悬崖的窄桥**：只有一种安全前进方式。提供明确 guardrails 和精确说明（低自由度）。例如必须按精确顺序运行的 database migrations。
* **没有危险的开阔地**：许多路径都能成功。给出总体方向，并信任 Claude 找到最佳路径（高自由度）。例如 code reviews，最佳方式由 context 决定。

### 用计划支持的所有模型测试

Skills 是对模型能力的补充，因此效果取决于底层模型。请用你计划搭配使用的所有模型测试 Skill。

**按模型划分的测试关注点**：

* **Claude Haiku**（快速、经济）：Skill 是否提供了足够指导？
* **Claude Sonnet**（平衡）：Skill 是否清晰、高效？
* **Claude Opus**（强推理）：Skill 是否避免了过度解释？

对 Opus 完美有效的内容，Haiku 可能需要更多细节。如果你计划让 Skill 跨多个模型使用，请力求说明对所有模型都足够有效。

## Skill 结构

<Note>
  **YAML Frontmatter**：SKILL.md frontmatter 需要两个字段：

  * `name` - Skill 的人类可读名称（最多 64 个字符）
  * `description` - 一行描述 Skill 做什么以及何时使用（最多 1024 个字符）

  完整 Skill 结构细节见 [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure)。
</Note>

### 命名约定

使用一致的命名模式，让 Skills 更容易被引用和讨论。建议 Skill names 使用 **gerund form**（动词 + -ing），因为这能清楚描述 Skill 提供的活动或能力。

**好的命名示例（gerund form）**：

* "Processing PDFs"
* "Analyzing spreadsheets"
* "Managing databases"
* "Testing code"
* "Writing documentation"

**可接受的替代形式**：

* 名词短语："PDF Processing", "Spreadsheet Analysis"
* 面向动作："Process PDFs", "Analyze Spreadsheets"

**避免**：

* 含糊名称："Helper", "Utils", "Tools"
* 过度泛化："Documents", "Data", "Files"
* 同一 skill collection 内命名模式不一致

一致命名能帮助你：

* 在文档和对话中引用 Skills
* 一眼理解 Skill 的作用
* 组织和搜索多个 Skills
* 维护专业、统一的 skill library

### 编写有效 description

`description` 字段用于 Skill discovery，应同时包含 Skill 做什么以及何时使用。

<Warning>
  **始终使用第三人称**。description 会注入 system prompt，不一致的视角会造成 discovery 问题。

  * **好：** "Processes Excel files and generates reports"
  * **避免：** "I can help you process Excel files"
  * **避免：** "You can use this to process Excel files"
</Warning>

**要具体，并包含关键术语**。同时写清 Skill 做什么，以及触发使用它的具体场景/context。

每个 Skill 只有一个 description 字段。description 对 skill selection 至关重要：Claude 会用它从可能超过 100 个 Skills 中选择正确 Skill。你的 description 必须提供足够细节，让 Claude 知道何时选择此 Skill；SKILL.md 的其余部分再提供实现细节。

有效示例：

**PDF Processing skill：**

```yaml  theme={null}
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

**Excel Analysis skill：**

```yaml  theme={null}
description: Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files.
```

**Git Commit Helper skill：**

```yaml  theme={null}
description: Generate descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
```

避免这类含糊 description：

```yaml  theme={null}
description: Helps with documents
```

```yaml  theme={null}
description: Processes data
```

```yaml  theme={null}
description: Does stuff with files
```

### Progressive disclosure 模式

SKILL.md 作为 overview，把 Claude 按需引导到详细材料，就像 onboarding guide 的目录。关于 progressive disclosure 的工作方式，请参阅 overview 中的 [How Skills work](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work)。

**实用建议：**

* 为获得最佳性能，让 SKILL.md body 保持在 500 行以内
* 接近此限制时，把内容拆分到单独文件
* 使用下面的模式有效组织说明、代码和资源

#### 可视化概览：从简单到复杂

基础 Skill 只需要一个包含 metadata 和说明的 SKILL.md 文件：

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=87782ff239b297d9a9e8e1b72ed72db9" alt="Simple SKILL.md file showing YAML frontmatter and markdown body" data-og-width="2048" width="2048" data-og-height="1153" height="1153" data-path="images/agent-skills-simple-file.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=c61cc33b6f5855809907f7fda94cd80e 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=90d2c0c1c76b36e8d485f49e0810dbfd 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=ad17d231ac7b0bea7e5b4d58fb4aeabb 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f5d0a7a3c668435bb0aee9a3a8f8c329 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0e927c1af9de5799cfe557d12249f6e6 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=46bbb1a51dd4c8202a470ac8c80a893d 2500w" />

随着 Skill 增长，你可以捆绑额外内容，让 Claude 只在需要时加载：

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=a5e0aa41e3d53985a7e3e43668a33ea3" alt="Bundling additional reference files like reference.md and forms.md." data-og-width="2048" width="2048" data-og-height="1327" height="1327" data-path="images/agent-skills-bundling-content.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f8a0e73783e99b4a643d79eac86b70a2 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=dc510a2a9d3f14359416b706f067904a 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=82cd6286c966303f7dd914c28170e385 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=56f3be36c77e4fe4b523df209a6824c6 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=d22b5161b2075656417d56f41a74f3dd 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=3dd4bdd6850ffcc96c6c45fcb0acd6eb 2500w" />

完整 Skill 目录结构可能如下：

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

#### 模式 1：带 references 的高层指南

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
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

## Advanced features

**Form filling**: See [FORMS.md](FORMS.md) for complete guide
**API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
**Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
````

Claude 只在需要时加载 FORMS.md、REFERENCE.md 或 EXAMPLES.md。

#### 模式 2：按领域组织

对于包含多个 domain 的 Skills，按 domain 组织内容，避免加载无关 context。当用户询问 sales metrics 时，Claude 只需要读取 sales 相关 schema，不需要 finance 或 marketing 数据。这样能降低 token 使用量并保持 context 聚焦。

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
grep -i "revenue" reference/finance.md
grep -i "pipeline" reference/sales.md
grep -i "api usage" reference/product.md
```
````

#### 模式 3：条件式细节

展示基础内容，并链接到高级内容：

```markdown  theme={null}
# DOCX Processing

## Creating documents

Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents

For simple edits, modify the XML directly.

**For tracked changes**: See [REDLINING.md](REDLINING.md)
**For OOXML details**: See [OOXML.md](OOXML.md)
```

Claude 只在用户需要这些功能时读取 REDLINING.md 或 OOXML.md。

### 避免深层嵌套 references

当 reference 文件再引用其他 reference 文件时，Claude 可能只会部分读取文件。遇到嵌套 references 时，Claude 可能用 `head -100` 等命令预览内容，而不是读取整份文件，导致信息不完整。

**保持 references 距 SKILL.md 只有一层**。所有 reference files 都应从 SKILL.md 直接链接，确保 Claude 需要时能完整读取。

**坏例子：太深**：

```markdown  theme={null}
# SKILL.md
See [advanced.md](advanced.md)...

# advanced.md
See [details.md](details.md)...

# details.md
Here's the actual information...
```

**好例子：一层深度**：

```markdown  theme={null}
# SKILL.md

**Basic usage**: [instructions in SKILL.md]
**Advanced features**: See [advanced.md](advanced.md)
**API reference**: See [reference.md](reference.md)
**Examples**: See [examples.md](examples.md)
```

### 为较长 reference 文件添加目录

超过 100 行的 reference 文件，应在顶部包含 table of contents。这样即使 Claude 只做部分预览，也能看到可用信息的完整范围。

**示例**：

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

随后 Claude 可以读取完整文件，或按需跳转到特定章节。

关于这种基于 filesystem 的架构如何支持 progressive disclosure，见下方 Advanced section 中的 [Runtime environment](#runtime-environment)。

## Workflows 与 feedback loops

### 为复杂任务使用 workflows

把复杂操作拆成清晰、连续的步骤。对于特别复杂的 workflows，提供一个 Claude 可以复制到回复里并逐项勾选的 checklist。

**示例 1：Research synthesis workflow**（适用于不含代码的 Skills）：

````markdown  theme={null}
## Research synthesis workflow

Copy this checklist and track your progress:

```
Research Progress:
- [ ] Step 1: Read all source documents
- [ ] Step 2: Identify key themes
- [ ] Step 3: Cross-reference claims
- [ ] Step 4: Create structured summary
- [ ] Step 5: Verify citations
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

这个示例展示 workflows 如何应用于不需要代码的分析任务。checklist 模式适用于任何复杂的多步骤流程。

**示例 2：PDF form filling workflow**（适用于含代码的 Skills）：

````markdown  theme={null}
## PDF form filling workflow

Copy this checklist and check off items as you complete them:

```
Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)
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

清晰步骤能防止 Claude 跳过关键验证。checklist 能帮助 Claude 和用户共同追踪多步骤 workflow 的进展。

### 实现 feedback loops

**常见模式**：运行 validator → 修复 errors → 重复。

这个模式能显著提升输出质量。

**示例 1：Style guide compliance**（适用于不含代码的 Skills）：

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

这里展示了用 reference documents 而不是 scripts 实现 validation loop 的模式。“validator” 是 STYLE_GUIDE.md，Claude 通过阅读和比对完成检查。

**示例 2：Document editing process**（适用于含代码的 Skills）：

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

validation loop 能尽早捕获错误。

## 内容准则

### 避免时效性信息

不要包含会过期的信息：

**坏例子：时效性强**（未来会变错）：

```markdown  theme={null}
If you're doing this before August 2025, use the old API.
After August 2025, use the new API.
```

**好例子**（使用 "old patterns" section）：

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

old patterns section 提供历史 context，同时不干扰主内容。

### 使用一致术语

选择一个术语并在整个 Skill 中保持一致：

**好 - 一致**：

* 始终使用 "API endpoint"
* 始终使用 "field"
* 始终使用 "extract"

**坏 - 不一致**：

* 混用 "API endpoint"、"URL"、"API route"、"path"
* 混用 "field"、"box"、"element"、"control"
* 混用 "extract"、"pull"、"get"、"retrieve"

一致性帮助 Claude 理解并遵循说明。

## 常见模式

### Template pattern

提供输出格式 templates。根据需求匹配严格程度。

**用于严格要求**（如 API responses 或 data formats）：

````markdown  theme={null}
## Report structure

ALWAYS use this exact template structure:

```markdown
# [Analysis Title]

## Executive summary
[One-paragraph overview of key findings]

## Key findings
- Finding 1 with supporting data
- Finding 2 with supporting data
- Finding 3 with supporting data

## Recommendations
1. Specific actionable recommendation
2. Specific actionable recommendation
```
````

**用于灵活指导**（适合需要适配的场景）：

````markdown  theme={null}
## Report structure

Here is a sensible default format, but use your best judgment based on the analysis:

```markdown
# [Analysis Title]

## Executive summary
[Overview]

## Key findings
[Adapt sections based on what you discover]

## Recommendations
[Tailor to the specific context]
```

Adjust sections as needed for the specific analysis type.
````

### Examples pattern

对于输出质量依赖示例的 Skills，像常规 prompting 一样提供 input/output pairs：

````markdown  theme={null}
## Commit message format

Generate commit messages following these examples:

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

**Example 2:**
Input: Fixed bug where dates displayed incorrectly in reports
Output:
```
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation
```

**Example 3:**
Input: Updated dependencies and refactored error handling
Output:
```
chore: update dependencies and refactor error handling

- Upgrade lodash to 4.17.21
- Standardize error response format across endpoints
```

Follow this style: type(scope): brief description, then detailed explanation.
````

示例能比单纯描述更清楚地帮助 Claude 理解期望风格和细节层级。

### Conditional workflow pattern

引导 Claude 经过决策点：

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
  如果 workflows 变得庞大或步骤很多，考虑把它们放进单独文件，并告诉 Claude 根据当前任务读取合适文件。
</Tip>

## Evaluation 与迭代

### 先构建 evaluations

**在编写大量文档前先创建 evaluations。** 这能确保 Skill 解决真实问题，而不是只是在记录想象中的需求。

**Evaluation-driven development：**

1. **识别 gaps**：在没有 Skill 的情况下，让 Claude 执行代表性任务。记录具体失败或缺失 context
2. **创建 evaluations**：构建三个测试这些 gaps 的 scenarios
3. **建立 baseline**：衡量无 Skill 时 Claude 的表现
4. **编写最小说明**：只创建足够解决 gaps 并通过 evaluations 的内容
5. **迭代**：执行 evaluations，与 baseline 比较，并精炼内容

这种方法能确保你解决实际问题，而不是预判可能永远不会出现的需求。

**Evaluation structure**：

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
  这个示例展示了带简单 testing rubric 的 data-driven evaluation。我们目前不提供内置运行这些 evaluations 的方式。用户可以创建自己的 evaluation system。Evaluations 是衡量 Skill 效果的 source of truth。
</Note>

### 与 Claude 迭代开发 Skills

最高效的 Skill 开发过程会让 Claude 本身参与进来。你可以和一个 Claude 实例（“Claude A”）一起创建供其他实例（“Claude B”）使用的 Skill。Claude A 帮你设计并精炼说明，Claude B 在真实任务中测试它们。这之所以有效，是因为 Claude models 同时理解如何写有效的 agent instructions，以及 agents 需要哪些信息。

**创建新 Skill：**

1. **不使用 Skill 完成一次任务**：用普通 prompting 和 Claude A 解决一个问题。在过程中，你会自然提供 context、解释偏好、分享流程知识。注意哪些信息你反复提供。

2. **识别可复用模式**：完成任务后，识别你提供过哪些 context 对未来类似任务有用。

   **示例**：如果你完成了一次 BigQuery analysis，你可能提供了 table names、field definitions、filtering rules（如“始终排除 test accounts”）以及常见 query patterns。

3. **让 Claude A 创建 Skill**："Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."

   <Tip>
     Claude models 原生理解 Skill format 和 structure。你不需要特殊 system prompts，也不需要 "writing skills" skill，就能让 Claude 帮你创建 Skills。直接要求 Claude 创建 Skill，它会生成结构正确、包含合适 frontmatter 和 body content 的 SKILL.md。
   </Tip>

4. **检查简洁性**：确认 Claude A 没有加入不必要解释。可以要求："Remove the explanation about what win rate means - Claude already knows that."

5. **改进 information architecture**：要求 Claude A 更有效组织内容。例如："Organize this so the table schema is in a separate reference file. We might add more tables later."

6. **在相似任务中测试**：让 Claude B（加载了 Skill 的新实例）在相关 use cases 上使用此 Skill。观察 Claude B 是否找到正确信息、正确应用规则并成功完成任务。

7. **根据观察迭代**：如果 Claude B 卡住或遗漏内容，把具体情况带回 Claude A："When Claude used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"

**迭代已有 Skills：**

改进 Skills 时同样使用这种分层模式。你在以下三件事之间交替：

* **与 Claude A 合作**（帮助精炼 Skill 的专家）
* **用 Claude B 测试**（使用 Skill 完成真实工作的 agent）
* **观察 Claude B 的行为**，并把 insight 带回 Claude A

1. **在真实 workflows 中使用 Skill**：给 Claude B（加载了 Skill）真实任务，而不是只给 test scenarios。

2. **观察 Claude B 的行为**：记录它在哪里卡住、成功或做出意外选择。

   **示例观察**："When I asked Claude B for a regional sales report, it wrote the query but forgot to filter out test accounts, even though the Skill mentions this rule."

3. **回到 Claude A 寻求改进**：分享当前 SKILL.md 并描述观察结果。询问："I noticed Claude B forgot to filter test accounts when I asked for a regional report. The Skill mentions filtering, but maybe it's not prominent enough?"

4. **审查 Claude A 的建议**：Claude A 可能建议重组内容让规则更醒目，使用 "MUST filter" 而不是 "always filter" 这类更强语言，或重构 workflow section。

5. **应用并测试变更**：用 Claude A 的 refined 内容更新 Skill，然后再次让 Claude B 在类似请求上测试。

6. **根据使用持续重复**：遇到新场景时继续 observe-refine-test cycle。每次迭代都基于真实 agent behavior 改进 Skill，而不是基于假设。

**收集团队反馈：**

1. 与队友分享 Skills，并观察他们的使用方式
2. 询问：Skill 是否按预期激活？说明是否清楚？缺少什么？
3. 纳入反馈，弥补你自己使用模式中的 blind spots

**为什么这种方法有效**：Claude A 理解 agent needs，你提供 domain expertise，Claude B 通过真实使用暴露 gaps，迭代式 refinement 让 Skills 基于观察到的行为而不是假设不断改进。

### 观察 Claude 如何浏览 Skills

迭代 Skills 时，留意 Claude 在实践中实际如何使用它们。观察：

* **意外探索路径**：Claude 是否以你没预料的顺序读取文件？这可能说明结构没有你想象中直观
* **错过连接**：Claude 是否没有跟随指向重要文件的 references？你的链接可能需要更明确或更醒目
* **过度依赖某些 sections**：如果 Claude 反复读取同一文件，考虑这部分内容是否应放进主 SKILL.md
* **被忽略的内容**：如果 Claude 从不访问某个 bundled file，它可能不必要，或在主说明中的提示不够清晰

基于这些观察迭代，而不是基于假设。Skill metadata 中的 `name` 和 `description` 尤其关键。Claude 会用它们判断当前任务是否应触发该 Skill。确保它们清楚描述 Skill 做什么以及何时使用。

## 应避免的 anti-patterns

### 避免 Windows-style paths

即使在 Windows 上，也始终在文件路径中使用 forward slashes：

* ✓ **好**：`scripts/helper.py`, `reference/guide.md`
* ✗ **避免**：`scripts\helper.py`, `reference\guide.md`

Unix-style paths 可跨平台工作，而 Windows-style paths 会在 Unix 系统上出错。

### 避免提供过多选项

除非必要，不要提供多个 approach：

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

## Advanced：带可执行代码的 Skills

以下 sections 关注包含 executable scripts 的 Skills。如果你的 Skill 只使用 markdown instructions，请跳到 [Checklist for effective Skills](#checklist-for-effective-skills)。

### 解决问题，不要甩给 Claude

为 Skills 编写 scripts 时，应处理错误条件，而不是把问题甩给 Claude。

**好例子：显式处理 errors**：

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

**坏例子：甩给 Claude**：

```python  theme={null}
def process_file(path):
    # Just fail and let Claude figure it out
    return open(path).read()
```

Configuration parameters 也应被解释和记录，避免 "voodoo constants"（Ousterhout's law）。如果你不知道正确值是什么，Claude 又如何判断？

**好例子：自解释**：

```python  theme={null}
# HTTP requests typically complete within 30 seconds
# Longer timeout accounts for slow connections
REQUEST_TIMEOUT = 30

# Three retries balances reliability vs speed
# Most intermittent failures resolve by the second retry
MAX_RETRIES = 3
```

**坏例子：magic numbers**：

```python  theme={null}
TIMEOUT = 47  # Why 47?
RETRIES = 5   # Why 5?
```

### 提供 utility scripts

即使 Claude 能自己写 script，预制 scripts 仍有优势：

**Utility scripts 的好处**：

* 比生成代码更可靠
* 节省 tokens（无需把代码放进 context）
* 节省时间（无需生成代码）
* 保证多次使用的一致性

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=4bbc45f2c2e0bee9f2f0d5da669bad00" alt="Bundling executable scripts alongside instruction files" data-og-width="2048" width="2048" data-og-height="1154" height="1154" data-path="images/agent-skills-executable-scripts.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=9a04e6535a8467bfeea492e517de389f 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=e49333ad90141af17c0d7651cca7216b 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=954265a5df52223d6572b6214168c428 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=2ff7a2d8f2a83ee8af132b29f10150fd 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=48ab96245e04077f4d15e9170e081cfb 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0301a6c8b3ee879497cc5b5483177c90 2500w" />

上图展示 executable scripts 如何与 instruction files 协作。instruction file（forms.md）引用 script，Claude 可以执行它，而无需把 script 内容加载进 context。

**重要区分**：在说明中明确 Claude 应该：

* **执行 script**（最常见）："Run `analyze_form.py` to extract fields"
* **作为 reference 阅读**（用于复杂逻辑）："See `analyze_form.py` for the field extraction algorithm"

对于大多数 utility scripts，执行比阅读更可靠、更高效。script execution 的工作细节见下方 [Runtime environment](#runtime-environment)。

**示例**：

````markdown  theme={null}
## Utility scripts

**analyze_form.py**: Extract all form fields from PDF

```bash
python scripts/analyze_form.py input.pdf > fields.json
```

Output format:
```json
{
  "field_name": {"type": "text", "x": 100, "y": 200},
  "signature": {"type": "sig", "x": 150, "y": 500}
}
```

**validate_boxes.py**: Check for overlapping bounding boxes

```bash
python scripts/validate_boxes.py fields.json
# Returns: "OK" or lists conflicts
```

**fill_form.py**: Apply field values to PDF

```bash
python scripts/fill_form.py input.pdf fields.json output.pdf
```
````

### 使用 visual analysis

当输入可以渲染成图像时，让 Claude 分析它们：

````markdown  theme={null}
## Form layout analysis

1. Convert PDF to images:
   ```bash
   python scripts/pdf_to_images.py form.pdf
   ```

2. Analyze each page image to identify form fields
3. Claude can see field locations and types visually
````

<Note>
  在这个示例中，你需要编写 `pdf_to_images.py` script。
</Note>

Claude 的 vision capabilities 有助于理解 layouts 和 structures。

### 创建可验证的 intermediate outputs

当 Claude 执行复杂、开放式任务时，可能会犯错。"plan-validate-execute" pattern 通过让 Claude 先用结构化格式创建 plan，再用 script 验证 plan，最后执行，来尽早捕获错误。

**示例**：假设你要求 Claude 根据 spreadsheet 更新 PDF 中的 50 个 form fields。没有 validation 时，Claude 可能引用不存在的 fields、创建冲突 values、漏掉 required fields，或错误应用 updates。

**解决方案**：使用上面展示的 workflow pattern（PDF form filling），但增加一个在应用 changes 前被验证的 intermediate `changes.json` 文件。workflow 变为：analyze → **create plan file** → **validate plan** → execute → verify。

**为什么这个 pattern 有效：**

* **尽早捕错**：Validation 在 changes 应用前发现问题
* **机器可验证**：Scripts 提供客观 verification
* **可逆 planning**：Claude 可以在不触碰 originals 的情况下迭代 plan
* **清晰 debugging**：Error messages 指向具体问题

**何时使用**：Batch operations、destructive changes、complex validation rules、high-stakes operations。

**实现建议**：让 validation scripts 输出详细而具体的 error messages，例如 "Field 'signature\_date' not found. Available fields: customer\_name, order\_total, signature\_date\_signed"，帮助 Claude 修复问题。

### Package dependencies

Skills 在 code execution environment 中运行，存在平台特定限制：

* **claude.ai**：可以从 npm 和 PyPI 安装 packages，也可以从 GitHub repositories 拉取
* **Anthropic API**：没有 network access，也不能在 runtime 安装 packages

在 SKILL.md 中列出 required packages，并确认它们在 [code execution tool documentation](/en/docs/agents-and-tools/tool-use/code-execution-tool) 中可用。

### Runtime environment

Skills 运行在具备 filesystem access、bash commands 和 code execution capabilities 的 code execution environment 中。关于此架构的概念说明，见 overview 中的 [The Skills architecture](/en/docs/agents-and-tools/agent-skills/overview#the-skills-architecture)。

**这对编写的影响：**

**Claude 如何访问 Skills：**

1. **Metadata pre-loaded**：启动时，所有 Skills YAML frontmatter 中的 name 和 description 会加载进 system prompt
2. **按需读取文件**：Claude 在需要时使用 bash Read tools 从 filesystem 读取 SKILL.md 和其他文件
3. **高效执行 scripts**：Utility scripts 可以通过 bash 执行，不必把完整内容加载进 context。只有 script output 消耗 tokens
4. **大文件无 context penalty**：Reference files、data 或 documentation 在实际读取前不消耗 context tokens

* **File paths 很重要**：Claude 像浏览 filesystem 一样浏览 skill directory。使用 forward slashes（`reference/guide.md`），不要用 backslashes
* **文件名要有描述性**：使用能表达内容的名称，如 `form_validation_rules.md`，不要用 `doc2.md`
* **为 discovery 组织结构**：按 domain 或 feature 组织目录
  * 好：`reference/finance.md`, `reference/sales.md`
  * 坏：`docs/file1.md`, `docs/file2.md`
* **捆绑完整资源**：包含完整 API docs、丰富 examples、大 datasets；未访问前没有 context penalty
* **确定性操作优先使用 scripts**：编写 `validate_form.py`，而不是要求 Claude 生成 validation code
* **明确 execution intent**：
  * "Run `analyze_form.py` to extract fields"（execute）
  * "See `analyze_form.py` for the extraction algorithm"（read as reference）
* **测试 file access patterns**：用真实请求验证 Claude 能浏览你的目录结构

**示例：**

```
bigquery-skill/
├── SKILL.md (overview, points to reference files)
└── reference/
    ├── finance.md (revenue metrics)
    ├── sales.md (pipeline data)
    └── product.md (usage analytics)
```

当用户询问 revenue 时，Claude 读取 SKILL.md，看到指向 `reference/finance.md` 的 reference，然后调用 bash 只读取该文件。sales.md 和 product.md 保留在 filesystem 上，在需要前消耗零 context tokens。这种基于 filesystem 的模型正是 progressive disclosure 得以实现的原因。Claude 可以按每个任务所需精确浏览并选择性加载内容。

技术架构完整细节见 Skills overview 中的 [How Skills work](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work)。

### MCP tool references

如果 Skill 使用 MCP（Model Context Protocol）tools，始终使用 fully qualified tool names，避免 "tool not found" errors。

**格式**：`ServerName:tool_name`

**示例**：

```markdown  theme={null}
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
Use the GitHub:create_issue tool to create issues.
```

其中：

* `BigQuery` 和 `GitHub` 是 MCP server names
* `bigquery_schema` 和 `create_issue` 是这些 servers 内的 tool names

没有 server prefix 时，Claude 可能无法定位 tool，尤其当多个 MCP servers 可用时。

### 避免假设 tools 已安装

不要假设 packages 可用：

````markdown  theme={null}
**Bad example: Assumes installation**:
"Use the pdf library to process the file."

**Good example: Explicit about dependencies**:
"Install required package: `pip install pypdf`

Then use it:
```python
from pypdf import PdfReader
reader = PdfReader("file.pdf")
```"
````

## Technical notes

### YAML frontmatter requirements

SKILL.md frontmatter 需要 `name`（最多 64 个字符）和 `description`（最多 1024 个字符）字段。完整结构细节见 [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure)。

### Token budgets

为获得最佳性能，SKILL.md body 应保持在 500 行以内。如果内容超过此长度，使用前面描述的 progressive disclosure patterns 拆分为单独文件。架构细节见 [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work)。

## Effective Skills checklist

分享 Skill 前，请验证：

### Core quality

* [ ] Description 具体且包含 key terms
* [ ] Description 同时说明 Skill 做什么以及何时使用
* [ ] SKILL.md body 低于 500 行
* [ ] 额外细节放在单独文件中（如果需要）
* [ ] 没有时效性信息（或放在 "old patterns" section）
* [ ] 全文术语一致
* [ ] Examples 具体而非抽象
* [ ] File references 只有一层深度
* [ ] 合理使用 progressive disclosure
* [ ] Workflows 有清晰步骤

### Code and scripts

* [ ] Scripts 解决问题，而不是把问题甩给 Claude
* [ ] Error handling 显式且有帮助
* [ ] 没有 "voodoo constants"（所有值都有理由）
* [ ] Required packages 已在说明中列出并确认可用
* [ ] Scripts 有清晰 documentation
* [ ] 没有 Windows-style paths（全部使用 forward slashes）
* [ ] 关键操作包含 validation/verification steps
* [ ] 质量关键任务包含 feedback loops

### Testing

* [ ] 至少创建三个 evaluations
* [ ] 已用 Haiku、Sonnet 和 Opus 测试
* [ ] 已用真实使用场景测试
* [ ] 已纳入团队反馈（如适用）

## Next steps

<CardGroup cols={2}>
  <Card title="Get started with Agent Skills" icon="rocket" href="/en/docs/agents-and-tools/agent-skills/quickstart">
    Create your first Skill
  </Card>

  <Card title="Use Skills in Claude Code" icon="terminal" href="/en/docs/claude-code/skills">
    Create and manage Skills in Claude Code
  </Card>

  <Card title="Use Skills with the API" icon="code" href="/en/api/skills-guide">
    Upload and use Skills programmatically
  </Card>
</CardGroup>
