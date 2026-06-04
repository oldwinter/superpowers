# Cross-Platform Polyglot Hooks for Claude Code

Claude Code plugins 需要能在 Windows、macOS 和 Linux 上工作的 hooks。本文解释让它可行的 polyglot wrapper technique。

## 问题

Claude Code 通过系统默认 shell 运行 hook commands：
- **Windows**: CMD.exe
- **macOS/Linux**: bash or sh

这会带来几个挑战：

1. **Script execution**: Windows CMD 不能直接执行 `.sh` files，它会尝试用 text editor 打开
2. **Path format**: Windows 使用 backslashes（`C:\path`），Unix 使用 forward slashes（`/path`）
3. **Environment variables**: `$VAR` syntax 在 CMD 中不工作
4. **No `bash` in PATH**: 即使安装了 Git Bash，CMD 运行时 `bash` 也不在 PATH 中

## 解决方案：Polyglot `.cmd` Wrapper

Polyglot script 是能同时作为多种语言 valid syntax 的脚本。我们的 wrapper 同时适用于 CMD 和 bash：

```cmd
: << 'CMDBLOCK'
@echo off
"C:\Program Files\Git\bin\bash.exe" -l -c "\"$(cygpath -u \"$CLAUDE_PLUGIN_ROOT\")/hooks/session-start.sh\""
exit /b
CMDBLOCK

# Unix shell runs from here
"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
```

### How It Works

#### On Windows (CMD.exe)

1. `: << 'CMDBLOCK'` - CMD 把 `:` 视为 label（类似 `:label`），并忽略 `<< 'CMDBLOCK'`
2. `@echo off` - 抑制 command echoing
3. bash.exe command 运行时带：
   - `-l`（login shell）以获得包含 Unix utilities 的 proper PATH
   - `cygpath -u` 把 Windows path 转成 Unix format（`C:\foo` → `/c/foo`）
4. `exit /b` - 退出 batch script，让 CMD 停在这里
5. `CMDBLOCK` 之后的内容 CMD 永远不会到达

#### On Unix (bash/sh)

1. `: << 'CMDBLOCK'` - `:` 是 no-op，`<< 'CMDBLOCK'` 开始 heredoc
2. 直到 `CMDBLOCK` 的所有内容都被 heredoc 消耗（ignored）
3. `# Unix shell runs from here` - Comment
4. Script 用 Unix path 直接运行

## File Structure

```
hooks/
├── hooks.json           # Points to the .cmd wrapper
├── session-start.cmd    # Polyglot wrapper (cross-platform entry point)
└── session-start.sh     # Actual hook logic (bash script)
```

### hooks.json

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.cmd\""
          }
        ]
      }
    ]
  }
}
```

Note: Path 必须 quote，因为 `${CLAUDE_PLUGIN_ROOT}` 在 Windows 上可能包含 spaces（例如 `C:\Program Files\...`）。

## Requirements

### Windows
- 必须安装 **Git for Windows**（提供 `bash.exe` 和 `cygpath`）
- 默认安装路径：`C:\Program Files\Git\bin\bash.exe`
- 如果 Git 安装在其他位置，需要修改 wrapper

### Unix (macOS/Linux)
- 标准 bash 或 sh shell
- `.cmd` file 必须有 execute permission（`chmod +x`）

## Writing Cross-Platform Hook Scripts

实际 hook logic 放在 `.sh` file 中。为了确保它在 Windows 上（通过 Git Bash）工作：

### Do:
- 尽可能使用 pure bash builtins
- 使用 `$(command)` 而不是 backticks
- Quote 所有 variable expansions：`"$VAR"`
- 使用 `printf` 或 here-docs 输出

### Avoid:
- 可能不在 PATH 中的 external commands（sed、awk、grep）
- 如果必须使用，它们在 Git Bash 中可用，但要确保 PATH setup 正确（使用 `bash -l`）

### Example: JSON Escaping Without sed/awk

不要这样：
```bash
escaped=$(echo "$content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
```

使用 pure bash：
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

## Reusable Wrapper Pattern

对于有多个 hooks 的 plugins，可以创建 generic wrapper，把 script name 作为 argument：

### run-hook.cmd
```cmd
: << 'CMDBLOCK'
@echo off
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=%~1"
"C:\Program Files\Git\bin\bash.exe" -l -c "cd \"$(cygpath -u \"%SCRIPT_DIR%\")\" && \"./%SCRIPT_NAME%\""
exit /b
CMDBLOCK

# Unix shell runs from here
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
"${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

### hooks.json using the reusable wrapper
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" validate-bash.sh"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

### "bash is not recognized"
CMD 找不到 bash。Wrapper 使用完整路径 `C:\Program Files\Git\bin\bash.exe`。如果 Git 安装在其他位置，更新该 path。

### "cygpath: command not found" or "dirname: command not found"
Bash 没有作为 login shell 运行。确保使用 `-l` flag。

### Path has weird `\/` in it
`${CLAUDE_PLUGIN_ROOT}` expanded 成以 backslash 结尾的 Windows path，然后又追加了 `/hooks/...`。使用 `cygpath` 转换整个 path。

### Script opens in text editor instead of running
hooks.json 直接指向 `.sh` file。改为指向 `.cmd` wrapper。

### Works in terminal but not as hook
Claude Code 可能以不同方式运行 hooks。通过模拟 hook environment 测试：
```powershell
$env:CLAUDE_PLUGIN_ROOT = "C:\path\to\plugin"
cmd /c "C:\path\to\plugin\hooks\session-start.cmd"
```

## Related Issues

- [anthropics/claude-code#9758](https://github.com/anthropics/claude-code/issues/9758) - .sh scripts open in editor on Windows
- [anthropics/claude-code#3417](https://github.com/anthropics/claude-code/issues/3417) - Hooks don't work on Windows
- [anthropics/claude-code#6023](https://github.com/anthropics/claude-code/issues/6023) - CLAUDE_PROJECT_DIR not found
