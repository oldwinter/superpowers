# Superpowers Release Notes

## v6.0.3 (2026-06-18)

### Subagent-Driven Development

- **SDD scratch files 已移出 `.git/`。** Claude Code 会把 `.git/` 视为 protected path，并拒绝 agent 写入；因此 implementer subagent 把报告写到 `.git/sdd/` 时会在运行中途被阻塞。Task briefs、implementer reports、review diffs 和 progress ledger 现在位于 working tree 中自我 ignore 的 `.superpowers/sdd/` 目录，既不会出现在 `git status`，也不会进入 commits，并由共享的 `sdd-workspace` helper 按 worktree 解析。有一个 caveat：因为这个 workspace 是 git-ignored working-tree scratch，`git clean -fdx` 会删除 progress ledger；如果发生这种情况，请从 `git log` 恢复。（#1780）

## v6.0.2 (2026-06-16)

### Install Fixes

- **我们不再提供 `evals` 子模块。** 它破坏了某些用户的插件安装，因此评估工具现在位于其自己的存储库中，与已发布的插件分开。 （＃1778，＃1774）

## v6.0.1 (2026-06-16)

### Codex Fixes

- **头脑风暴同伴中的版本显示** — 打包的 Codex 插件没有根 `package.json`，因此视觉同伴将其版本报告为"未知"。当 `package.json` 不存在时，`readSuperpowersVersion()` 现在会回退到 `.codex-plugin/plugin.json`。
- **更干净的 Codex 插件同步** — 同步到 Codex 脚本现在排除 `.gitmodules` 和 `.pre-commit-config.yaml`，将存储库元数据排除在打包的 Codex 插件之外。

## v6.0.0 (2026-06-16)

Superpowers 6.0 是一个重大版本。重点是重写了 `subagent-driven-development` 审查每项任务的方式——更便宜、更严格、更难玩弄。

虽然这些数字并不适用于每个工具和每个工作负载，但在我们的评估中，Claude Code 和 Codex 产生类似的高质量结果的速度大约是前者的两倍，而花费的代币却少了近 50%。

它还添加了三个新的工具（Kimi Code、Pi 和 Antigravity），为集思广益的视觉伴侣提供了更好的安全模型，并重写了许多技能的工具调用，使其更加与供应商中立。

### 可见变化

- **每个任务审阅者的两个提示变成了一个。** `spec-reviewer-prompt.md` 和 `code-quality-reviewer-prompt.md` 消失了，取而代之的是单个 `task-reviewer-prompt.md`。如果直接发送旧文件，请切换到新文件。
- **旧的全局工作树目录已消失。** `using-git-worktrees` 和 `finishing-a-development-branch` 不再使用 `~/.config/superpowers/worktrees/`。工作树现在登陆项目 - 现有的 `.worktrees/` 或 `worktrees/`（如果有），否则是新的 `.worktrees/` - 除非您另有说明。

### 新 Harness 支持

超级大国现在需要另外三个安全带运行。每个都有自己的引导程序、工具映射参考和测试，并且每个在自述文件中都有自己的安装部分。

- **Kimi Code** — 插件清单、安装文档和清单测试；从 Kimi 的市场安装或直接从存储库安装。 （@qer 的初始清单）
- **Pi** — 一个会话启动扩展，用于注册技能并注入 `using-superpowers` 引导程序。 Pi 具有本机技能，因此不需要兼容性垫片。
- **Antigravity (`agy`)** — 直接安装插件并从第一条消息引导；根据标准"制作反应待办事项列表"验收测试进行端到端验证。

### Subagent-Driven Development

对实际项目进行的长期成本和质量实验重塑了控制器审查每项任务的方式。旧流程为每个任务运行两名评审员，并依靠控制器对模型选择和严重性的判断，结果证明两者都很昂贵且易于玩弄。新流程为每个任务运行一名审阅者，将工作作为文件而不是粘贴文本进行处理，并从控制器中获取多个判断调用。

- **每个任务一个审阅者，两个结论。** 单个 `task-reviewer-prompt.md` 读取任务的 diff 一次，并返回规范合规性结论和质量结论，因此一次修复通过即可清除两者。新的"无法从差异中验证"判决标记了未触及代码中的要求，以便控制器进行自我检查。 （＃1538，＃1543）
- **最后进行一次广泛的审查。** 运行结束时会对最有能力的模型进行一次全分支审查，而不是逐个任务地重新审查所有内容。
- **计划在飞行前进行阅读。**在执行第一项任务之前，控制人员会检查计划是否存在内部冲突，以及计划要求的任何审核者会标记为缺陷的内容，并立即提出所有问题，而不是在运行中途陷入困境。
- **差异和任务文本作为文件移动。**粘贴的差异将自身永久地放置在最昂贵的上下文中，并且没有人的审阅者手动重建它 - 这是最大的审阅者成本。两个新脚本 `task-brief` 和 `review-package` 将任务文本和审查差异写入文件以供子代理读取。
- **每一次调度都会说明其模型。** 剩下的选择，控制者根本不再命名模型 - 并且一个未命名的模型悄悄地继承了会话中最昂贵的模型，因此一次运行将其所有 26 个审阅者置于顶层。现在，模板需要一个模型，并提供指导，以便在工作允许时达到更便宜的等级。
- **控制者无法告诉审阅者要忽略什么。** 实际运行发现控制者指导审阅者跳过某个发现或将其称为"至多较小"，然后将缺陷发送出去。现在完全禁止抑制调查结果和预先评估严重性，并且计划本身要求的缺陷会被报告给您来决定，而不是挥手而过。
- **审阅者是只读的并且对基本原理持怀疑态度。**审阅不再触及工作树或分支 - 运行 `git checkout` 的审阅者已经孤立了后来的提交 - 并且实现者的"我故意留下了这个未抽象的"不再让审阅者放弃真正的发现。
- **更有力的证据和报告。** 审阅者用文件和行支持每个答案，实施者的报告移动到文件并在应用 TDD 时携带红色 /green 证据，进度分类帐允许失去上下文的控制器恢复而不是重做已完成的工作。 (#994)

### Writing Plans

计划现在带有控制者和审核者用于在每次调度时重新推导的结构。

- **全局约束块**列出了绑定每个任务的规则 - 版本底线、依赖关系限制、命名和复制、精确值 - 逐字复制，以便它们实际上到达下游的实施者和审核者。
- **每个任务的接口块**准确地命名每个任务消耗和产生的内容，因此仅看到自己任务的实现者仍然知道其邻居的合同。
- **正确的规模指导**将任务保持在能够获得自己的测试周期和审阅者通过的规模，将设置、配置和文档折叠到需要它们的任务中。在测试中，以这种方式编写的计划需要一轮修复，而控件需要两到四次修复，并且控件带来了真正的错误。

### Brainstorming Visual Companion

视觉伴侣是代理在对话旁边打开的一个小型网络服务器。它根本没有身份验证，因此在共享或远程计算机上，任何可以到达端口的人都可以读取您的头脑风暴 - 或注入代理将其视为您的输入的事件。此版本为其提供了真正的安全模型，并使其能够在重新启动和断开连接的情况下生存。

- **每会话密钥现在可以保护一切。** 代理的 URL 带有一次性密钥，浏览器将其放入选项卡范围的 cookie 中，每个请求和 WebSocket 连接都必须提供它。这为杂散的本地选项卡和可路由的远程主机等关闭了大门，包括原始允许列表无法捕获的 DNS 重新绑定情况。 （关闭#1014）
- **文件服务器保留在其沙箱中。**它拒绝符号链接、点文件和任何爬出内容目录的路径，忽略 macOS 资源分支文件，并发送通常的无存储和拒绝帧标头。保存会话密钥的文件仅由所有者写入。
- **只有在有帮助的时候才提供同伴。**当问题第一次读起来比讲述的更好时，技能就会提出它，作为它自己的信息，并让拒绝保持不变。接受后，您的浏览器将打开至第一个屏幕。 （关闭#755）
- **它可以在重新启动和不稳定的连接中幸存下来。**给定一个项目目录，服务器在重新启动时保留相同的端口和密钥，因此打开的选项卡只需重新连接即可。该页面会自行重新连接，显示实时状态药丸，并在服务器关闭时引发"暂停"覆盖。
- **更长的空闲寿命，更安全的关闭。** 空闲超时从 30 分钟变为 4 小时，并且 `stop-server.sh` 现在在发出信号之前确认它拥有正确的进程，因此它在重新启动后永远不会杀死不相关的 `node`。 (#1703)
- **Windows 启动强化** - 合并 shell 检测，Windows 现在依赖空闲超时来关闭，因为 Node 无法跟踪 MSYS2 中的 POSIX 进程所有权。


### 现有 Harness 更新

- **Codex** 现在通过自己的 SessionStart 挂钩而不是共享线路进行引导，并且 Codex 应用程序获得了安装部分和更完整的工具文档（网络搜索、`AGENTS.md`、个人技能）。 (#1540)
- **OpenCode** 在其插件、安装文档和自述文件中提供了基于操作的工具映射，以及引导缓存测试。
- **光标**的清单删除了其 `agents` 和 `commands` 条目，因为这些目录不再存在。

### 一套技能，每种驾驭方式

用于讲克劳德·科德方言的技能——"使用任务工具"，"将其放入CLAUDE.md"。此版本根据您实际执行的操作重写了该词汇表（"调度子代理"、"您的指令文件"），并添加了每个线束参考，将每个操作映射到正确的工具，并根据每个运行时进行检查。名为"克劳德"的散文现在说"你的代理人"。

- **每个安全带的工具参考**位于 `skills/using-superpowers/references/`，涵盖 Claude Code、Codex、Copilot、Gemini、Pi 和 Antigravity。
- **`finishing-a-development-branch` 变得与伪造无关** - 它不再硬编码 `gh pr create`，因此特工可以使用他们拥有的任何伪造工具进行推送。 （#1609）
- **一次重命名：**"克劳德搜索优化"现在是"技能发现优化"，因为该技术不是克劳德特定的。

### Writing Skills

为技能作者添加了两项内容。

- **将表格与失败相匹配** - 用于选择正确类型指导的简短表格。平淡的"不做 X"对于纪律失误很有用，但当问题是输出的"形状"时，会适得其反，而工作示例会做得更好。该表格以及现有合理化部分的更严格范围，引导作者采用真正有帮助的形式。
- **微观测试措辞**——一种在提交之前检查措辞的廉价方法：在无指导的控制下对其进行几次采样，并手动读取每个结果，将运行间差异视为警告信号。

### Testing

技能行为测试从 `tests/` 转移到一个基于"drill"构建的新的 `evals/` 子模块，该子模块运行真实的 Claude Code、Codex 和 Gemini 会话，并用 LLM 对其进行评判。一些树内攻击套件在更严格的演习场景覆盖后就退役了；少数没有同等水平的人留下来了。从这里开始，`tests/` 进行插件代码测试，`evals/` 进行技能行为测试，`docs/testing.md` 解释拆分。新的后端支持 Antigravity、Pi 和更多模型，新的 shell-lint 和预提交检查可以保护安全带。 (#1541)

### Bug Fixes

- **系统调试不再迫使每个会话都进行扩展思考。** 一颗子弹包含克劳德·代码扫描的确切关键字，悄悄地触发加载技能的每个会话上的开关。连字符打破关键字；文字仍然显示。 （＃1283，@Nick Galatis）
- **Windows SessionStart 挂钩停止在每个会话中打印写入错误** — 每个 `printf` 现在通过 `cat` 路由以吸收损坏的管道，并且输出在其他方面保持不变。 （#1612，由@silvertakana 报道）
- **Windows 前台模式** 跟踪正确的进程并清除 MSYS2 上其所有者 PID。 （作者：@nestorluiscamachopaz）
- **`using-superpowers` 引导程序**不再将"调试"列为不存在的技能。 （@mhat 报道）
- **TDD 技能**链接测试反模式参考。 （#1532、#1529；链接修复#1474，作者：@Stable Genius）
- **`using-git-worktrees`** 修复其步骤编号并删除过时的游标引用。 （#1522，作者：@fuleinist）
- **法典审查技巧**将私人笑话替换为简单的指导。 (#1531)

### 文档和贡献者指南

- **将 Superpowers 移植到新工具的指南** (`docs/porting-to-a-new-harness.md`) 列出了每个集成所需的三个部分以及成功或失败的一个规则：在会话开始时加载引导程序。
- **现在每个 PR 和问题都会披露它是如何制作的** - 模型、工具、版本和安装的插件，或者是手写的注释。我们根据贡献的产生因素来不同地衡量贡献。 PR 还针对 `dev`，而不是 `main`。 PR 模板、所有三个问题模板以及新的平台支持模板都包含此内容。

### 贡献者

感谢@mattvanhorn、@nawfal、@Nick Galatis、@silvertakana、@nestorluiscamachopaz、@qer、@mhat、@Stable Genius、@fuleinist、@dev_Hakaze、@robotsnh、Rahul 和 @arittr。

## v5.1.0 (2026-04-30)

### Removals

- **旧版斜杠命令已删除** — `/brainstorm`、`/execute-plan` 和 `/write-plan` 已消失。它们是已弃用的存根，除了告诉用户调用相应的技能之外什么也不做。而是直接调用 `superpowers:brainstorming`、`superpowers:executing-plans` 和 `superpowers:writing-plans`。 (#1188)
- **`superpowers:code-reviewer` 命名代理已删除** — 该代理是插件唯一的命名代理，并且仅由两个技能使用，而存储库中的每个其他审阅者/implementer 子代理都会调度 `general-purpose` 以及其技能旁边的提示模板。代理的角色和清单已合并到`skills/requesting-code-review/code-reviewer.md`中作为独立的任务调度模板。任何调度 `Task (superpowers:code-reviewer)` 的人都应该使用提示模板切换到 `Task (general-purpose)`。 （公关#1299）
- **从技能中删除了集成部分** - 这些是代理拥有本地技能系统之前的遗留问题，并且对指导没有帮助。

### Worktree Skills Rewrite

`using-git-worktrees` 和 `finishing-a-development-branch` 现在检测代理何时已在隔离工作树内运行，并在回退到 `git worktree` 之前更喜欢线束的本机工作树控件。行为经过了 TDD 验证，并跨五个安全带进行了跨平台检查。 （PRI-974，PR #1121）

- **环境检测** - 两种技能在做任何事情之前都会检查`GIT_DIR != GIT_COMMON`；如果已经在链接的工作树中，则完全跳过创建。子模块防护可防止错误检测。
- **创建工作树之前同意** — `using-git-worktrees` 不再隐式创建工作树；该技能首先询问用户。修复#991（子代理驱动开发未经同意自动创建工作树）。
- **本机工具首选项（步骤 1a）** - 当工具暴露其自己的工作树工具（例如 Codex）时，技能将遵循它。用户表达的偏好将得到尊重。
- **基于来源的清理** — `finishing-a-development-branch` 仅清理 `.worktrees/` 内的工作树（由超级能力创建）；外面的任何东西都被留下。修复了 #940（选项 2 错误地清理了工作树）、#999（合并然后删除排序）和 #238（`cd` 在 `git worktree remove` 之前存储到仓库根目录）。
- **分离 HEAD 处理** — 当没有要合并的分支时，整理菜单会折叠为两个选项。
- **技能示例中的硬编码 `/Users/jesse` 路径**替换为通用占位符。 （#858，公关#1122）

### AI Agent 贡献者指南

`CLAUDE.md` 顶部的两个新部分（符号链接到 `AGENTS.md`）直接与 AI 代理对话。针对该存储库对最近 100 个已关闭 PR 的审计显示，由 AI 生成的错误导致的拒绝率为 94%：代理没有阅读 PR 模板、打开重复项、编造问题描述或将分叉或特定领域的更改推送到上游。

- **提交前清单** — 阅读 PR 模板，搜索现有 PR，验证是否存在实际问题，确认更改属于核心，并在提交之前向人类合作伙伴展示完整的差异。
- **我们不会接受的** — 第三方依赖项、技能内容的"合规性"重写、特定于项目的配置、批量 PR、推测性修复、特定于领域的技能、特定于分叉的更改、捏造的内容以及捆绑的不相关更改。
- **新的线束 PR 需要会话记录** - 大多数过去的新线束集成都会复制技能文件或用 `npx skills` 包装，而不是在会话开始时加载 `using-superpowers` 引导程序。现在需要验收测试（"让我们制作一个反应待办事项列表"必须在干净的会话中自动触发`brainstorming`）和完整的成绩单。

### Codex Plugin Mirror 工具

新的 `sync-to-codex-plugin` 脚本将超能力镜像到 OpenAI Codex 插件市场中，作为 `prime-radiant-inc/openai-codex-plugins`。路径/user-agnostic，以便任何团队成员都可以运行它。 （公关＃1165）

- 每次运行时将新的 fork 克隆到临时目录中，重新生成内联覆盖，并打开 PR；自动检测脚本自身位置的上游并预检 `rsync`/`git`/`gh auth`/`python3`。
- `--bootstrap` 首次设置标志； `EXCLUDES` 模式锚定到源根； `assets/` 排除在外。
- 镜子`CODE_OF_CONDUCT.md`；删除`agents/openai.yaml` 覆盖层。
- 镜像 `plugin.json` 中的种子 `interface.defaultPrompt`。 （@arittr 的 PR #1180）
- Codex 插件文件已提交到源存储库，因此同步脚本使用规范版本； Codex 市场元数据被保留。

### OpenCode

- **在模块级别缓存的引导内容** — `getBootstrapContent()` 在每个代理步骤上调用 `fs.existsSync` + `fs.readFileSync` + frontmatter 正则表达式（`experimental.chat.messages.transform` 钩子在 OpenCode 代理循环中的每个步骤上触发）。现在读取一次，在会话生命周期内缓存，并针对丢失文件的情况使用空标记。 15 项回归测试涵盖缓存行为、fs 调用计数、注入防护、丢失文件哨兵和缓存重置。 （修复#1202）
- **集成测试现代化**。
- **安装自述文件中澄清的注意事项**。

### Code Review Consolidation

`requesting-code-review` 现在是独立的：角色、清单和调度模板位于 `skills/requesting-code-review/code-reviewer.md` 中，技能直接调度 `Task (general-purpose)`。 （公关#1299）

- **单一事实来源** — 之前同时存在于 `agents/code-reviewer.md` 和技能占位符模板（并且独立漂移）中的角色 /checklist 现在是一个文件。
- **`subagent-driven-development` 紧随其后** — 它的 `code-quality-reviewer-prompt.md` 现在调度 `Task (general-purpose)` 而不是指定的代理。
- **添加了行为测试** - `tests/claude-code/test-requesting-code-review.sh` 将真正的错误（SQL 注入、明文密码处理、凭证日志记录）植入到一个小项目中，并断言派遣的审阅者将每个植入的问题标记为"严重"/Important 严重性，并拒绝批准差异。

> 注意：`tests/claude-code/test-requesting-code-review.sh` 和 `tests/claude-code/test-document-review-system.sh`（本文档后面提到）已于 2026 年 5 月 6 日提升至演练场景，并从 `tests/` 中删除。参见`evals/scenarios/code-review-catches-planted-bugs.yaml`和`evals/scenarios/spec-reviewer-catches-planted-flaws.yaml`。上面和下面的参考文献被保留为本节描述的工作的过时工件。
- **Codex 和 Copilot 解决方法文档已修剪** — `references/codex-tools.md` 和 `references/copilot-tools.md` 中的"指定代理调度"部分记录了如何将指定代理扁平化为通用调度。由于没有指定代理发货，因此没有必要采取解决方法；两个部分都被删除了。

### Subagent-Driven Development

- **不再每 3 个任务暂停** — `requesting-code-review` 中的"每批（3 个任务）后进行审核"节奏（最初用于 `executing-plans`）已泄漏到 `subagent-driven-development` 中。替换为"每个任务或在自然检查点"加上显式的连续执行指令。
- **SDD 集成测试现在运行其断言** - 三个独立的错误导致测试在打印任何验证结果之前静默退出：工作目录路径中未解析的 `..` 段、与 `find | sort | head -1` 的 `set -euo pipefail` 交互（生产者上的 SIGPIPE 杀死了脚本），以及 `claude -p` 调用上缺少 `--plugin-dir` 导致测试加载已安装的插件而不是工作树。三者均已固定；现在，六个验证测试实际上是针对真正的端到端 SDD 运行运行的。

### Cursor

- **Windows SessionStart 挂钩** 通过 `run-hook.cmd` 路由，而不是直接调用无扩展的 `session-start` 脚本。修复了 Windows 在编辑器中打开文件而不是运行文件的问题。还从 `hooks-cursor.json` 中删除了意外的 UTF-8 BOM。

### Gemini CLI

- **子代理调度映射** — Gemini 的 `Task` 调度现在映射到 `@agent-name` / `@generalist`，并为独立任务记录了并行子代理调度。

### Skills

- **跨技能内容的术语清理**。

### 文档和安装

- **Factory Droid 安装说明** 添加到自述文件中。
- **自述文件中的快速入门安装链接**。 （@arittr 的 PR #1293）
- **Codex 插件安装指南**已更新。 （@arittr 的 PR #1288）
- **法典 `wait` 映射已更正**至工具参考中的 `wait_agent`。
- **重新组织安装顺序**； Codex 安装说明已清理。
- **删除了残留的`CHANGELOG.md`>**，转而将`RELEASE-NOTES.md`作为单一来源。 （PR #1163，作者：@shaanmajid）
- **不和谐邀请链接**已修复；发布公告链接和社区部分添加了详细的 Discord 描述。

### Community

- @shaanmajid — 残留的 `CHANGELOG.md` 移除（PR #1163）
- @arittr — 自述文件快速入门安装链接 (#1293)、Codex 插件安装指南 (#1288)、`sync-to-codex-plugin` `interface.defaultPrompt` 种子 (#1180)

## v5.0.7 (2026-03-31)

### GitHub Copilot CLI Support

- **SessionStart 上下文注入** — Copilot CLI v1.0.11 在 sessionStart 挂钩输出中添加了对 `additionalContext` 的支持。会话启动挂钩现在可以检测 `COPILOT_CLI` 环境变量并发出 SDK 标准 `{ "additionalContext": "..." }` 格式，从而在会话启动时为 Copilot CLI 用户提供完整的超能力引导。 （@culinablaz 在 PR #910 中的原始修复）
- **工具映射** — 添加了 `references/copilot-tools.md` 以及完整的 Claude Code 到 Copilot CLI 工具等效表
- **技能和自述文件更新** — 将 Copilot CLI 添加到 `using-superpowers` 技能的平台说明和自述文件安装部分

### OpenCode Fixes

- **技能路径一致性** — 引导文本不再宣传与运行时路径不匹配的误导性 `configDir/skills/superpowers/` 路径。代理应使用本机 `skill` 工具，而不是通过路径导航到文件。测试现在使用源自单一事实来源的一致路径。 （＃847，＃916）
- **引导程序作为用户消息** — 将引导程序注入从 `experimental.chat.system.transform` 移动到 `experimental.chat.messages.transform`，添加到第一条用户消息前面，而不是添加系统消息。避免每次重复的系统消息导致令牌膨胀 (#750)，并修复了与 Qwen 和其他在多个系统消息上中断的模型的兼容性 (#894)。

## v5.0.6 (2026-03-24)

### Inline Self-Review Replaces Subagent Review Loops

子代理审核循环（派遣新代理来审核计划/specs）使执行时间增加了一倍（约 25 分钟开销），但没有显着提高计划质量。跨 5 个版本的回归测试和 5 次试验均显示相同的质量分数，无论审查循环是否运行。

- **头脑风暴** — 用内嵌规范自我审查清单替换规范审查循环（子代理调度 + 3 次迭代上限）：占位符扫描、内部一致性、范围检查、歧义性检查
- **编写计划** — 用内联自我审查清单替换了计划审查循环（子代理调度 + 3 次迭代上限）：规范覆盖率、占位符扫描、类型一致性
- **编写计划** - 添加了明确的"无占位符"部分来定义计划失败（待定，模糊描述，未定义的引用，"类似于任务 N"）
- 自我审查每次运行可在约 30 秒（而不是约 25 分钟）内捕获 3-5 个真正的错误，其缺陷率与子代理方法相当

### Brainstorm Server

- **Session directory restructured** — the brainstorm server session directory now contains two peer subdirectories: `content/` (HTML files served to the browser) and `state/` (events, server-info, pid, log). Previously, server state and user interaction data were stored alongside served content, making them accessible over HTTP. The `screen_dir` and `state_dir` paths are both included in the server-started JSON. (Reported by 吉田仁)

### Bug Fixes

- **所有者 PID 生命周期修复** — 头脑风暴服务器的所有者 PID 监控有两个错误，导致 60 秒内错误关闭：(1) 来自跨用户 PID（Tailscale SSH 等）的 EPERM 被视为"进程死亡"，以及 (2) 在 WSL 上，祖父 PID 解析为在第一次生命周期检查之前退出的短期子进程。通过将 EPERM 视为"活动"并在启动时验证所有者 PID 来修复 - 如果它已经死亡，则禁用监控并且服务器依赖 30 分钟的空闲超时。这还删除了 Windows/MSYS2-specific 从 `start-server.sh` 中剥离出来的内容，因为服务器现在可以通用地处理它。 （#879）
- **写作技巧** — 更正了 SKILL.md frontmatter 支持"仅两个字段"的错误说法；现在显示"两个必填字段"，并链接到所有支持字段的agentskills.io 规范（PR #882 by @arittr）

### Codex App Compatibility

- **codex-tools** — 添加了命名代理调度映射，记录了如何使用辅助角色将 Claude Code 的命名代理类型转换为 Codex 的 `spawn_agent`（PR #647 by @arittr）
- **codex-tools** — 添加了环境检测和 Codex App 整理部分，以实现工作树感知技能（由 @arittr 提供）
- **设计规范** - 添加了 Codex App 兼容性设计规范 (PRI-823)，涵盖只读环境检测、工作树安全技能行为和沙箱回退模式（由 @arittr 提供）

## v5.0.5 (2026-03-17)

### Bug Fixes

- **头脑风暴服务器 ESM 修复** — 重命名为 `server.js` → `server.cjs`，以便头脑风暴服务器在 Node.js 22+ 上正确启动，其中根 `package.json` `"type": "module"` 导致 `require()` 失败。 （@sarbojitrana 的 PR #784，修复了 #774、#780、#783）
- **在 Windows 上集体讨论所有者 PID** — 跳过 Windows/MSYS2 上的 PID 生命周期监控，其中 PID 命名空间对 Node.js 不可见，从而防止服务器在 60 秒后自行终止。 （#770，来自 @lucasyhzlu-debug 的 PR #768 的文档）
- **stop-server.sh 可靠性** — 在报告成功之前验证服务器进程实际上已死亡。 SIGTERM + 2 秒等待 + SIGKILL 回退。 (#723)

### Changed

- **执行切换** - 在计划编写后恢复用户在子代理驱动和内联执行之间的选择。建议使用子代理驱动，但不再强制。

## v5.0.4 (2026-03-16)

### Review Loop Refinements

通过消除不必要的审核并加强审核者的关注，显着减少令牌使用并加快规范和计划审核速度。

- **单个整体计划审查** - 计划审查者现在一次性审查完整的计划，而不是逐块审查。删除了所有与块相关的概念（`## Chunk N:` 标题、1000 行块限制、每个块调度）。
- **提高了阻止问题的标准** - 规范和计划审阅者提示现在都包含"校准"部分：仅标记在实施过程中会导致实际问题的问题。次要的措辞、风格偏好和格式问题不应阻碍批准。
- **减少最大审核迭代次数** — 规范和计划审核循环从 5 次减少到 3 次。如果审稿人校准正确，3 轮就足够了。
- **简化的审阅者清单** - 规范审阅者从 7 个类别减少到 5 个；计划审阅者从 7 人减少到 4 人。删除了以格式为中心的检查（任务语法、块大小），转而关注实质内容（可构建性、规范对齐）。

### OpenCode

- **一行插件安装** — OpenCode 插件现在通过 `config` 挂钩自动注册技能目录。不需要符号链接或 `skills.paths` 配置。安装只是在 `opencode.json` 中添加一行。 （公关#753）
- **添加了 `package.json`** 以便 OpenCode 可以从 git 将超能力安装为 npm 包。

### Bug Fixes

- **验证服务器实际上已停止** — `stop-server.sh` 现在在报告成功之前确认进程已终止。 SIGTERM + 2 秒等待 + SIGKILL 回退。如果进程存活则报告失败。 （公关＃751）
- **通用代理语言** - 头脑风暴同伴等待页面现在显示"代理"而不是"克劳德"。

## v5.0.3 (2026-03-15)

### Cursor Support

- **光标挂钩** — 使用光标的驼峰格式添加了 `hooks/hooks-cursor.json`（`sessionStart`、`version: 1`）并更新了 `.cursor-plugin/plugin.json` 以引用它。修复了`session-start`中的平台检测以首先检查`CURSOR_PLUGIN_ROOT`（光标也可以设置`CLAUDE_PLUGIN_ROOT`）。 （基于 PR #709）

### Bug Fixes

- **停止在 `--resume`** 上触发 SessionStart 钩子 - 启动钩子在恢复的会话上重新注入上下文，这些会话的对话历史记录中已经有了上下文。该钩子现在仅在 `startup`、`clear` 和 `compact` 上触发。
- **Bash 5.3+ 挂钩挂起** — 将 `hooks/session-start` 中的heredoc (`cat <<EOF`) 替换为`printf`。修复了 macOS 上使用 Homebrew bash 5.3+ 时由于 bash 回归和此处文档中的大变量扩展导致的无限期挂起。 （＃572，＃571）
- **POSIX 安全挂钩脚本** — 在 `hooks/session-start` 中将 `${BASH_SOURCE[0]:-$0}` 替换为 `$0`。修复了 Ubuntu/Debian 上的"错误替换"错误，其中 `/bin/sh` 是破折号。 (#553)
- **Portable shebangs** — 在所有 shell 脚本中将 `#!/bin/bash` 替换为 `#!/usr/bin/env bash`。修复了 NixOS、FreeBSD 和 macOS 上使用 Homebrew bash 的执行，其中 `/bin/bash` 已过时或丢失。 (#700)
- **Windows 上的头脑风暴服务器** — 自动检测 Windows/Git Bash（`OSTYPE=msys*`、`MSYSTEM`）并切换到前台模式，修复由 `nohup`/`disown` 进程收割导致的静默服务器故障。 (#737)
- **Codex 文档修复** — 在 Codex 文档中用 `multi_agent` 替换已弃用的 `collab` 标志。 （公关＃749）

## v5.0.2 (2026-03-11)

### Zero-Dependency Brainstorm Server

**删除了所有供应的node_modules - server.js现在完全独立**

- 使用内置 `http`、`fs` 和 `crypto` 模块将 Express/Chokidar/WebSocket 依赖项替换为零依赖项 Node.js 服务器
- 删除了约 1,200 行已售出的 `node_modules/`、`package.json` 和 `package-lock.json`
- 自定义 WebSocket 协议实现（RFC 6455 框架、ping/pong、正确的关闭握手）
- 原生 `fs.watch()` 文件监视取代了 Chokidar
- 完整的测试套件：HTTP 服务、WebSocket 协议、文件监视和集成测试

### Brainstorm Server Reliability

- **闲置 30 分钟后自动退出** — 服务器在没有客户端连接时关闭，防止孤立进程
- **所有者进程跟踪** — 服务器监视父线束 PID，并在所属会话终止时退出
- **活性检查** - 技能在重用现有实例之前验证服务器是否响应
- **编码修复** - 在所提供的 HTML 页面上正确的 `<meta charset="utf-8">`

### Subagent Context Isolation

- 所有委托技能（头脑风暴、调度并行代理、请求代码审查、子代理驱动开发、编写计划）现在都包含上下文隔离原则
- 子代理只接收它们需要的上下文，防止上下文窗口污染

## v5.0.1 (2026-03-10)

### Agentskills Compliance

**头脑风暴服务器移至技能目录**

- 按照 [agentskills.io](https://agentskills.io) 规范移动了 `lib/brainstorm-server/` → `skills/brainstorming/scripts/`
- 所有 `${CLAUDE_PLUGIN_ROOT}/lib/brainstorm-server/` 引用替换为相对 `scripts/` 路径
- 技能现在可以完全跨平台移植 - 不需要特定于平台的环境变量来定位脚本
- `lib/`目录已删除（是最后剩余的内容）

### New Features

**Gemini CLI 扩展**

- 通过存储库根目录中的 `gemini-extension.json` 和 `GEMINI.md` 支持本机 Gemini CLI 扩展
- `GEMINI.md` @imports `using-superpowers` 会话开始时的技能和工具映射表
- Gemini CLI 工具映射参考 (`skills/using-superpowers/references/gemini-tools.md`) — 将 Claude Code 工具名称（Read、Write、Edit、Bash 等）转换为 Gemini CLI 等效项（read_file、write_file、replace 等）
- 文档 Gemini CLI 限制：没有子代理支持，技能回退到 `executing-plans`
- 存储库根目录中的扩展根目录可实现跨平台兼容性（避免 Windows 符号链接问题）
- 安装说明添加到自述文件中

### Improvements

**多平台头脑风暴服务器上线**

- visual-companion.md 中的每个平台启动说明：Claude Code（默认模式）、Codex（通过 `CODEX_CI` 自动前台）、Gemini CLI（`--foreground` 和 `is_background`）以及其他环境的回退
- 服务器现在将启动 JSON 写入 `$SCREEN_DIR/.server-info`，因此即使后台执行隐藏了 stdout，代理也可以找到 URL 和端口

**集思广益捆绑服务器依赖项**

- `node_modules` 已供应到存储库中，因此头脑风暴服务器可以立即在新安装的插件上运行，而无需在运行时使用 `npm`
- 从捆绑的 deps 中删除了 `fsevents` （仅限 macOS 的本机二进制文件；没有它，chokidar 会优雅地回退）
- 如果缺少 `node_modules`，则通过 `npm install` 进行回退自动安装

**OpenCode 工具映射修复**

- `TodoWrite` → `todowrite`（被错误地映射到`update_plan`）；根据 OpenCode 源代码进行验证

### Bug Fixes

**Windows/Linux：单引号中断 SessionStart 挂钩**（#577、#529、#644、PR #585）

- hooks.json 中的 `${CLAUDE_PLUGIN_ROOT}` 周围的单引号在 Windows 上失败（cmd.exe 无法将单引号识别为路径分隔符）和 Linux 上（单引号防止变量扩展）
- 修复：用转义双引号替换单引号 - 适用于 macOS bash、Windows cmd.exe、Windows Git Bash 和 Linux，路径中带或不带空格
- 在 Windows 11 (NT 10.0.26200.0) 上使用 Claude Code 2.1.72 和 Git for Windows 进行验证

**跳过头脑风暴规范审查循环** (#677)

- 规范审查循环（调度规范文档审查者子代理，迭代直至批准）存在于散文"设计之后"部分中，但在清单和流程图中缺失
- 由于代理遵循图表和清单比散文更可靠，因此完全跳过了规范审查步骤
- 将步骤 7（规范审查循环）添加到清单中，并将相应的节点添加到点图中
- 使用 `claude --plugin-dir` 和 `claude-session-driver` 进行测试：工作人员现在可以正确派遣审阅者

**光标安装命令** (PR #676)

- 修复了自述文件中的 Cursor 安装命令：`/plugin-add` → `/add-plugin`（通过 Cursor 2.5 发布公告确认）

**头脑风暴中的用户审查门** (#565)

- 在规范完成和编写计划交接之间添加了明确的用户审查步骤
- 在实施计划开始之前，用户必须批准规范
- 使用新的大门更新了清单、流程和文章

**会话启动挂钩每个平台仅发出一次上下文**

- Hook 现在可以检测它是在 Claude Code 还是其他平台上运行
- 为 Claude 代码发出 `hookSpecificOutput`，为其他代码发出 `additional_context` — 防止双重上下文注入

**令牌分析脚本中的 Linting 修复**

- `except:` → `except Exception:` 在 `tests/claude-code/analyze-token-usage.py`

### Maintenance

**删除死代码**

- 删除了 `lib/skills-core.js` 及其测试 (`tests/opencode/test-skills-core.js`) — 自 2026 年 2 月以来未使用
- 从`tests/opencode/test-plugin-loading.sh`中删除了技能核心存在检查

### Community

- @karuturi — Claude Code 官方市场安装说明 (PR #610)
- @mvanhorn — 会话启动挂钩双发射修复、OpenCode 工具映射修复
- @daniel-graham — 对裸露的 linting 进行修复，除了
- PR #585 作者 — Windows/Linux 挂钩引用修复

---

## v5.0.0 (2026-03-09)

### Breaking Changes

**规格和计划目录已重组**

- 规格（头脑风暴输出）现在保存到 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- 计划（编写计划输出）现在保存到 `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- User preferences for spec/plan locations override these defaults
- 所有内部技能参考、测试文件和示例路径均已更新以匹配
- 迁移：如果需要，将现有文件从 `docs/plans/` 移动到新位置

**有能力的线束必须进行子代理驱动的开发**

编写计划不再提供子代理驱动计划和执行计划之间的选择。在具有子代理支持（Claude Code、Codex）的工具上，需要子代理驱动开发。执行计划是为没有子代理功能的线束保留的，现在告诉用户 Superpowers 在具有子代理功能的平台上工作得更好。

**执行计划不再批量**

删除了"执行 3 个任务然后停止进行审查"模式。计划现在连续执行，仅在遇到阻碍时停止。

**斜线命令已弃用**

`/brainstorm`、`/write-plan` 和 `/execute-plan` 现在显示弃用通知，将用户指向相应的技能。命令将在下一个主要版本中删除。

### New Features

**视觉头脑风暴伴侣**

可选的基于浏览器的头脑风暴会议伴侣。当某个主题受益于视觉效果时，头脑风暴技能可以在浏览器窗口中与终端对话一起显示模型、图表、比较和其他内容。

- `lib/brainstorm-server/` — WebSocket 服务器，带有浏览器帮助程序库、会话管理脚本和深色 /light 主题框架模板（带有 GitHub 链接的"Superpowers Brainstorming"）
- `skills/brainstorming/visual-companion.md` — 服务器工作流程、屏幕创作和反馈收集的渐进式披露指南
- 头脑风暴技能在其流程中添加了视觉同伴决策点：在探索项目背景后，该技能评估即将出现的问题是否涉及视觉内容，并在自己的消息中提供同伴
- 每个问题的决策：即使在接受后，每个问题都会评估浏览器或终端是否更合适
- `tests/brainstorm-server/` 中的集成测试

**文件审核系统**

使用子代理调度对规范和计划文档进行自动审查循环：

- `skills/brainstorming/spec-document-reviewer-prompt.md` — 审阅者检查完整性、一致性、架构和 YAGNI
- `skills/writing-plans/plan-document-reviewer-prompt.md` — 审阅者检查规范对齐、任务分解、文件结构和文件大小
- 撰写设计文档后，集思广益派遣规范审阅者
- 写作计划包括每个部分之后基于块的计划审查循环
- 重复审核循环直至获得批准或在 5 次迭代后升级
- `tests/claude-code/test-document-review-system.sh` 中的端到端测试
- `docs/superpowers/` 中的设计规范和实施方案

**跨技能管道的架构指导**

集思广益、编写计划和子代理驱动开发中添加了隔离设计和文件大小感知指南：

- **头脑风暴** - 新部分："设计隔离和清晰"（清晰的边界、定义明确的接口、独立可测试的单元）和"在现有代码库中工作"（遵循现有模式，仅进行有针对性的改进）
- **写作计划** — 新的"文件结构"部分：在定义任务之前规划出文件和职责。新的"范围检查"支持：捕获本应在头脑风暴期间分解的多子系统规范
- **SDD 实施者** — 新的"代码组织"部分（遵循计划的文件结构，报告有关文件增长的问题）和"当您陷入困境时"升级指南
- **SDD 代码质量审查程序** — 现在检查架构、单元分解、计划一致性和文件增长
- **Spec/plan 审阅者** — 添加到审阅标准的架构和文件大小
- **范围评估** - 头脑风暴现在评估项目对于单个规范是否太大。多子系统请求尽早标记并分解为子项目，每个子项目都有自己的规范→计划→实施周期

**子代理驱动的开发改进**

- **模型选择** - 按任务类型选择模型功能的指南：用于机械实现的廉价模型、集成标准、架构和审查能力
- **实施者状态协议** — 子代理现在报告 DONE、DONE_WITH_CONCERNS、BLOCKED 或 NEEDS_CONTEXT。控制器适当地处理每个状态：使用更多上下文重新调度、升级模型功能、分解任务或升级为人工

### Improvements

**指令优先级层次**

为 using-superpowers 添加了明确的优先级排序：

1. 用户的显式指令（CLAUDE.md、AGENTS.md、直接请求）——最高优先级
2. 超能力技能——覆盖默认系统行为
3. 默认系统提示——最低优先级

如果CLAUDE.md或AGENTS.md说"不要使用TDD"并且技能说"总是使用TDD"，则用户的指令获胜。

**SUBAGENT-STOP gate**

向 using-superpowers 添加了 `<SUBAGENT-STOP>` 块。为特定任务分派的子代理现在会跳过技能，而不是激活 1% 规则并调用完整技能工作流程。

**Multi-platform improvements**

- 法典工具映射移至渐进公开参考文件 (`references/codex-tools.md`)
- 添加了平台适应指针，以便非克劳德代码平台可以找到等效工具
- 计划标题现在专门针对"代理工人"而不是"克劳德"
- 协作功能要求记录在`docs/README.codex.md`中

**写作计划模板更新**

- 计划步骤现在使用复选框语法 (`- [ ] **Step N:**`) 进行进度跟踪
- 计划标头引用子代理驱动的开发和具有平台感知路由的执行计划

---

## v4.3.1 (2026-02-21)

### Added

**Cursor support**

Superpowers 现在可与 Cursor 的插件系统配合使用。自述文件中包括 `.cursor-plugin/plugin.json` 清单和特定于 Cursor 的安装说明。 SessionStart 挂钩输出现在包括一个 `additional_context` 字段以及现有的 `hookSpecificOutput.additionalContext` 字段，以实现游标挂钩兼容性。

### Fixed

**Windows：恢复多语言包装器以实现可靠的钩子执行（#518、#504、#491、#487、#466、#440）**

Claude Code 在 Windows 上的 `.sh` 自动检测会将 `bash` 添加到钩子命令之前，从而中断执行。修复：

- 将 `session-start.sh` 重命名为 `session-start`（无扩展名），因此自动检测不会干扰
- 恢复了具有多位置 bash 发现的 `run-hook.cmd` 多语言包装器（Windows 路径的标准 Git，然后是 PATH 回退）
- 如果没有找到 bash，则静默退出而不是出错
- 在 Unix 上，包装器直接通过 `exec bash` 运行脚本
- 使用 POSIX 安全的 `dirname "$0"` 路径解析（适用于 dash/sh，而不仅仅是 bash）

这修复了 Windows 上的 SessionStart 失败（路径中存在空格）、缺少 WSL、MSYS 上的 `set -euo pipefail` 脆弱性以及反斜杠损坏。

## v4.3.0 (2026-02-12)

此修复应该会显着提高超能力技能的合规性，并减少克劳德无意中进入其本机计划模式的机会。

### Changed

**头脑风暴技能现在强制执行其工作流程，而不是描述它**

模型跳过设计阶段，直接跳到前端设计等实施技能，或者将整个头脑风暴过程分解为单个文本块。该技能现在使用硬门、强制性检查表和 graphviz 流程来强制合规性：

- `<HARD-GATE>`：在设计提出并获得用户批准之前，没有实施技能、代码或脚手架
- 必须创建为任务并按顺序完成的明确清单（6 项）
- Graphviz 流程，以 `writing-plans` 作为唯一有效的终端状态
- 反模式标注"这太简单了，不需要设计"——精确的合理化模型用来跳过这个过程
- 根据部分复杂性而不是项目复杂性设计部分大小

**使用-superpowers工作流程图拦截EnterPlanMode**

在技能流程图中添加了`EnterPlanMode`拦截。当模型即将进入 Claude 的本机计划模式时，它会检查头脑风暴是否已发生，并通过头脑风暴技能进行路由。永远不会进入计划模式。

### Fixed

**SessionStart 挂钩现在同步运行**

将hooks.json中的`async: true`更改为`async: false`。当异步时，挂钩可能无法在模型第一次转动之前完成，这意味着使用超级能力指令不在第一条消息的上下文中。

## v4.2.0 (2026-02-05)

### Breaking Changes

**Codex：用本机技能发现替换了 bootstrap CLI**

`superpowers-codex` 引导 CLI、Windows `.cmd` 包装器和相关引导内容文件已被删除。 Codex 现在通过 `~/.agents/skills/superpowers/` 符号链接使用本机技能发现，因此不再需要旧的 `use_skill`/`find_skills` CLI 工具。

安装现在只需克隆+符号链接（记录在INSTALL.md中）。不需要 Node.js 依赖项。旧的 `~/.codex/skills/` 路径已弃用。

### Fixes

**Windows：修复了 Claude Code 2.1.x 挂钩执行 (#331)**

Claude Code 2.1.x 更改了挂钩在 Windows 上的执行方式：它现在自动检测命令中的 `.sh` 文件并在前面添加 `bash`。这打破了多语言包装模式，因为 `bash "run-hook.cmd" session-start.sh` 尝试将 `.cmd` 文件作为 bash 脚本执行。

修复：hooks.json 现在直接调用 session-start.sh。 Claude Code 2.1.x 自动处理 bash 调用。还添加了 .gitattributes 以强制 shell 脚本使用 LF 行结尾（修复 Windows 签出上的 CRLF 问题）。

**Windows：SessionStart 挂钩运行异步以防止终端冻结（#404、#413、#414、#419）**

同步 SessionStart 挂钩阻止 TUI 在 Windows 上进入原始模式，冻结所有键盘输入。异步运行钩子可以防止冻结，同时仍然注入超能力上下文。

**Windows：固定 O(n^2) `escape_for_json` 性能**

由于子字符串复制开销，在 bash 中使用 `${input:$i:1}` 的逐字符循环的时间复杂度为 O(n^2)。在 Windows Git Bash 上，这花了 60 多秒。替换为 bash 参数替换 (`${s//old/new}`)，它将每个模式作为单个 C 级传递运行 — 在 macOS 上快 7 倍，在 Windows 上快得多。

**Codex：修复了 Windows/PowerShell 调用（#285、#243）**

- Windows 不尊重 shebang，因此直接调用无扩展名 `superpowers-codex` 脚本会触发"打开方式"对话框。所有调用现在都以 `node` 为前缀。
- 修复了 Windows 上的 `~/` 路径扩展 — 当作为参数传递给 `node` 时，PowerShell 不会扩展 `~`。更改为 `$HOME`，它可以在 bash 和 PowerShell 中正确扩展。

**Codex：修复了安装程序中的路径解析**

使用 `fileURLToPath()` 代替手动 URL 路径名解析，以正确处理所有平台上包含空格和特殊字符的路径。

**法典：修复了写作技能中过时的技能路径**

将 `~/.codex/skills/` 参考（已弃用）更新为 `~/.agents/skills/` 以进行本机发现。

### Improvements

**实施前现在需要工作树隔离**

添加了`using-git-worktrees`作为`subagent-driven-development`和`executing-plans`的必需技能。实施工作流程现在明确要求在开始工作之前设置一个独立的工作树，以防止直接在主干上进行意外工作。

**主要分支保护软化为需要明确同意**

现在，这些技能不再完全禁止主要分支的工作，而是在用户明确同意的情况下允许它。更加灵活，同时仍确保用户了解其含义。

**简化安装验证**

从验证步骤中删除了 `/help` 命令检查和特定斜杠命令列表。技能主要是通过描述您想要执行的操作来调用的，而不是通过运行特定命令来调用。

**Codex：澄清引导程序中的子代理工具映射**

改进了有关 Codex 工具如何映射到子代理工作流程的 Claude Code 等效项的文档。

### Tests

- 添加了子代理驱动开发的工作树需求测试
- 添加主分支红旗警告测试
- 修复了技能识别测试断言中的大小写敏感性

---

## v4.1.1 (2026-01-23)

### Fixes

**OpenCode：根据官方文档在 `plugins/` 目录上进行标准化 (#343)**

OpenCode 的官方文档使用`~/.config/opencode/plugins/`（复数）。我们的文档之前使用过 `plugin/` （单数）。虽然 OpenCode 接受这两种形式，但我们已经对官方约定进行了标准化以避免混淆。

Changes:
- 在存储库结构中将 `.opencode/plugin/` 重命名为 `.opencode/plugins/`
- 更新了所有平台上的所有安装文档（INSTALL.md、README.opencode.md）
- 更新了测试脚本以匹配

**OpenCode：修复了符号链接指令（#339、#342）**

- 在 `ln -s` 之前添加了显式 `rm`（修复了重新安装时的"文件已存在"错误）
- 添加了 INSTALL.md 中缺少的技能符号链接步骤
- 从已弃用的 `use_skill`/`find_skills` 更新为本机 `skill` 工具参考

---

## v4.1.0 (2026-01-23)

### Breaking Changes

**OpenCode：切换到原生技能系统**

Superpowers for OpenCode 现在使用 OpenCode 的本机 `skill` 工具，而不是自定义的 `use_skill`/`find_skills` 工具。这是一个更清晰的集成，可与 OpenCode 的内置技能发现配合使用。

**需要迁移：** 技能必须符号链接到 `~/.config/opencode/skills/superpowers/`（请参阅更新的安装文档）。

### Fixes

**OpenCode：修复了会话启动时代理重置的问题 (#226)**

之前使用 `session.prompt({ noReply: true })` 的引导注入方法导致 OpenCode 在第一条消息上将所选代理重置为"构建"。现在使用`experimental.chat.system.transform`钩子直接修改系统提示符，没有副作用。

**OpenCode：修复了 Windows 安装 (#232)**

- 删除了对 `skills-core.js` 的依赖（消除了复制文件而不是符号链接时损坏的相对导入）
- 添加了 cmd.exe、PowerShell 和 Git Bash 的全面 Windows 安装文档
- 记录了每个平台的正确符号链接与连接使用情况

**Claude Code：修复了 Claude Code 2.1.x 的 Windows 挂钩执行**

Claude Code 2.1.x 更改了挂钩在 Windows 上的执行方式：它现在自动检测命令中的 `.sh` 文件并在前面添加 `bash `。这打破了多语言包装模式，因为 `bash "run-hook.cmd" session-start.sh` 尝试将 .cmd 文件作为 bash 脚本执行。

修复：hooks.json 现在直接调用 session-start.sh。 Claude Code 2.1.x 自动处理 bash 调用。还添加了 .gitattributes 以强制 shell 脚本使用 LF 行结尾（修复 Windows 签出上的 CRLF 问题）。

---

## v4.0.3 (2025-12-26)

### Improvements

**针对明确的技能要求强化了使用超能力的技能**

解决了一种故障模式，即使用户通过名称明确请求该技能（例如，"请使用子代理驱动开发"），克劳德也会跳过调用该技能。克劳德会想"我知道这意味着什么"，然后直接开始工作，而不是加载技能。

Changes:
- 更新了"规则"以"调用相关或请求的技能"而不是"检查技能" - 强调主动调用而不是被动检查
- 添加"在任何回应或行动之前" - 原来的措辞只提到"回应"，但克劳德有时会在不先回应的情况下采取行动
- 增加了调用错误技能是可以的保证 - 减少犹豫
- 添加了新的危险信号："我知道这意味着什么"→了解概念≠使用技能

**添加了明确的技能要求测试**

`tests/explicit-skill-requests/` 中的新测试套件可验证 Claude 在用户通过名称请求技能时是否正确调用技能。包括单圈和多圈测试场景。

## v4.0.2 (2025-12-23)

### Fixes

**斜线命令现在仅供用户使用**

将 `disable-model-invocation: true` 添加到所有三个斜杠命令（`/brainstorm`、`/execute-plan`、`/write-plan`）。克劳德无法再通过技能工具调用这些命令 - 它们仅限于手动用户调用。

基本技能（`superpowers:brainstorming`、`superpowers:executing-plans`、`superpowers:writing-plans`）仍然可供克劳德自主调用。当克劳德调用仅重定向到技能的命令时，此更改可以防止混淆。

## v4.0.1 (2025-12-23)

### Fixes

**阐明了如何获取克劳德代码中的技能**

修复了克劳德通过技能工具调用技能，然后尝试单独读取技能文件的令人困惑的模式。 `using-superpowers` 技能现在明确指出技能工具直接加载技能内容，无需读取文件。

- 在`using-superpowers`中添加了"如何获取技能"部分
- 修改了指令中的"读取技能"→"调用技能"
- 更新了斜杠命令以使用完全限定的技能名称（例如，`superpowers:brainstorming`）

**添加了对接收代码审查的 GitHub 线程回复指南** (h/t @ralphbean)

添加了关于回复原始线程中的内嵌评论评论的注释，而不是作为顶级 PR 评论。

**添加了对写作技能的自动化文档指导** (h/t @EthanJStark)

添加了关于机械约束应该自动化而不是记录的指导——保留用于判断的技能。

## v4.0.0 (2025-12-17)

### New Features

**子代理驱动开发中的两阶段代码审查**

子代理工作流程现在在每个任务之后使用两个单独的审核阶段：

1. **规范合规性审查** - 持怀疑态度的审查者验证实施是否完全符合规范。捕获缺失的需求和过度构建。不会相信实施者的报告——阅读实际代码。

2. **代码质量审查** - 仅在规范合规性通过后运行。审查干净的代码、测试覆盖率、可维护性。

这捕获了常见的故障模式，即代码编写良好但与请求的内容不匹配。评审是循环的，而不是一次性的：如果评审者发现问题，实施者会修复它们，然后评审者再次检查。

其他子代理工作流程改进：
- 控制器向工作人员提供完整的任务文本（不是文件引用）
- 工人可以在工作前和工作期间提出澄清问题
- 报告完成前的自我审查清单
- 计划在开始时读取一次，提取到 TodoWrite

`skills/subagent-driven-development/` 中的新提示模板：
- `implementer-prompt.md` - 包括自我审查清单，鼓励提问
- `spec-reviewer-prompt.md` - 根据要求进行怀疑性验证
- `code-quality-reviewer-prompt.md` - 标准代码审查

**调试技术与工具相结合**

`systematic-debugging` 现在捆绑支持技术和工具：
- `root-cause-tracing.md` - 通过调用堆栈向后跟踪错误
- `defense-in-depth.md` - 添加多层验证
- `condition-based-waiting.md` - 用条件轮询替换任意超时
- `find-polluter.sh` - 二分脚本来查找哪个测试造成污染
- `condition-based-waiting-example.ts` - 真实调试会话的完整实现

**测试反模式参考**

`test-driven-development` 现在包括 `testing-anti-patterns.md` 覆盖：
- 测试模拟行为而不是真实行为
- 将仅测试方法添加到生产类中
- 在不了解依赖关系的情况下进行模拟
- 隐藏结构假设的不完整模拟

**技能测试基础设施**

用于验证技能行为的三个新测试框架：

`tests/skill-triggering/` - 在没有明确命名的情况下验证简单提示的技能触发。测试 6 项技能以确保仅描述就足够了。

`tests/claude-code/` - 使用 `claude -p` 进行无头测试的集成测试。通过会话记录 (JSONL) 分析验证技能使用情况。包括用于成本跟踪的`analyze-token-usage.py`。

`tests/subagent-driven-dev/` - 通过两个完整的测试项目进行端到端工作流程验证：
- `go-fractals/` - 使用 Sierpinski/Mandelbrot 的 CLI 工具（10 个任务）
- `svelte-todo/` - 带有 localStorage 和 Playwright 的 CRUD 应用程序（12 个任务）

### Major Changes

**DOT 流程图作为可执行规范**

Rewrote key skills using DOT/GraphViz flowcharts as the authoritative process definition. Prose becomes supporting content.

**描述陷阱**（记录在`writing-skills`中）：发现当描述包含工作流摘要时，技能描述会覆盖流程图内容。克劳德遵循简短的描述，而不是阅读详细的流程图。修复：描述必须仅触发（"在 X 时使用"），没有流程详细信息。

**使用超能力时技能优先**

当应用多种技能时，流程技能（头脑风暴、调试）现在明确优先于实施技能。 "Build X"首先引发头脑风暴，然后引发领域技能。

**强化头脑风暴触发**

描述更改为命令式："您必须在任何创造性工作之前使用它——创建功能、构建组件、添加功能或修改行为。"

### Breaking Changes

**技能整合** - 合并六项独立技能：
- `root-cause-tracing`、`defense-in-depth`、`condition-based-waiting` → 捆绑在 `systematic-debugging/` 中
- `testing-skills-with-subagents` → 捆绑在`writing-skills/`
- `testing-anti-patterns` → 捆绑在`test-driven-development/`
- `sharing-skills` 已删除（已过时）

### Other Improvements

- **render-graphs.js** - 从技能中提取点图并渲染为 SVG 的工具
- **使用超级大国中的合理化表** - 可扫描格式，包括新条目："我首先需要更多上下文"，"让我先探索一下"，"这感觉很有成效"
- **docs/testing.md** - 使用 Claude Code 集成测试测试技能的指南

---

## v3.6.2 (2025-12-03)

### Fixed

- **Linux 兼容性**：修复了多语言挂钩包装器 (`run-hook.cmd`) 以使用 POSIX 兼容语法
  - 在第 16 行将特定于 bash 的 `${BASH_SOURCE[0]:-$0}` 替换为标准 `$0`
  - 解决了 Ubuntu/Debian 系统上的"错误替换"错误，其中 `/bin/sh` 是破折号
  - Fixes #141

---

## v3.5.1 (2025-11-24)

### Changed

- **OpenCode Bootstrap Refactor**：从 `chat.message` 挂钩切换到 `session.created` 事件以进行引导注入
  - Bootstrap 现在通过 `session.prompt()` 和 `noReply: true` 在会话创建时注入
  - 明确告诉模型 using-superpowers 已经加载，以防止多余的技能加载
  - 将引导内容生成合并到共享 `getBootstrapContent()` 帮助程序中
  - 更干净的单一实现方法（删除了后备模式）

---

## v3.5.0 (2025-11-23)

### Added

- **OpenCode 支持**：OpenCode.ai 的本机 JavaScript 插件
  - 自定义工具：`use_skill` 和 `find_skills`
  - 用于跨上下文压缩技能持久性的消息插入模式
  - 通过 chat.message 钩子自动上下文注入
  - 自动重新注入 session.compacted 事件
  - 三层技能优先级：项目>个人>超能力
  - 项目本地技能支持 (`.opencode/skills/`)
  - 用于 Codex 代码重用的共享核心模块 (`lib/skills-core.js`)
  - 具有适当隔离的自动化测试套件 (`tests/opencode/`)
  - 特定于平台的文档（`docs/README.opencode.md`、`docs/README.codex.md`）

### Changed

- **重构 Codex 实现**：现在使用共享 `lib/skills-core.js` ES 模块
  - 消除 Codex 和 OpenCode 之间的代码重复
  - 用于技能发现和解析的单一事实来源
  - Codex 通过 Node.js 互操作成功加载 ES 模块

- **改进文档**：重写自述文件以清楚地解释问题/solution
  - 删除了重复的部分和冲突的信息
  - 添加了完整的工作流程描述（头脑风暴→计划→执行→完成）
  - 简化的平台安装说明
  - 强调技能检查协议而不是自动激活声明

---

## v3.4.1 (2025-10-31)

### Improvements

- 优化超能力引导程序，消除多余的技能执行。 `using-superpowers` 技能内容现在直接在会话上下文中提供，并明确指导仅将技能工具用于其他技能。这减少了开销并防止出现令人困惑的循环，即尽管已经拥有会话启动时的内容，代理仍会手动执行 `using-superpowers`。

## v3.4.0 (2025-10-30)

### Improvements

- 简化了`brainstorming`技能，回到原来的对话视野。删除了带有正式检查表的重量级 6 阶段流程，转而采用自然对话：一次提出一个问题，然后以 200-300 字的部分展示设计并进行验证。保留文档和实施移交功能。

## v3.3.1 (2025-10-28)

### Improvements

- 更新了 `brainstorming` 技能，要求在询问之前进行自主侦察，鼓励推荐驱动的决策，并防止代理将优先级委托给人类。
- 遵循斯特伦克的"风格元素"原则，对`brainstorming`技能进行写作清晰度改进（省略不必要的单词，将否定形式转换为肯定形式，改进并行结构）。

### Bug Fixes

- 澄清了`writing-skills`指南，使其指向正确的特工特定个人技能目录（`~/.claude/skills`用于Claude Code，`~/.codex/skills`用于Codex）。

## v3.3.0 (2025-10-28)

### New Features

**实验性法典支持**
- 添加了带有引导/use-skill/find-skills命令的统一`superpowers-codex`脚本
- 跨平台 Node.js 实现（适用于 Windows、macOS、Linux）
- 命名空间技能：`superpowers:skill-name`为超能力技能，`skill-name`为个人技能
- 当名字匹配时，个人技能优先于超能力技能
- Clean skill display: shows name/description without raw frontmatter
- 有用的上下文：显示每个技能的支持文件目录
- Codex 的工具映射：TodoWrite→update_plan、子代理→手动回退等。
- 引导程序集成与最小的AGENTS.md自动启动
- Codex 特定的完整安装指南和引导说明

**与 Claude Code 集成的主要区别：**
- 单个统一脚本而不是单独的工具
- 法典特定等效工具的工具替代系统
- 简化的子代理处理（手动工作而不是委派）
- 更新术语："超能力技能"而不是"核心技能"

### Files Added
- `.codex/INSTALL.md` - Codex 用户安装指南
- `.codex/superpowers-bootstrap.md` - 经 Codex 改编的引导指令
- `.codex/superpowers-codex` - 具有所有功能的统一 Node.js 可执行文件

**注意：** Codex 支持是实验性的。该集成提供了核心超级功能，但可能需要根据用户反馈进行改进。

## v3.2.3 (2025-10-23)

### Improvements

**更新了使用超能力技能以使用技能工具而不是阅读工具**
- 将技能调用指令从读取工具更改为技能工具
- 更新说明："使用阅读工具"→"使用技能工具"
- 更新了步骤3："使用读取工具"→"使用技能工具读取并运行"
- 更新合理化列表："读取当前版本"→"运行当前版本"

Skill 工具是 Claude Code 中调用技能的正确机制。此更新更正了引导指令，以引导代理使用正确的工具。

### Files Changed
- 更新：`skills/using-superpowers/SKILL.md` - 将工具参考从"阅读"更改为"技能"

## v3.2.2 (2025-10-21)

### Improvements

**加强使用超能力对抗特工合理化的技巧**
- 添加了极其重要的块，其中包含关于强制技能检查的绝对语言
  - "如果一项技能有 1% 的机会适用，你就必须阅读它"
  - "你别无选择。你无法合理化自己的出路。"
- 添加了强制第一响应协议清单
  - 代理必须在做出任何响应之前完成 5 个步骤流程
  - 明确的"没有这个响应=失败"的后果
- 添加了具有 8 种特定规避模式的常见合理化部分
  - "这只是一个简单的问题"→ 错误
  - "我可以快速检查文件" → 错误
  - "让我先收集信息" → 错误
  - 加上在代理行为中观察到的 5 种更常见的模式

这些变化解决了观察到的代理行为，尽管有明确的指示，但他们仍围绕技能使用进行合理化。强有力的语言和先发制人的反驳旨在让不遵守行为变得更加困难。

### Files Changed
- 更新：`skills/using-superpowers/SKILL.md` - 添加了三层强制措施，以防止技能跳过合理化

## v3.2.1 (2025-10-20)

### New Features

**代码审查代理现在包含在插件中**
- 将 `superpowers:code-reviewer` 代理添加到插件的 `agents/` 目录
- 代理根据计划和编码标准提供系统的代码审查
- 以前要求用户拥有个人代理配置
- 所有技能参考均更新为使用命名空间 `superpowers:code-reviewer`
- Fixes #55

### Files Changed
- 新增内容：`agents/code-reviewer.md` - 具有审核清单和输出格式的代理定义
- 更新：`skills/requesting-code-review/SKILL.md` - 对 `superpowers:code-reviewer` 的引用
- 更新：`skills/subagent-driven-development/SKILL.md` - 对 `superpowers:code-reviewer` 的引用

## v3.2.0 (2025-10-18)

### New Features

**头脑风暴工作流程中的设计文档**
- 添加了第 4 阶段：设计文档到头脑风暴技能
- 现在在实施之前将设计文档写入`docs/plans/YYYY-MM-DD-<topic>-design.md`
- 恢复技能转换过程中丢失的原始头脑风暴命令的功能
- 在工作树设置和实施规划之前编写的文档
- 使用子代理进行测试，以验证时间压力下的合规性

### Breaking Changes

**技能参考命名空间标准化**
- 所有内部技能引用现在都使用 `superpowers:` 命名空间前缀
- 更新格式：`superpowers:test-driven-development`（之前只是`test-driven-development`）
- 影响所有必需的子技能、推荐的子技能和必需的背景参考
- 与使用技能工具调用技能的方式保持一致
- 更新的文件：头脑风暴、执行计划、子代理驱动开发、系统调试、子代理测试技能、写作计划、写作技能

### Improvements

**设计与实施计划命名**
- 设计文档使用`-design.md`后缀来防止文件名冲突
- 实施计划继续使用现有的`YYYY-MM-DD-<feature-name>.md`格式
- 两者都存储在 `docs/plans/` 目录中，具有明确的命名区别

## v3.1.1 (2025-10-17)

### Bug Fixes

- **自述文件中的固定命令语法** (#44) - 更新了所有命令引用以使用正确的命名空间语法（`/superpowers:brainstorm` 而不是 `/brainstorm`）。插件提供的命令由 Claude Code 自动命名，以避免插件之间发生冲突。

## v3.1.0 (2025-10-17)

### Breaking Changes

**技能名称标准化为小写**
- 所有技能 frontmatter `name:` 字段现在使用小写短横线匹配目录名称
- 示例：`brainstorming`、`test-driven-development`、`using-git-worktrees`
- 所有技能公告和交叉引用均更新为小写格式
- 这确保了目录名称、frontmatter 和文档之间的命名一致

### New Features

**增强头脑风暴技巧**
- 添加了显示阶段、活动和工具使用情况的快速参考表
- 添加了可复制的工作流程清单以跟踪进度
- 添加了何时重新访问早期阶段的决策流程图
- 添加了全面的 AskUserQuestion 工具指南和具体示例
- 添加了"问题模式"部分，解释何时使用结构化问题与开放式问题
- 将关键原则重组为可扫描表

**人类最佳实践集成**
- 添加了 `skills/writing-skills/anthropic-best-practices.md` - 官方 Anthropic 技能创作指南
- 参考写作技巧SKILL.md以获得全面指导
- 提供渐进式披露、工作流程和评估的模式

### Improvements

**技能交叉引用清晰度**
- 所有技能参考现在都使用明确的要求标记：
  - `**REQUIRED BACKGROUND:**` - 您必须了解的先决条件
  - `**REQUIRED SUB-SKILL:**` - 工作流程中必须使用的技能
  - `**Complementary skills:**` - 可选但有用的相关技能
- 删除了旧的路径格式（`skills/collaboration/X`→只是`X`）
- 更新了具有分类关系的集成部分（必需与补充）
- 使用最佳实践更新了交叉引用文档

**与人择最佳实践保持一致**
- 固定描述语法和语音（完全第三人称）
- 添加了扫描快速参考表
- 添加了克劳德可以复制和跟踪的工作流程清单
- 对于不明显的决策点适当使用流程图
- 改进的可扫描表格格式
- 所有技能均远低于 500 行推荐

### Bug Fixes

- **重新添加了缺失的命令重定向** - 恢复了在 v3.0 迁移中意外删除的 `commands/brainstorm.md` 和 `commands/write-plan.md`
- 修复了 `defense-in-depth` 名称不匹配的问题（原为 `Defense-in-Depth-Validation`）
- 修复了 `receiving-code-review` 名称不匹配的问题（原为 `Code-Review-Reception`）
- 修复了 `commands/brainstorm.md` 对正确技能名称的引用
- 删除了对不存在的相关技能的引用

### Documentation

**writing-skills improvements**
- 更新了具有明确要求标记的交叉引用指南
- 添加了对 Anthropic 官方最佳实践的参考
- 改进的示例显示正确的技能参考格式

## v3.0.1 (2025-10-16)

### Changes

我们现在使用Anthropic的第一方技能系统！

## v2.0.2 (2025-10-12)

### Bug Fixes

- **修复了本地技能存储库领先于上游时的错误警告** - 当本地存储库领先于上游提交时，初始化脚本错误地警告"上游可用新技能"。现在，逻辑可以正确区分三种 git 状态：本地落后（应更新）、本地领先（无警告）和发散（应警告）。

## v2.0.1 (2025-10-12)

### Bug Fixes

- **修复了插件上下文中的会话启动钩子执行**（#8，PR #9） - 钩子默默地失败，并出现"插件钩子错误"，阻止加载技能上下文。修复者：
  - 当 BASH_SOURCE 在 Claude Code 的执行上下文中解除绑定时使用 `${BASH_SOURCE[0]:-$0}` 回退
  - 添加 `|| true` 在过滤状态标志时优雅地处理空 grep 结果

---

# Superpowers v2.0.0 Release Notes

## Overview

Superpowers v2.0 通过重大架构转变，使技能更易于访问、维护和社区驱动。

主要变化是**技能存储库分离**：所有技能、脚本和文档已从插件移至专用存储库 ([obra/superpowers-skills](https://github.com/obra/superpowers-skills))。这将超级能力从单一插件转变为管理技能存储库本地克隆的轻量级填充程序。技能会在会话开始时自动更新。用户通过标准 git 工作流程分叉并贡献改进。技能库版本独立于插件。

除了基础设施之外，此版本还增加了九项新技能，重点关注问题解决、研究和架构。我们以命令式的语气和更清晰的结构重写了核心**使用技能**文档，使克劳德更容易理解何时以及如何使用技能。 **查找技能** 现在输出路径，您可以直接粘贴到读取工具中，从而消除技能发现工作流程中的摩擦。

用户体验无缝操作：插件自动处理克隆、分叉和更新。贡献者发现新的架构使改进和共享技能变得微不足道。此版本为技能作为社区资源的快速发展奠定了基础。

## Breaking Changes

### Skills Repository Separation

**最大的变化：** 技能不再存在于插件中。它们已被移至 [obra/superpowers-skills](https://github.com/obra/superpowers-skills) 的单独存储库。

**这对您意味着什么：**

- **首次安装：** 插件自动将技能克隆到`~/.config/superpowers/skills/`
- **分叉：** 在设置过程中，您将可以选择分叉技能存储库（如果安装了`gh`）
- **更新：** 技能在会话开始时自动更新（如果可能的话快进）
- **贡献：** 在分支上工作，在本地提交，向上游提交 PR
- **不再有阴影：**旧的两层系统（个人/core）替换为单存储库分支工作流程

**Migration:**

如果您有现有安装：
1. 您的旧`~/.config/superpowers/.git`将备份到`~/.config/superpowers/.git.bak`
2. 旧技能将备份至`~/.config/superpowers/skills.bak`
3. obra/superpowers-skills 的新克隆将在 `~/.config/superpowers/skills/` 创建

### Removed Features

- **个人超能力覆盖系统** - 替换为 git 分支工作流程
- **设置个人超能力挂钩** - 替换为 initialize-skills.sh

## New Features

### Skills Repository Infrastructure

**自动克隆和设置** (`lib/initialize-skills.sh`)
- Clones obra/superpowers-skills on first run
- 如果安装了 GitHub CLI，则提供分叉创建
- Sets up upstream/origin remotes correctly
- 处理从旧安装的迁移

**Auto-Update**
- 每次会话启动时从跟踪远程获取
- 可能时自动快进合并
- 需要手动同步时发出通知（分支分歧）
- 使用从技能存储库提取更新技能进行手动同步

### New Skills

**解决问题的能力** (`skills/problem-solving/`)
- **碰撞区思维** - 将不相关的概念强行放在一起以获得紧急见解
- **反转练习** - 翻转假设以揭示隐藏的约束
- **元模式识别** - 发现跨领域的通用原则
- **规模游戏** - 进行极端测试以揭示基本事实
- **简化级联** - 找到消除多个组件的见解
- **当卡住时** - 分派正确的问题解决技术

**研究技能** (`skills/research/`)
- **追踪知识血统** - 了解想法如何随着时间的推移而演变

**架构技能** (`skills/architecture/`)
- **保留生产性紧张** - 保留多种有效方法，而不是强制过早解决

### Skills Improvements

**使用技能（以前的入门）**
- 从入门更名为使用技能
- 用祈使语气完全重写（v4.0.0）
- 预先加载的关键规则
- 为所有工作流程添加了"为什么"解释
- Always includes /SKILL.md suffix in references
- 严格的规则和灵活的模式之间的区别更加清晰

**writing-skills**
- 交叉引用指南从使用技能转移
- 添加了令牌效率部分（字数目标）
- 改进的 CSO（克劳德搜索优化）指南

**sharing-skills**
- 更新了新的分支和 PR 工作流程 (v2.0.0)
- Removed personal/core split references

**pulling-updates-from-skills-repository** (new)
- 与上游同步的完整工作流程
- 取代旧的"更新技能"技能

### Tools Improvements

**find-skills**
- Now outputs full paths with /SKILL.md suffix
- 使路径可直接用于读取工具
- 更新了帮助文本

**skill-run**
- Moved from scripts/ to skills/using-skills/
- Improved documentation

### Plugin Infrastructure

**会话启动挂钩**
- 现在从技能存储库位置加载
- 在会话开始时显示完整的技能列表
- 打印技能位置信息
- 显示更新状态（更新成功/落后于上游）
- 将"技能落后"警告移至输出末尾

**Environment Variables**
- `SUPERPOWERS_SKILLS_ROOT` 设置为 `~/.config/superpowers/skills`
- 在所有路径中一致使用

## Bug Fixes

- 修复了分叉时重复的上游远程添加
- 修复了输出中的 find-skills 双"skills/"前缀
- 从会话启动中删除了过时的 setup-personal-superpowers 调用
- 修复了整个钩子和命令的路径引用

## Documentation

### README
- 更新了新的技能存储库架构
- 与超级技能存储库的显着链接
- 更新了自动更新说明
- 固定技能名称和参考
- 更新元技能列表

### Testing Documentation
- 添加了全面的测试清单（`docs/TESTING-CHECKLIST.md`）
- 创建本地市场配置以进行测试
- 记录手动测试场景

## Technical Details

### File Changes

**Added:**
- `lib/initialize-skills.sh` - 技能库初始化和自动更新
- `docs/TESTING-CHECKLIST.md` - 手动测试场景
- `.claude-plugin/marketplace.json` - 本地测试配置

**Removed:**
- `skills/` 目录（82 个文件） - 现在位于 obra/superpowers-skills
- `scripts/`目录 - 现在在obra/superpowers-skills/skills/using-skills/
- `hooks/setup-personal-superpowers.sh` - 已过时

**Modified:**
- `hooks/session-start.sh` - 使用~/.config/superpowers/skills的技能
- `commands/brainstorm.md` - 更新了 SUPERPOWERS_SKILLS_ROOT 的路径
- `commands/write-plan.md` - 更新了 SUPERPOWERS_SKILLS_ROOT 的路径
- `commands/execute-plan.md` - 更新了 SUPERPOWERS_SKILLS_ROOT 的路径
- `README.md` - 新架构的完全重写

### Commit History

此版本包括：
- 20 多项技能库分离提交
- PR #1：放大器启发的问题解决和研究技能
- PR#2：个人超能力叠加系统（后被替换）
- 多项技能改进和文档改进

## Upgrade Instructions

### Fresh Install

```bash
# In Claude Code
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

该插件会自动处理一切。

### Upgrading from v1.x

1. **备份您的个人技能**（如果您有的话）：
   ```bash
   cp -r ~/.config/superpowers/skills ~/superpowers-skills-backup
   ```

2. **更新插件：**
   ```bash
   /plugin update superpowers
   ```

3. **下一次会议开始时：**
   - 旧安装将自动备份
   - 新技能库将被克隆
   - 如果您有 GitHub CLI，您将可以选择分叉

4. **迁移个人技能**（如果您有的话）：
   - 在本地技能存储库中创建分支
   - 从备份中复制您的个人技能
   - 提交并推送到你的分叉
   - 考虑通过公关做出贡献

## 下一步是什么

### For Users

- 探索新的解决问题的技巧
- 尝试基于分支的工作流程来提高技能
- 将技能回馈社区

### For Contributors

- Skills repository is now at https://github.com/obra/superpowers-skills
- 分叉 → 分支 → PR 工作流程
- See skills/meta/writing-skills/SKILL.md for TDD approach to documentation

## Known Issues

目前没有。

## Credits

- 受放大器模式启发的解决问题技能
- 社区贡献和反馈
- 对技能有效性进行广泛的测试和迭代

---

**完整变更日志：** https://github.com/obra/superpowers/compare/dd013f6...main
**技能库：** https://github.com/obra/superpowers-skills
**Issues:** https://github.com/obra/superpowers/issues
