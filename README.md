# Superpowers

Superpowers 是一套完整的软件开发方法论，面向你的 coding agents 构建。它基于一组可组合的 skills，以及一小段确保 agent 会使用这些 skills 的初始指令。

## 快速开始

给你的 agent 装上 Superpowers：[Claude Code](#claude-code)、[Codex CLI](#codex-cli)、[Codex App](#codex-app)、[Factory Droid](#factory-droid)、[Gemini CLI](#gemini-cli)、[OpenCode](#opencode)、[Cursor](#cursor)、[GitHub Copilot CLI](#github-copilot-cli)。

## 工作方式

它从你启动 coding agent 的那一刻开始生效。一旦 agent 看到你在构建东西，它*不会*立刻跳进写代码。相反，它会后退一步，问清楚你真正想做什么。

当它从对话中梳理出 spec 后，会把内容拆成足够短的小段展示给你，让你真的能读完、消化。

在你确认设计之后，agent 会整理出一份实现计划。计划要清楚到足够让一个热情但品味糟糕、没有判断力、没有项目上下文、还讨厌测试的 junior engineer 照着执行。它强调真正的 red/green TDD、YAGNI (You Aren't Gonna Need It) 和 DRY。

接下来，当你说 "go" 后，它会启动 *subagent-driven-development* 流程，让 agents 逐项处理工程任务、检查并 review 自己的工作，然后继续推进。Claude 能够一次自主工作几个小时而不偏离你们共同制定的计划，这并不少见。

里面还有更多细节，但这就是系统的核心。因为 skills 会自动触发，你不需要做任何特别操作。你的 coding agent 直接拥有 Superpowers。

## 赞助

如果 Superpowers 帮你做出了能赚钱的东西，而你也愿意支持，我会非常感激你考虑[赞助我的 opensource 工作](https://github.com/sponsors/obra)。

谢谢！

- Jesse

## 安装

不同 harness 的安装方式不同。如果你使用多个 harness，请分别为每一个安装 Superpowers。

### Claude Code

Superpowers 可通过 [official Claude plugin marketplace](https://claude.com/plugins/superpowers) 获取。

#### Official Marketplace

- 从 Anthropic 的 official marketplace 安装 plugin：

  ```bash
  /plugin install superpowers@claude-plugins-official
  ```

#### Superpowers Marketplace

Superpowers marketplace 为 Claude Code 提供 Superpowers 和一些其他相关 plugins。

- 注册 marketplace：

  ```bash
  /plugin marketplace add obra/superpowers-marketplace
  ```

- 从这个 marketplace 安装 plugin：

  ```bash
  /plugin install superpowers@superpowers-marketplace
  ```

### Codex CLI

Superpowers 可通过 [official Codex plugin marketplace](https://github.com/openai/plugins) 获取。

- 打开 plugin 搜索界面：

  ```bash
  /plugins
  ```

- 搜索 Superpowers：

  ```bash
  superpowers
  ```

- 选择 `Install Plugin`。

### Codex App

Superpowers 可通过 [official Codex plugin marketplace](https://github.com/openai/plugins) 获取。

- 在 Codex app 中，点击侧边栏的 Plugins。
- 你应该会在 Coding 分区看到 `Superpowers`。
- 点击 Superpowers 旁边的 `+`，然后按提示操作。

### Factory Droid

- 注册 marketplace：

  ```bash
  droid plugin marketplace add https://github.com/obra/superpowers
  ```

- 安装 plugin：

  ```bash
  droid plugin install superpowers@superpowers
  ```

### Gemini CLI

- 安装 extension：

  ```bash
  gemini extensions install https://github.com/obra/superpowers
  ```

- 后续更新：

  ```bash
  gemini extensions update superpowers
  ```

### OpenCode

OpenCode 使用自己的 plugin 安装方式；即使你已经在另一个 harness 中使用 Superpowers，也需要单独安装。

- 告诉 OpenCode：

  ```
  Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md
  ```

- 详细文档：[docs/README.opencode.md](docs/README.opencode.md)

### Cursor

- 在 Cursor Agent chat 中，从 marketplace 安装：

  ```text
  /add-plugin superpowers
  ```

- 或者在 plugin marketplace 搜索 "superpowers"。

### GitHub Copilot CLI

- 注册 marketplace：

  ```bash
  copilot plugin marketplace add obra/superpowers-marketplace
  ```

- 安装 plugin：

  ```bash
  copilot plugin install superpowers@superpowers-marketplace
  ```

## 基本工作流

1. **brainstorming** - 写代码前激活。通过提问细化粗略想法，探索替代方案，分段展示设计供验证，并保存 design document。

2. **using-git-worktrees** - 设计获批后激活。在新 branch 上创建隔离 workspace，运行项目 setup，验证干净的测试 baseline。

3. **writing-plans** - 设计获批后激活。把工作拆成 bite-sized tasks（每项 2-5 分钟）。每个 task 都包含精确文件路径、完整代码和验证步骤。

4. **subagent-driven-development** 或 **executing-plans** - 有计划后激活。为每个 task 分派 fresh subagent，并进行两阶段 review（先 spec compliance，再 code quality）；或者按批次执行并设置 human checkpoints。

5. **test-driven-development** - 实现期间激活。强制 RED-GREEN-REFACTOR：写失败测试，看它失败；写最小代码，看它通过；commit。删除先于测试写出的代码。

6. **requesting-code-review** - tasks 之间激活。按计划 review，按严重程度报告问题。Critical issues 会阻塞进展。

7. **finishing-a-development-branch** - tasks 完成后激活。验证测试，展示选项（merge/PR/keep/discard），清理 worktree。

**agent 在任何 task 前都会检查相关 skills。** 这是强制工作流，不是建议。

## 包含内容

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR 循环（包含 testing anti-patterns 参考）

**Debugging**
- **systematic-debugging** - 四阶段 root cause 流程（包含 root-cause-tracing、defense-in-depth、condition-based-waiting 技术）
- **verification-before-completion** - 确保问题真的修好了

**Collaboration**
- **brainstorming** - 苏格拉底式设计细化
- **writing-plans** - 详细实现计划
- **executing-plans** - 带 checkpoints 的批量执行
- **dispatching-parallel-agents** - 并发 subagent workflows
- **requesting-code-review** - pre-review checklist
- **receiving-code-review** - 回复反馈
- **using-git-worktrees** - 并行开发 branches
- **finishing-a-development-branch** - merge/PR 决策工作流
- **subagent-driven-development** - 通过两阶段 review（spec compliance，然后 code quality）快速迭代

**Meta**
- **writing-skills** - 按 best practices 创建新 skills（包含测试方法）
- **using-superpowers** - skills system 入门

## 哲学

- **Test-Driven Development** - 永远先写测试
- **Systematic over ad-hoc** - 用流程替代猜测
- **Complexity reduction** - 把简单作为首要目标
- **Evidence over claims** - 宣称成功前先验证

阅读[最初的 release announcement](https://blog.fsck.com/2025/10/09/superpowers/)。

## 贡献

Superpowers 的一般贡献流程如下。请注意，我们通常不接受新增 skills 的贡献，并且任何对 skills 的更新都必须能在我们支持的所有 coding agents 上工作。

1. Fork repository
2. 切换到 `dev` branch
3. 为你的工作创建一个 branch
4. 按 `writing-skills` skill 创建、测试新增或修改过的 skills
5. 提交 PR，并确保填完整 pull request template。

完整指南见 `skills/writing-skills/SKILL.md`。

## 更新

Superpowers 的更新方式在一定程度上取决于 coding agent，但通常是自动的。

## License

MIT License - 详情见 LICENSE file

## 社区

Superpowers 由 [Jesse Vincent](https://blog.fsck.com) 和 [Prime Radiant](https://primeradiant.com) 的其他伙伴构建。

- **Discord**：[Join us](https://discord.gg/35wsABTejz)，获取社区支持、提问，并分享你用 Superpowers 构建的东西
- **Issues**：https://github.com/obra/superpowers/issues
- **Release announcements**：[Sign up](https://primeradiant.com/superpowers/) 获取新版本通知
