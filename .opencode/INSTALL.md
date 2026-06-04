# Installing Superpowers for OpenCode

## Prerequisites

- 已安装 [OpenCode.ai](https://opencode.ai)

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

## 从旧的 symlink-based install 迁移

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

使用 OpenCode 原生 `skill` tool：

```
use skill tool to list skills
use skill tool to load superpowers/brainstorming
```

## Updating

OpenCode 通过 git-backed package spec 安装 Superpowers。一些 OpenCode 和 Bun 版本会在 lockfile 或 cache 中 pin 已解析的 git dependency，所以重启可能无法拿到最新 Superpowers commit。如果 updates 没出现，请清理 OpenCode package cache 或重新安装 plugin。

要 pin 到特定版本：

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```

## Troubleshooting

### Plugin not loading

1. 检查 logs：`opencode run --print-logs "hello" 2>&1 | grep -i superpowers`
2. 验证 `opencode.json` 中的 plugin line
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

1. 使用 `skill` tool 列出 discovered 内容
2. 检查 plugin 是否正在 loading（见上方）

### Tool mapping

当 skills 引用 Claude Code tools 时：
- `TodoWrite` → `todowrite`
- `Task` with subagents → `@mention` syntax
- `Skill` tool → OpenCode 原生 `skill` tool
- File operations → 你的 native tools

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Full documentation: https://github.com/obra/superpowers/blob/main/docs/README.opencode.md
