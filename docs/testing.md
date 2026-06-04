# Testing Superpowers Skills

本文描述如何测试 Superpowers skills，尤其是像 `subagent-driven-development` 这类复杂 skills 的 integration tests。

## 概览

测试涉及 subagents、workflows 和复杂 interactions 的 skills，需要在 headless mode 中运行真实 Claude Code sessions，并通过 session transcripts 验证它们的 behavior。

## Test Structure

```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── test-subagent-driven-development-integration.sh
│   ├── analyze-token-usage.py             # Token analysis tool
│   └── run-skill-tests.sh                 # Test runner (if exists)
```

## Running Tests

### Integration Tests

Integration tests 会使用真实 skills 执行真实 Claude Code sessions：

```bash
# Run the subagent-driven-development integration test
cd tests/claude-code
./test-subagent-driven-development-integration.sh
```

**Note:** Integration tests 可能需要 10-30 分钟，因为它们会用多个 subagents 执行真实 implementation plans。

### Requirements

- 必须从 **superpowers plugin directory** 运行（不要从 temp directories 运行）
- 必须安装 Claude Code，并且 `claude` command 可用
- 必须启用 local dev marketplace：`~/.claude/settings.json` 中有 `"superpowers@superpowers-dev": true`

## Integration Test: subagent-driven-development

### What It Tests

Integration test 会验证 `subagent-driven-development` skill 正确做到：

1. **Plan Loading**：开始时只读取一次 plan
2. **Full Task Text**：向 subagents 提供完整 task descriptions（不让它们读 files）
3. **Self-Review**：确保 subagents 在 report 前执行 self-review
4. **Review Order**：先运行 spec compliance review，再运行 code quality review
5. **Review Loops**：发现 issues 时使用 review loops
6. **Independent Verification**：Spec reviewer 独立读取 code，不信任 implementer reports

### How It Works

1. **Setup**：创建带 minimal implementation plan 的临时 Node.js project
2. **Execution**：用该 skill 在 headless mode 运行 Claude Code
3. **Verification**：解析 session transcript（`.jsonl` file）以验证：
   - Skill tool 被调用
   - Subagents 被 dispatch（Task tool）
   - TodoWrite 用于 tracking
   - Implementation files 被创建
   - Tests pass
   - Git commits 展示 proper workflow
4. **Token Analysis**：按 subagent 展示 token usage breakdown

### Test Output

```
========================================
 Integration Test: subagent-driven-development
========================================

Test project: /tmp/tmp.xyz123

=== Verification Tests ===

Test 1: Skill tool invoked...
  [PASS] subagent-driven-development skill was invoked

Test 2: Subagents dispatched...
  [PASS] 7 subagents dispatched

Test 3: Task tracking...
  [PASS] TodoWrite used 5 time(s)

Test 6: Implementation verification...
  [PASS] src/math.js created
  [PASS] add function exists
  [PASS] multiply function exists
  [PASS] test/math.test.js created
  [PASS] Tests pass

Test 7: Git commit history...
  [PASS] Multiple commits created (3 total)

Test 8: No extra features added...
  [PASS] No extra features added

=========================================
 Token Usage Analysis
=========================================

Usage Breakdown:
----------------------------------------------------------------------------------------------------
Agent           Description                          Msgs      Input     Output      Cache     Cost
----------------------------------------------------------------------------------------------------
main            Main session (coordinator)             34         27      3,996  1,213,703 $   4.09
3380c209        implementing Task 1: Create Add Function     1          2        787     24,989 $   0.09
34b00fde        implementing Task 2: Create Multiply Function     1          4        644     25,114 $   0.09
3801a732        reviewing whether an implementation matches...   1          5        703     25,742 $   0.09
4c142934        doing a final code review...                    1          6        854     25,319 $   0.09
5f017a42        a code reviewer. Review Task 2...               1          6        504     22,949 $   0.08
a6b7fbe4        a code reviewer. Review Task 1...               1          6        515     22,534 $   0.08
f15837c0        reviewing whether an implementation matches...   1          6        416     22,485 $   0.07
----------------------------------------------------------------------------------------------------

TOTALS:
  Total messages:         41
  Input tokens:           62
  Output tokens:          8,419
  Cache creation tokens:  132,742
  Cache read tokens:      1,382,835

  Total input (incl cache): 1,515,639
  Total tokens:             1,524,058

  Estimated cost: $4.67
  (at $3/$15 per M tokens for input/output)

========================================
 Test Summary
========================================

STATUS: PASSED
```

## Token Analysis Tool

### Usage

分析任意 Claude Code session 的 token usage：

```bash
python3 tests/claude-code/analyze-token-usage.py ~/.claude/projects/<project-dir>/<session-id>.jsonl
```

### Finding Session Files

Session transcripts 存储在 `~/.claude/projects/`，working directory path 会被编码：

```bash
# Example for /Users/yourname/Documents/GitHub/superpowers/superpowers
SESSION_DIR="$HOME/.claude/projects/-Users-yourname-Documents-GitHub-superpowers-superpowers"

# Find recent sessions
ls -lt "$SESSION_DIR"/*.jsonl | head -5
```

### What It Shows

- **Main session usage**：Coordinator（你或 main Claude instance）的 token usage
- **Per-subagent breakdown**：每个 Task invocation 包含：
  - Agent ID
  - Description（从 prompt 提取）
  - Message count
  - Input/output tokens
  - Cache usage
  - Estimated cost
- **Totals**：Overall token usage 和 cost estimate

### Understanding the Output

- **High cache reads**：好事，表示 prompt caching 正常工作
- **High input tokens on main**：预期行为，coordinator 有 full context
- **Similar costs per subagent**：预期行为，每个 subagent 拿到类似 task complexity
- **Cost per task**：典型范围是每个 subagent $0.05-$0.15，取决于 task

## Troubleshooting

### Skills Not Loading

**Problem**：运行 headless tests 时找不到 skill

**Solutions**：
1. 确保你从 superpowers directory 运行：`cd /path/to/superpowers && tests/...`
2. 检查 `~/.claude/settings.json` 的 `enabledPlugins` 中有 `"superpowers@superpowers-dev": true`
3. 验证 skill 存在于 `skills/` directory

### Permission Errors

**Problem**：Claude 被阻止写 files 或访问 directories

**Solutions**：
1. 使用 `--permission-mode bypassPermissions` flag
2. 使用 `--add-dir /path/to/temp/dir` 授予 test directories 访问权限
3. 检查 test directories 的 file permissions

### Test Timeouts

**Problem**：Test 耗时过长并 timeout

**Solutions**：
1. 增加 timeout：`timeout 1800 claude ...`（30 分钟）
2. 检查 skill logic 中是否有 infinite loops
3. Review subagent task complexity

### Session File Not Found

**Problem**：Test run 后找不到 session transcript

**Solutions**：
1. 检查 `~/.claude/projects/` 中正确的 project directory
2. 使用 `find ~/.claude/projects -name "*.jsonl" -mmin -60` 查找 recent sessions
3. 验证 test 确实运行了（检查 test output 中的 errors）

## Writing New Integration Tests

### Template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Create test project
TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project $TEST_PROJECT" EXIT

# Set up test files...
cd "$TEST_PROJECT"

# Run Claude with skill
PROMPT="Your test prompt here"
cd "$SCRIPT_DIR/../.." && timeout 1800 claude -p "$PROMPT" \
  --allowed-tools=all \
  --add-dir "$TEST_PROJECT" \
  --permission-mode bypassPermissions \
  2>&1 | tee output.txt

# Find and analyze session
WORKING_DIR_ESCAPED=$(echo "$SCRIPT_DIR/../.." | sed 's/\\//-/g' | sed 's/^-//')
SESSION_DIR="$HOME/.claude/projects/$WORKING_DIR_ESCAPED"
SESSION_FILE=$(find "$SESSION_DIR" -name "*.jsonl" -type f -mmin -60 | sort -r | head -1)

# Verify behavior by parsing session transcript
if grep -q '"name":"Skill".*"skill":"your-skill-name"' "$SESSION_FILE"; then
    echo "[PASS] Skill was invoked"
fi

# Show token analysis
python3 "$SCRIPT_DIR/analyze-token-usage.py" "$SESSION_FILE"
```

### Best Practices

1. **Always cleanup**：使用 trap 清理 temp directories
2. **Parse transcripts**：不要 grep user-facing output，要解析 `.jsonl` session file
3. **Grant permissions**：使用 `--permission-mode bypassPermissions` 和 `--add-dir`
4. **Run from plugin dir**：只有从 superpowers directory 运行时，skills 才会加载
5. **Show token usage**：始终包含 token analysis，方便看 cost
6. **Test real behavior**：验证实际 files created、tests passing、commits made

## Session Transcript Format

Session transcripts 是 JSONL（JSON Lines）files，每一行都是代表 message 或 tool result 的 JSON object。

### Key Fields

```json
{
  "type": "assistant",
  "message": {
    "content": [...],
    "usage": {
      "input_tokens": 27,
      "output_tokens": 3996,
      "cache_read_input_tokens": 1213703
    }
  }
}
```

### Tool Results

```json
{
  "type": "user",
  "toolUseResult": {
    "agentId": "3380c209",
    "usage": {
      "input_tokens": 2,
      "output_tokens": 787,
      "cache_read_input_tokens": 24989
    },
    "prompt": "You are implementing Task 1...",
    "content": [{"type": "text", "text": "..."}]
  }
}
```

`agentId` field 会关联到 subagent sessions，`usage` field 包含该 specific subagent invocation 的 token usage。
