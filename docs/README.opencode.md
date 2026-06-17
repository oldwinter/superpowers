# Superpowers for OpenCode

使用 [OpenCode.ai](https://opencode.ai) 的超能力的完整指南。

## Installation

将超级能力添加到 `opencode.json` 中的 `plugin` 数组（全局或项目级别）：

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

重新启动 OpenCode。该插件通过 OpenCode 的插件管理器安装，
注册所有技能。

通过询问来验证："告诉我你的超能力"

OpenCode 使用自己的插件安装。如果您还使用 Claude Code、Codex 或
另一种安全带，为每个安全带单独安装 Superpowers。

### Migrating from the old symlink-based install

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

**技能优先级：** 项目技能 > 个人技能 > 超能力技能

## Updating

OpenCode 通过 git 支持的包规范安装 Superpowers。一些开放代码
和 Bun 版本 pin 解决了锁定文件或缓存中的 git 依赖关系，因此
重新启动可能无法获取最新的 Superpowers 提交。如果没有出现更新，
清除 OpenCode 的包缓存或重新安装插件。

要固定特定版本，请使用分支或标签：

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```

## How It Works

该插件做了两件事：

1. **通过 `experimental.chat.messages.transform` 钩子注入引导上下文**，为每个对话添加超能力意识。
2. **通过 `config` 钩子注册技能目录**，因此 OpenCode 无需符号链接或手动配置即可发现所有超级技能。

### Tool Mapping

技能用行动说话，而不是命名任何一种运行时的工具。在 OpenCode 上，这些解析为：

- "创建待办事项"/"在待办事项列表中标记完成"→ `todowrite`
- `Subagent (general-purpose):` 模板 → OpenCode 的 `task` 工具以及 `subagent_type: "general"`（或用于代码库探索的 `"explore"`）
- "调用技能" → OpenCode 原生的`skill`工具
- "读取文件"→`read`
- "创建文件"/"编辑文件"/"删除文件"→ `apply_patch`
- "运行 shell 命令"→ `bash`
- "搜索文件内容"/"按名称查找文件"→ `grep`, `glob`
- "获取 URL"→ `webfetch`

（根据已安装的 OpenCode CLI 工具清单进行验证。）

## Troubleshooting

### Plugin not loading

1. 检查 OpenCode 日志：`opencode run --print-logs "hello" 2>&1 | grep -i superpowers`
2. 验证 `opencode.json` 中的插件行是否正确
3. 确保您运行的是最新版本的 OpenCode

### Windows install issues

某些 Windows OpenCode 版本存在 git 支持的上游安装程序问题
插件规范，包括 `git+https` URL 的缓存路径和 Bun 未找到
`git.exe` 即使它在普通终端中工作。如果 OpenCode 无法安装
插件，尝试使用系统 npm 安装并将 OpenCode 指向本地
package:

```powershell
npm install superpowers@git+https://github.com/obra/superpowers.git --prefix "$HOME\.config\opencode"
```

然后使用`opencode.json`中安装的包路径：

```json
{
  "plugin": ["~/.config/opencode/node_modules/superpowers"]
}
```

### Skills not found

1. 使用 OpenCode 的 `skill` 工具列出可用技能
2. 检查插件是否正在加载（见上文）
3. 每个技能都需要一个带有有效 YAML frontmatter 的 `SKILL.md` 文件

### Bootstrap not appearing

1. 检查 OpenCode 版本支持 `experimental.chat.messages.transform` 钩子
2. 配置更改后重新启动 OpenCode

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Main documentation: https://github.com/obra/superpowers
- OpenCode docs: https://opencode.ai/docs/
