# Superpowers for OpenCode

这是一份在 [OpenCode.ai](https://opencode.ai) 中使用 Superpowers 的完整指南。

## Installation

把 superpowers 添加到你的 `opencode.json`（global 或 project-level）的 `plugin` array：

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

重启 OpenCode。Plugin 会通过 OpenCode 的 plugin manager 安装，并注册所有 skills。

通过提问验证："Tell me about your superpowers"

OpenCode 使用自己的 plugin install。即使你也使用 Claude Code、Codex 或其他 harness，也需要为每个 harness 单独安装 Superpowers。

### 从旧的 symlink-based install 迁移

如果你之前用 `git clone` 和 symlinks 安装过 superpowers，请移除旧 setup：

```bash
# Remove old symlinks
rm -f ~/.config/opencode/plugins/superpowers.js
rm -rf ~/.config/opencode/skills/superpowers

# Optionally remove the cloned repo
rm -rf ~/.config/opencode/superpowers

# Remove skills.paths from opencode.json if you added one for superpowers
```

然后按上面的 installation steps 操作。

## Usage

### Finding Skills

使用 OpenCode 原生 `skill` tool 列出所有 available skills：

```
use skill tool to list skills
```

### Loading a Skill

```
use skill tool to load superpowers/brainstorming
```

### Personal Skills

在 `~/.config/opencode/skills/` 中创建自己的 skills：

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

创建 `~/.config/opencode/skills/my-skill/SKILL.md`：

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

### Project Skills

在项目内的 `.opencode/skills/` 中创建 project-specific skills。

**Skill Priority:** Project skills > Personal skills > Superpowers skills

## Updating

OpenCode 通过 git-backed package spec 安装 Superpowers。一些 OpenCode 和 Bun 版本会在 lockfile 或 cache 中 pin 已解析的 git dependency，所以重启可能无法拿到最新 Superpowers commit。如果 updates 没出现，请清理 OpenCode package cache 或重新安装 plugin。

要 pin 到特定版本，请使用 branch 或 tag：

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```

## How It Works

Plugin 做两件事：

1. 通过 `experimental.chat.system.transform` hook **注入 bootstrap context**，把 superpowers awareness 添加到每个 conversation。
2. 通过 `config` hook **注册 skills directory**，让 OpenCode 无需 symlinks 或手动 config 即可发现所有 superpowers skills。

### Tool Mapping

为 Claude Code 编写的 skills 会自动适配 OpenCode：

- `TodoWrite` → `todowrite`
- `Task` with subagents → OpenCode 的 `@mention` system
- `Skill` tool → OpenCode 原生 `skill` tool
- File operations → Native OpenCode tools

## Troubleshooting

### Plugin not loading

1. 检查 OpenCode logs：`opencode run --print-logs "hello" 2>&1 | grep -i superpowers`
2. 验证 `opencode.json` 中的 plugin line 正确
3. 确保你运行的是较新的 OpenCode 版本

### Windows install issues

一些 Windows OpenCode builds 在 git-backed plugin specs 上有 upstream installer issues，包括 `git+https` URLs 的 cache paths，以及 Bun 在普通 terminal 能找到 `git.exe` 时仍找不到它。如果 OpenCode 无法安装 plugin，尝试用 system npm 安装，并让 OpenCode 指向 local package：

```powershell
npm install superpowers@git+https://github.com/obra/superpowers.git --prefix "$HOME\.config\opencode"
```

然后在 `opencode.json` 中使用 installed package path：

```json
{
  "plugin": ["~/.config/opencode/node_modules/superpowers"]
}
```

### Skills not found

1. 使用 OpenCode 的 `skill` tool 列出 available skills
2. 检查 plugin 是否正在 loading（见上方）
3. 每个 skill 都需要包含 valid YAML frontmatter 的 `SKILL.md` file

### Bootstrap not appearing

1. 检查 OpenCode version 是否支持 `experimental.chat.system.transform` hook
2. Config changes 后重启 OpenCode

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Main documentation: https://github.com/obra/superpowers
- OpenCode docs: https://opencode.ai/docs/
