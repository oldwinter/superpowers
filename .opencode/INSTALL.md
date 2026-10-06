# Installing Superpowers for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

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

对于本地 V2 安装，请配置包含 `index.js` 的仓库目录。OpenCode 2.0.4 和
2.0.7 会拒绝直接配置 JavaScript 文件路径；自动发现的 plugin 符号链接仍受支持。

重启 OpenCode。V2 使用 `opencode` 命令；`opencode2` 可能作为别名提供。
该 plugin 通过 OpenCode 的 plugin manager 安装，并注册所有 skills。

通过询问来验证："告诉我你的超能力"

OpenCode 使用自己的插件安装。如果您还使用 Claude Code、Codex 或
另一种安全带，为每个安全带单独安装 Superpowers。

## Migrating from the old symlink-based install

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

使用 OpenCode 的原生 `skill` 工具：

```
use skill tool to list skills
use skill tool to load brainstorming
```

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

## Troubleshooting

### Plugin not loading

1. 检查日志。V1：`opencode run --print-logs "hello" 2>&1 | grep -i superpowers`。
   V2 在后台 server 中加载 plugins，因此需添加 `--standalone`：
   `opencode run --standalone --print-logs "hello" 2>&1 | grep -i superpowers`,
   或检查 `~/.local/share/opencode/log/opencode.log` 并筛选 `role=server`。
2. 验证 `opencode.json` 中的 plugin 配置行。
3. 确保运行的是较新版本的 OpenCode。

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

1. 使用 `skill` 工具列出发现的内容
2. 检查插件是否正在加载（见上文）

### Tool mapping

Skills 用动作表达（“创建 todo”、“派遣 subagent”、“读取文件”）。Plugin 会注入针对版本的映射，请确认所用 OpenCode 版本：

**V1 (`opencode` 1.x):**

- "创建待办事项"/"在待办事项列表中标记完成"→ `todowrite`
- `Subagent (general-purpose):` 模板 → `task` 工具和 `subagent_type: "general"` （或 `"explore"` 用于代码库探索）
- "调用技能" → OpenCode 原生的`skill`工具
- "读取文件"→`read`
- "创建文件"/"编辑文件"/"删除文件"→ `apply_patch`
- "运行 shell 命令"→ `bash`
- "搜索文件内容"/"按名称查找文件"→ `grep`, `glob`
- "获取 URL"→ `webfetch`

**V2 (`opencode` 2.0.4 or later; `opencode2` may be available as an alias):**

- “创建 todo” → V2 没有 todo 工具；改为在 Markdown 文件中跟踪计划
- `Subagent (general-purpose):` 模板 → 使用 `agent: "general"`（或 `"explore"`）的 `subagent` 工具；传入 `sessionID` 以继续之前的 subagent
- “调用 skill” → OpenCode 原生 `skill` 工具
- “读取文件” → `read`
- “创建、编辑或删除文件” → 可用时使用带 `patchText` 的 `patch`；否则使用 `write` 创建或覆盖文件、`edit` 定点修改、`shell` 删除
- “运行 shell 命令” → `shell`（`command`、`workdir`、`timeout`、`background`）
- “搜索文件内容”/“按名称查找文件” → `grep`、`glob`
- “获取 URL” → `webfetch`
- “搜索 web” → `websearch`

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Full documentation: https://github.com/obra/superpowers/blob/main/docs/README.opencode.md
