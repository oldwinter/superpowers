# Superpowers for OpenCode

使用 [OpenCode.ai](https://opencode.ai) 的超能力的完整指南。

## Installation

OpenCode V2 需要 2.0.4 或更高版本。

### OpenCode V1

使用现有的 V1 plugin 配置：

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

### OpenCode V2 (2.0.4 or later)

使用 V2 plugin 配置：

```json
{
  "plugins": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

本地 V2 安装需配置包含 `index.js` 的仓库目录。OpenCode 2.0.4 和 2.0.7
会拒绝直接配置 JavaScript 文件路径；自动发现的 plugin 符号链接仍受支持。

重启 OpenCode。V2 使用 `opencode` 命令；`opencode2` 可能作为别名提供。
该 plugin 通过 OpenCode 的 plugin manager 安装，并注册所有 skills。

通过询问来验证："告诉我你的超能力"

OpenCode 使用自己的插件安装。如果您还使用 Claude Code、Codex 或
另一种安全带，为每个安全带单独安装 Superpowers。

### Migrating from the old symlink-based install (V1)

如果您之前使用 `git clone` 和符号链接安装了超级能力，请删除旧的设置：

```bash
# Remove old symlinks
rm -f ~/.config/opencode/plugins/superpowers.js
rm -rf ~/.config/opencode/skills/superpowers

# Optionally remove the cloned repo
rm -rf ~/.config/opencode/superpowers

# Remove skills.paths from opencode.json if you added one for superpowers
```

然后按照上面的安装步骤进行操作。

## Usage

### Finding Skills

使用 OpenCode 的原生 `skill` 工具列出所有可用技能：

```
use skill tool to list skills
```

### Loading a Skill

```
use skill tool to load brainstorming
```

### Personal Skills

在`~/.config/opencode/skills/`中创造你自己的技能：

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

创建`~/.config/opencode/skills/my-skill/SKILL.md`：

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

### Project Skills

在项目中的 `.opencode/skills/` 中创建项目特定技能。

**V2 skill 优先级：** 项目 skills > 个人 skills > Superpowers skills。在已测试的
V1 1.18.31 中，如果个人或项目 skill 同名，内置 Superpowers skill 优先；请为个人和
项目 skills 使用不同名称。迁移不会改变这一行为。

## Updating

OpenCode 通过 git 支持的包规范安装 Superpowers。一些开放代码
和 Bun 版本 pin 解决了锁定文件或缓存中的 git 依赖关系，因此
重新启动可能无法获取最新的 Superpowers 提交。如果没有出现更新，
清除 OpenCode 的包缓存或重新安装插件。

要固定特定版本，请在规范中添加 tag 或 commit（V1 的 `plugin` key 与 V2 的
`plugins` key 使用相同形式）：

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v6.4.2"]
}
```

在 V2 上应固定到 `v6.4.1` 或更高版本；`v6.3.0` 及更早版本只能在 V1 上加载。

## How It Works

该 plugin 使用特定 host 版本的 API 完成两件事：

1. **注册 skills 目录**，使 OpenCode 无需符号链接或手动配置即可发现所有 Superpowers skills。
    - **V1：** 通过 `config` hook 注入 `config.skills.paths`
    - **V2：** 通过使用 `ctx.skill.transform()` 的 `setup()` 函数（V2 原生 API，已确认 runtime 生效）
2. **注入 bootstrap 上下文**并附带版本对应的工具映射：V1 session 获得下方 V1 工具名，V2 session 获得 V2 工具名。
    - **V1：** 通过 `experimental.chat.messages.transform` hook
    - **V2：** 通过 `ctx.session.hook("context")`，即 V2 对应机制（已确认 runtime 生效）

Controller session 会在临时 model context 中接收 `using-superpowers` bootstrap。
被委派的 child session 仍可使用原生 skills，但不会接收 controller bootstrap。
没有 parent session 的手动 fork 会保留 controller 行为。V2 原生 compaction 保留早期
用户消息时（默认受 `compaction.keep.tokens` 预算控制），bootstrap 会像未 compact 的
session 一样放入 checkpoint 之前第一条保留的用户消息。当 compaction 删除全部用户消息时，
plugin 会在 checkpoint 后附加一条临时 bootstrap 消息。两种情况都不会更改保存的历史。

如果 session 查询失败，plugin 会为该请求保留 bootstrap，并在下一请求重试；失败的查询
不会缓存为 controller 判定。

### Tool Mapping

Skills 用动作表达，而不是指定某个 runtime 的工具。Bootstrap 会把动作映射到当前 OpenCode 版本实际暴露的工具。

**V1 (`opencode` 1.x):**

- "创建待办事项"/"在待办事项列表中标记完成"→ `todowrite`
- `Subagent (general-purpose):` 模板 → OpenCode 的 `task` 工具以及 `subagent_type: "general"`（或用于代码库探索的 `"explore"`）
- "调用技能" → OpenCode 原生的`skill`工具
- "读取文件"→`read`
- "创建文件"/"编辑文件"/"删除文件"→ `apply_patch`
- "运行 shell 命令"→ `bash`
- "搜索文件内容"/"按名称查找文件"→ `grep`, `glob`
- "获取 URL"→ `webfetch`

**V2 (`opencode` 2.0.4 or later; `opencode2` may be available as an alias):**

- “创建 todo” → V2 完全没有 todo 工具；映射会让 model 改用 Markdown 文件（或 harness 的 plan 功能）跟踪计划
- `Subagent (general-purpose):` 模板 → OpenCode 的 `subagent` 工具，使用 `agent: "general"`（或 `"explore"`）；传入 `sessionID` 以继续之前的 subagent
- “调用 skill” → OpenCode 原生 `skill` 工具
- “读取文件” → `read`
- “创建、编辑或删除文件” → 可用时使用带 `patchText` 的 `patch`；否则用 `write` 创建或覆盖、`edit` 定点修改、`shell` 删除
- “运行 shell 命令” → `shell`（`command`、`workdir`、`timeout`、`background`）
- “搜索文件内容”/“按名称查找文件” → `grep`、`glob`
- “获取 URL” → `webfetch`
- “搜索 web” → `websearch`

简而言之，V2 将 `task` 改名为 `subagent`（agent 名从 `subagent_type` 移到 `agent`，通过带 `sessionID` 的再次调用继续）、将 `apply_patch` 改名为 `patch`、将 `bash` 改名为 `shell`，并彻底移除了 todo 工具。可用的修改工具取决于所选 model：部分 GPT model ID 可使用 `patch`，其他 model 使用 `write` 和 `edit`。

（V1 列表已对照 OpenCode 1.18.x CLI 的工具清单验证；V2 列表已对照 OpenCode 2.0.4 和 2.0.7 host contract 验证。）

## Troubleshooting

### Plugin not loading

**V1：** 检查 OpenCode 日志：

```
opencode run --print-logs "hello" 2>&1 | grep -i superpowers
```

**V2：** Plugins 在后台 server 中加载，其日志只有在配合 `--standalone` 时才会由
`--print-logs` 显示：

```
opencode run --standalone --print-logs "hello" 2>&1 | grep -i superpowers
```

也可检查 `~/.local/share/opencode/log/opencode.log`，筛选 `role=server`。

另请验证 `opencode.json` 中的 plugin 路径正确，并确保运行较新版本的 OpenCode。

### Windows install issues

某些 Windows OpenCode 版本存在 git 支持的上游安装程序问题
插件规范，包括 `git+https` URL 的缓存路径和 Bun 未找到
`git.exe` 即使它在普通终端中工作。如果 OpenCode 无法安装
插件，尝试使用系统 npm 安装并将 OpenCode 指向本地
package:

```powershell
npm install superpowers@git+https://github.com/obra/superpowers.git --prefix "$HOME\.config\opencode"
```

然后针对所用 OpenCode 版本，在 `opencode.json` 中使用已安装 package 的绝对路径。
OpenCode 不会展开 `~`；`~/...` 条目会被当作 package name，而不是本地目录。

**V1:**

```json
{
  "plugin": ["C:\\Users\\<you>\\.config\\opencode\\node_modules\\superpowers"]
}
```

**V2 (2.0.4 or later):**

```json
{
  "plugins": ["C:\\Users\\<you>\\.config\\opencode\\node_modules\\superpowers"]
}
```

### Skills not found

1. 使用 OpenCode 的 `skill` 工具列出可用技能
2. 检查插件是否正在加载（见上文）
3. 每个技能都需要一个带有有效 YAML frontmatter 的 `SKILL.md` 文件

### Bootstrap not appearing

- **V1：** 检查 OpenCode 版本是否支持 `experimental.chat.messages.transform` hook；配置更改后重启 OpenCode。
- **V2：** Plugin 使用 `ctx.session.hook("context")` 注入 bootstrap。通过 `opencode api get /api/plugin` 验证 plugin 已加载；配置更改后用 `opencode service restart` 重启。`opencode2` 命令可能作为别名提供。

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Main documentation: https://github.com/obra/superpowers
- OpenCode V2 docs: https://opencode.ai/v2/docs/
- OpenCode V1 docs: https://opencode.ai/docs/
