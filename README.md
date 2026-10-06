# Superpowers

Superpowers 是一种适用于编码代理的完整软件开发方法，建立在一组可组合技能和一些确保您的代理使用它们的初始指令之上。

> [!IMPORTANT]
> **安装中文版（社区维护 fork）**
>
> 本仓库是 `obra/superpowers` 的中文 fork，不是上游官方发行，当前同步到上游 `8ca22db`。通过 Codex plugin marketplace 安装本 fork 后，runtime 会直接读取已中文化的 `skills/**/SKILL.md` 和 hooks：
>
> ```bash
> codex plugin marketplace add oldwinter/superpowers
> codex plugin add superpowers@superpowers
> ```
>
> 下方标为官方 marketplace 或指向 `obra/superpowers` 的入口属于上游发行，不代表安装的是本中文版。

- [工作方式](#工作方式)
- [商业服务](#商业服务)
- [安装](#安装)
  - [Claude Code](#claude-code)
  - [Antigravity](#antigravity)
  - [Codex App](#codex-app)
  - [Codex CLI](#codex-cli)
  - [Cursor](#cursor)
  - [Devin CLI](#devin-cli)
  - [Factory Droid](#factory-droid)
  - [Gemini CLI](#gemini-cli)
  - [GitHub Copilot CLI](#github-copilot-cli)
  - [Grok Build CLI](#grok-build-cli)
  - [Kimi Code](#kimi-code)
  - [OpenCode](#opencode)
  - [Pi](#pi)
  - [Qwen Code](#qwen-code)
  - [Hermes Agent](#hermes-agent)
  - [Muse](#muse)
- [基本工作流](#基本工作流)
- [出现问题时](#出现问题时)
- [社区](#社区)
- [包含内容](#包含内容)
- [理念](#philosophy)
- [贡献](#contributing)
- [更新](#updating)
- [许可证](#license)
- [Visual companion telemetry](#visual-companion-telemetry)

赋予你的 agent Superpowers：[Claude Code](#claude-code)、[Antigravity](#antigravity)、[Codex App](#codex-app)、[Codex CLI](#codex-cli)、[Cursor](#cursor)、[Devin CLI](#devin-cli)、[Factory Droid](#factory-droid)、[Gemini CLI](#gemini-cli)、[GitHub Copilot CLI](#github-copilot-cli)、[Grok Build CLI](#grok-build-cli)、[Kimi Code](#kimi-code)、[OpenCode](#opencode)、[Pi](#pi)、[Qwen Code](#qwen-code)、[Hermes Agent](#hermes-agent)、[Muse](#muse)。

## 工作方式

它从您启动编码代理的那一刻开始。一旦它发现您正在构建某些东西，它就不会立即尝试编写代码。相反，它会退后一步，问你真正想做什么。

一旦它从对话中挑出一个规范，它就会以足够短的块向您展示，以便您实际阅读和消化。

在您签署设计后，您的代理会制定一个实施计划，该计划对于一位品味差、缺乏判断力、没有项目背景且厌恶测试的热情初级工程师来说足够清晰。它强调真正的红色/green TDD、YAGNI（You Aren't Gonna Need It）和DRY。

接下来，一旦您说"开始"，它就会启动"子代理驱动开发"流程，让代理完成每个工程任务，检查和审查他们的工作，然后继续前进。对于您的代理来说，在不偏离您制定的计划的情况下一次自主工作几个小时的情况并不少见。

还有很多东西，但这是系统的核心。而且因为技能会自动触发，所以你不需要做任何特别的事情。你的编码agent拥有Superpowers。

## 商业服务

如果您在企业中使用 Superpowers，并且可以从商业支持、附加工具或管理支出中受益，请随时通过 sales@primeradiant.com 给我们发邮件。

## 安装

安装因线束而异。如果您使用多个，请为每一个单独安装 Superpowers。

### Claude Code

Superpowers可通过[official Claude plugin marketplace](https://claude.com/plugins/superpowers)获得

#### Official Marketplace

- 从 Anthropic 的官方市场安装插件：

  ```bash
  /plugin install superpowers@claude-plugins-official
  ```

#### Superpowers Marketplace

Superpowers 市场为 Claude Code 提供 Superpowers 和其他一些相关插件。

- 注册市场：

  ```bash
  /plugin marketplace add obra/superpowers-marketplace
  ```

- 从这个市场安装插件：

  ```bash
  /plugin install superpowers@superpowers-marketplace
  ```

### Antigravity

从这个存储库安装 Superpowers 作为插件：

```bash
agy plugin install https://github.com/obra/superpowers
```

Antigravity 运行插件的会话启动挂钩，因此 Superpowers 从
第一条消息。使用相同的更新命令重新安装。

### Codex App

Superpowers可通过[official Codex plugin marketplace](https://github.com/openai/plugins)获得。

- 在 Codex 应用程序中，单击侧栏中的插件。
- 您应该在编码部分看到 `Superpowers`。
- 单击"Superpowers"旁边的 `+` 并按照提示进行操作。

### Codex CLI

Superpowers可通过[official Codex plugin marketplace](https://github.com/openai/plugins)获得。

- 打开插件搜索界面：

  ```bash
  /plugins
  ```

- 寻找Superpowers：

  ```bash
  superpowers
  ```

- 选择`Install Plugin`。

### Cursor

- 在 Cursor Agent 聊天中，从市场安装：

  ```text
  /add-plugin superpowers
  ```

- 或者在插件市场中搜索"superpower"。

### Devin CLI

- Install the plugin from this repository:

  ```bash
  devin plugins install obra/superpowers
  ```

- Update to the latest version with:

  ```bash
  devin plugins update superpowers
  ```

### Factory Droid

- 注册市场：

  ```bash
  droid plugin marketplace add https://github.com/obra/superpowers
  ```

- 安装插件：

  ```bash
  droid plugin install superpowers@superpowers
  ```

### Gemini CLI

- 安装 extension：

  ```bash
  gemini extensions install https://github.com/oldwinter/superpowers
  ```

- 后续更新：

  ```bash
  gemini extensions update superpowers
  ```

### GitHub Copilot CLI

- 注册市场：

  ```bash
  copilot plugin marketplace add obra/superpowers-marketplace
  ```

- 安装插件：

  ```bash
  copilot plugin install superpowers@superpowers-marketplace
  ```

### Grok Build CLI

Superpowers is available via the [official Grok plugin marketplace](https://github.com/xai-org/plugin-marketplace).

- Install the plugin from xAI's official marketplace:

  ```bash
  grok plugin install superpowers@xai-official --trust
  ```

- Or open the marketplace in the TUI, search for Superpowers, and install it:

  ```text
  /marketplace
  ```

### Kimi Code

Superpowers 可在 Kimi Code 的插件市场中找到。

- 打开Kimi Code的插件管理器：

  ```text
  /plugins
  ```

- 转到 `Marketplace` > `Superpowers` 并安装它。

- 或者直接从此存储库安装：

  ```text
  /plugins install https://github.com/obra/superpowers
  ```

- 详细文档：[docs/README.kimi.md](docs/README.kimi.md)

### OpenCode

OpenCode 使用自己的插件安装；单独安装 Superpowers，即使您
已经在另一个harness中使用它。

- 告诉 OpenCode：

  ```
  Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md
  ```

- 详细文档：[docs/README.opencode.md](docs/README.opencode.md)

### Pi

从此存储库将 Superpowers 安装为 Pi 包：

```bash
pi install git:github.com/obra/superpowers
```

对于本地开发，运行 Pi 并将此签出作为临时包加载：

```bash
pi -e /path/to/superpowers
```

Pi 包加载 Superpowers 技能和一个小扩展，该扩展在会话启动时注入 `using-superpowers` 引导程序，并在压缩后再次注入。 Pi 具有原生技能，因此不需要兼容性 `Skill` 工具。子代理和任务列表工具仍然是可选的 Pi 配套软件包。

### Qwen Code

Qwen Code 可直接从 Claude Code marketplace 安装 plugins。

- 从本仓库安装 plugin，并在提示时选择 `superpowers`：

  ```bash
  qwen extensions install obra/superpowers
  ```

- 后续更新：

  ```bash
  qwen extensions update superpowers
  ```

### Hermes Agent

从此仓库将 Superpowers 安装为 Hermes plugin：

```bash
hermes plugins install obra/superpowers --enable
```

安装后重启已有 Hermes session。Hermes 没有 post-compaction hook；如果很长的 session 在第一轮之后 compact 丢失 bootstrap，skill 不再触发时请启动新 session。

### Muse

Superpowers 可作为原生 Muse plugin 使用：同一仓库、同一组 skills，支持所有 harness。与 Claude Code、Codex、Cursor、Gemini、Pi 等集成一样，原生 `SessionStart` hook 会注入 `using-superpowers` bootstrap，无需每个 session 手动启用。

- 从本地 checkout 安装：

  ```bash
  muse plugins install ./
  muse plugins approve superpowers
  ```

  或 clone 后安装：

  ```bash
  git clone https://github.com/obra/superpowers.git
  muse plugins install ./superpowers
  muse plugins approve superpowers
  ```

- 后续更新：

  ```bash
  muse plugins update superpowers
  ```

安装后重启所有活动中的 Muse session，让 `SessionStart` hook 生效。Skills 会立即启用，hooks 在首次安装时需要批准。验证时启动新 session 并发送 `Let's make a react todo list`；正常安装会在编写任何代码之前自动触发 `brainstorming`。版本记录在 `.version-bump.json` 中，由 `scripts/bump-version.sh` 保持同步。

## 基本工作流

1. **[`brainstorming`](skills/brainstorming/SKILL.md)**（头脑风暴） - 在编写代码之前激活。通过问题提炼粗略的想法，探索替代方案，分段展示设计以供验证。保存设计文档。

2. **[`using-git-worktrees`](skills/using-git-worktrees/SKILL.md)** - 设计批准后激活。在新分支上创建独立的工作区，运行项目设置，验证干净的测试基线。

3. **[`writing-plans`](skills/writing-plans/SKILL.md)**（写作计划） - 使用批准的设计激活。将工作分解为带可检查结果的小任务，明确文件、接口、测试和验证步骤，同时避免替实现者写完整程序。

4. **[`subagent-driven-development`](skills/subagent-driven-development/SKILL.md)**（子代理驱动开发）或 **[`executing-plans`](skills/executing-plans/SKILL.md)**（执行计划） - 按计划激活。可以为每个任务分派全新 subagent 并逐项审查（最全面），也可以在当前 session 内逐项实现、最后对整个分支做一次全新审查（成本最低）。

5. **[`test-driven-development`](skills/test-driven-development/SKILL.md)**（测试驱动开发） - 在实施期间激活。强制执行红绿重构：编写失败的测试，观察它失败，编写最少的代码，观察它通过，提交。删除测试之前编写的代码。

6. **[`requesting-code-review`](skills/requesting-code-review/SKILL.md)**（请求代码审查） - 在任务之间激活。根据计划进行审查，按严重程度报告问题。关键问题阻碍进展。

7. **[`finishing-a-development-branch`](skills/finishing-a-development-branch/SKILL.md)**（完成开发分支） - 任务完成时激活。验证测试，显示选项（合并/PR/keep/discard），清理工作树。

当 session 行为异常时，使用 **[`diagnosing-superpowers`](skills/diagnosing-superpowers/SKILL.md)**（诊断 Superpowers）读取 transcript，并以逐行证据说明发生了什么。

**代理在执行任何任务之前都会检查相关技能。** 强制性工作流程，而不是建议。

## 出现问题时

有时 session 会表现异常：skill 在不该触发时触发、该触发时没有响应，或者 agent 忽略计划、重复工作、消耗的 token 超出预期。让 coding agent “分析这个 session 中 superpowers 出了什么问题”，它会调用 **diagnosing-superpowers** skill。检查较早的 session 时请指定 ID：“分析 session `<id>` 中 superpowers 出了什么问题”。

该 skill 会读取 session transcript，用逐行证据报告发生了什么，并可按需生成经过脱敏的 bug report bundle。

## 社区

Superpowers 由 [Jesse Vincent](https://blog.fsck.com) 和 [Prime Radiant](https://primeradiant.com) 团队共同构建。

- **Discord**：[加入社区](https://discord.gg/35wsABTejz)，获取支持、提问并分享使用 Superpowers 构建的内容
- **Issues**：https://github.com/obra/superpowers/issues
- **发布公告**：[订阅](https://primeradiant.com/superpowers/)新版本通知

## 包含内容

### Skills Library

Skill 身份是目录名（slug）。译名只是说明，不是路径。点 slug 进入对应 `SKILL.md`。

| 分组 | 译名 | slug | 路径 |
| --- | --- | --- | --- |
| Testing | 测试驱动开发 | [`test-driven-development`](skills/test-driven-development/SKILL.md) | `skills/test-driven-development/` |
| Debugging | 系统调试 | [`systematic-debugging`](skills/systematic-debugging/SKILL.md) | `skills/systematic-debugging/` |
| Debugging | 完成前验证 | [`verification-before-completion`](skills/verification-before-completion/SKILL.md) | `skills/verification-before-completion/` |
| Debugging | 诊断 Superpowers | [`diagnosing-superpowers`](skills/diagnosing-superpowers/SKILL.md) | `skills/diagnosing-superpowers/` |
| Collaboration | 头脑风暴 | [`brainstorming`](skills/brainstorming/SKILL.md) | `skills/brainstorming/` |
| Collaboration | 写作计划 | [`writing-plans`](skills/writing-plans/SKILL.md) | `skills/writing-plans/` |
| Collaboration | 执行计划 | [`executing-plans`](skills/executing-plans/SKILL.md) | `skills/executing-plans/` |
| Collaboration | 派遣并行代理 | [`dispatching-parallel-agents`](skills/dispatching-parallel-agents/SKILL.md) | `skills/dispatching-parallel-agents/` |
| Collaboration | 请求代码审查 | [`requesting-code-review`](skills/requesting-code-review/SKILL.md) | `skills/requesting-code-review/` |
| Collaboration | 接收代码审查 | [`receiving-code-review`](skills/receiving-code-review/SKILL.md) | `skills/receiving-code-review/` |
| Collaboration | 使用 git worktrees | [`using-git-worktrees`](skills/using-git-worktrees/SKILL.md) | `skills/using-git-worktrees/` |
| Collaboration | 完成开发分支 | [`finishing-a-development-branch`](skills/finishing-a-development-branch/SKILL.md) | `skills/finishing-a-development-branch/` |
| Collaboration | 子代理驱动开发 | [`subagent-driven-development`](skills/subagent-driven-development/SKILL.md) | `skills/subagent-driven-development/` |
| Meta | 写作技能 | [`writing-skills`](skills/writing-skills/SKILL.md) | `skills/writing-skills/` |
| Meta | 使用 Superpowers | [`using-superpowers`](skills/using-superpowers/SKILL.md) | `skills/using-superpowers/` |

### 文档地图

`docs/superpowers/` 不是子项目。下面两套 `plans/` 都是历史设计稿，不是当前行为真源：

- [`docs/plans/`](docs/plans/) — 2025 年起的设计稿
- [`docs/superpowers/plans/`](docs/superpowers/plans/) — 2026 年设计稿；对应规格在 [`docs/superpowers/specs/`](docs/superpowers/specs/)

## Philosophy

- **测试驱动开发** - 始终首先编写测试
- **系统性优于临时性** - 流程优于猜测
- **降低复杂性** - 简单性作为主要目标
- **索赔证据** - 在宣布成功之前进行验证

阅读[the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/)。

## Contributing

Superpowers 的一般贡献流程如下。请记住，我们通常不接受新技能的贡献，并且任何技能更新都必须适用于我们支持的所有编码代理。

1. 分叉存储库
2. 切换到"dev"分支
3. 为您的工作创建一个分支
4. 遵循`writing-skills`技能来创建和测试新的和修改的技能
5. 提交 PR，确保填写拉取请求模板。

技能行为测试使用来自[superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/)的演练评估工具，克隆到`evals/` - 请参阅`evals/README.md`进行设置。插件基础设施测试位于 `tests/` 并通过相关的 `run-*.sh` 或 `npm test` 运行。

完整指南请参阅`skills/writing-skills/SKILL.md`。

## Updating

Superpowers更新在某种程度上依赖于编码代理，但通常是自动的。

## License

MIT 许可证 - 有关详细信息，请参阅许可证文件

## Visual companion telemetry

由于技能和插件不会向创作者提供任何反馈，因此我们不知道有多少人正在使用Superpowers。默认情况下，头脑风暴的可选视觉伴随功能上的 Prime Radiant 徽标是从我们的网站加载的。它包括正在使用的 Superpowers 版本。它不包含有关您的项目、提示或编码代理的任何详细信息。我们看不到您的点击次数或任何有关您正在构建的内容的信息。这有助于我们大致了解有多少人正在使用 Superpowers 以及他们正在使用哪个版本的 Superpowers。它是 100% 可选的。要禁用此功能，请将环境变量 `SUPERPOWERS_DISABLE_TELEMETRY` 设置为任何真实值。 Superpowers 还尊重克劳德·科德 (Claude Code) 的`DISABLE_TELEMETRY` 和 `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` 选择退出。

## Community

Superpowers 是由 [Jesse Vincent](https://blog.fsck.com) 和 [Prime Radiant](https://primeradiant.com) 的其他人员创建的。

- **Discord**：[Join us](https://discord.gg/35wsABTejz) 用于社区支持、提问以及分享您与 Superpowers 一起构建的内容
- **Issues**: https://github.com/obra/superpowers/issues
- **发布公告**：[Sign up](https://primeradiant.com/superpowers/) 获取有关新版本的通知
