# Cross-Platform Polyglot Hooks for Claude Code

Claude Code 插件需要适用于 Windows、macOS 和 Linux 的挂钩。本文档描述了 `hooks/run-hook.cmd` 中使用的单一通用调度程序模式。

> **权威来源：** `hooks/run-hook.cmd` 是规范的实现。当本文档和代码不一致时，请相信代码。

## The Problem

Claude Code 通过 shell 运行 hook 命令：
- **macOS/Linux**：bash 或 sh
- **已安装 Git Bash 的 Windows**：Git Bash
- **未安装 Git Bash 的 Windows**：PowerShell（较旧版本使用 CMD.exe）

两种 Windows fallback shell 都无法解析我们的命令字符串：PowerShell 会把开头带引号的路径当成字符串表达式，并在下一个裸词处报错；CMD.exe 的 `/c` 引号规则则会在路径包含 `(` 等元字符时剥掉外层引号。因此 hooks 显式声明 `"shell": "bash"`（Claude Code 2.1.81 起支持，旧版本会忽略该 key），强制走 Git Bash；未安装 Git Bash 时，会显示可操作的“安装 Git for Windows”错误，而不是 shell parser failure。

这带来了几个挑战：

1. **脚本执行**：Windows CMD无法直接执行`.sh`文件
2. **路径格式**：Windows 使用反斜杠 (`C:\path`)，Unix 使用正斜杠 (`/path`)
3. **环境变量**：`$VAR` 语法在 CMD 中不起作用
4. **`.sh` 自动前缀**：Windows 上的 Claude Code 自动在路径中包含 `.sh` 的任何命令前面添加 `bash` — 如果脚本具有扩展名，这会干扰调度程序

## 解决方案：无扩展脚本 + 单一通用调度程序

该存储库对所有挂钩使用一个通用的 `run-hook.cmd` 调度程序。挂钩脚本是**无扩展**（`session-start`，而不是`session-start.sh`）。这是故意的：它可以防止 Claude Code 的 Windows 自动检测将 `bash` 添加到调度程序命令中并破坏它。

### File Structure

```
hooks/
├── hooks.json          # Points to run-hook.cmd with extensionless script name
├── run-hook.cmd        # Cross-platform dispatcher (the polyglot wrapper)
└── session-start       # Actual hook logic — extensionless bash script
```

### hooks.json

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "powershell": "& \"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "shell": "bash",
            "async": false
          }
        ]
      }
    ]
  }
}
```

该路径被引用是因为 `${CLAUDE_PLUGIN_ROOT}` 可能包含空格。

### The `powershell` key

Windows 上的 GitHub Copilot（CLI 和 VS Code）无论 `shell` key 是什么，
都会通过 PowerShell 运行 hook 命令（#2189）。在 PowerShell 中，前置的
带引号路径会被解析为字符串表达式，末尾的裸词会报错
（"Unexpected token 'session-start'"）。存在 `powershell` key 时，
Copilot 会使用它而不是 `command`，并用 `&` 调用运算符执行同样的分发。
Claude Code 会忽略该 key。

## `run-hook.cmd` 如何在高层次上工作

`run-hook.cmd` 是一个多语言脚本：Windows 将第一个块视为批处理
命令，而 Unix shell 将该块视为无操作定界符并继续
after it.

不要复制本文档的实现。阅读`hooks/run-hook.cmd`
直接更改调度程序时，然后运行 `tests/hooks/test-session-start.sh`
afterward.

### 它在 Windows 上的工作原理 (CMD.exe)

1. 批处理部分验证脚本名称并解析挂钩目录
   从调度员自己的位置。
2. 它按顺序在四个地方尝试 bash：
   - `C:\Program Files\Git\bin\bash.exe`
   - `C:\Program Files (x86)\Git\bin\bash.exe`
   - `%LOCALAPPDATA%\Programs\Git\bin\bash.exe`（按用户安装的
     Git for Windows），仅在设置了 `LOCALAPPDATA` 时尝试
   - `PATH` 上的 `bash`（MSYS2、Cygwin 或非默认 Git 安装），通过运行
     `%SystemRoot%\System32\where.exe $PATH:bash` 查找，因此 `where`
     和 `bash` 都不会从当前目录获取。WSL 启动器（`System32`、
     `Sysnative` 或 `%LOCALAPPDATA%\Microsoft\WindowsApps` 中的
     `bash.exe`）和无扩展名匹配会被跳过，因为未安装 Linux 发行版时
     这些启动器会失败。
3. 如果找到 bash，它会从 hooks 目录运行指定的无扩展名 hook 脚本，
   并以脚本的退出码退出。
4. 如果没有找到 bash，调度程序会静默退出 `0` — 插件
   继续工作，只是跳过 hook。
5. `exit /b` 在 CMD 到达 Unix 部分之前停止它。

### 它如何在 Unix 上工作（bash/sh）

1. `: << 'CMDBLOCK'` 在无操作命令上打开一个定界文档。
2. 整个 CMD 批处理块被定界符消耗并被忽略。
3. 在`CMDBLOCK`之后，bash解析脚本目录并`exec`命名
   直接使用无扩展脚本。

### Key design decisions

|决定|为什么 |
|----------|-----|
|无扩展脚本 |防止 Claude Code 的 Windows `.sh`-自动前置干扰调度程序命令 |
|否 `-l`（登录 shell）|不需要；钩子脚本应该是独立的，不依赖于登录外壳路径设置 |
|没有 `cygpath` | Bash直接接收Windows路径并正确处理；旧的 `-c "..."` 调用模式需要 `cygpath`，而不是直接 exec |
| no-bash 静默退出 |避免为没有 Windows 版 Git 的用户破坏插件；钩子上下文注入被优雅地跳过 |

## Writing Cross-Platform Hook Scripts

您的挂钩逻辑位于无扩展脚本文件中。一些便携式模式：

### Do
- 尽可能使用纯 bash 内置函数
- 使用 `$(command)` 代替反引号
- 引用所有变量扩展：`"$VAR"`

### Avoid
- 依赖于 PATH 相关的工具而没有后备（钩子在没有 `-l` 的情况下运行，因此未设置登录 shell PATH）
- 为脚本提供 `.sh` 扩展名 — 这会触发 Claude Code 的 Windows 自动前置

### Example: JSON escaping without external tools

```bash
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            $'\\') output+='\\' ;;
            '"') output+='\"' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *) output+="$char" ;;
        esac
    done
    printf '%s' "$output"
}
```

## Troubleshooting

### "bash 未被识别"

CMD 在调度程序尝试的四个位置中都找不到 bash。调度程序会静默退出 (0)
而不是报错，因此 hook 被跳过。请安装 Git for Windows（系统级或按用户），
或确保 `PATH` 上有一个非 WSL 的 `bash`。

### Hook runs on Unix but does nothing on Windows

检查 `hooks.json` 中的脚本文件名是否**无扩展名**。像 `run-hook.cmd session-start.sh` 这样的命令可以触发 Claude Code 的 `.sh` 自动检测并绕过预期的 CMD 调度程序路径，或者只是尝试运行不存在的 `session-start.sh` 脚本。

### 钩子根本不开火

验证 `hooks.json` 中的 `matcher` 是否与你的 harness 发出的事件类型匹配。Claude Code 使用 `startup|clear|compact`；Cursor 使用 `sessionStart`。Cursor 变体见 `hooks-cursor.json`。

## Related Issues

- [anthropics/claude-code#9758](https://github.com/anthropics/claude-code/issues/9758) — `.sh` 脚本在 Windows 上的编辑器中打开
- [anthropics/claude-code#3417](https://github.com/anthropics/claude-code/issues/3417) — 挂钩在 Windows 上不起作用
