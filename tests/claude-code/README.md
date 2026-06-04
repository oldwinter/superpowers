# Claude Code Skills Tests

使用 Claude Code CLI 为 superpowers skills 编写的 automated tests。

## 概览

这个 test suite 验证 skills 是否正确加载，以及 Claude 是否按预期遵循它们。Tests 会以 headless mode（`claude -p`）调用 Claude Code，并验证 behavior。

## Requirements

- 已安装 Claude Code CLI，且在 PATH 中（`claude --version` 应可运行）
- 已安装 local superpowers plugin（安装方式见 main README）

## Running Tests

### Run all fast tests（recommended）：
```bash
./run-skill-tests.sh
```

### Run integration tests（slow, 10-30 minutes）：
```bash
./run-skill-tests.sh --integration
```

### Run specific test：
```bash
./run-skill-tests.sh --test test-subagent-driven-development.sh
```

### Run with verbose output：
```bash
./run-skill-tests.sh --verbose
```

### Set custom timeout：
```bash
./run-skill-tests.sh --timeout 1800  # 30 minutes for integration tests
```

## Test Structure

### test-helpers.sh
Skills testing 的 common functions：
- `run_claude "prompt" [timeout]` - 用 prompt 运行 Claude
- `assert_contains output pattern name` - 验证 pattern 存在
- `assert_not_contains output pattern name` - 验证 pattern 不存在
- `assert_count output pattern count name` - 验证 exact count
- `assert_order output pattern_a pattern_b name` - 验证 order
- `create_test_project` - 创建 temp test directory
- `create_test_plan project_dir` - 创建 sample plan file

### Test Files

每个 test file：
1. Sources `test-helpers.sh`
2. 用 specific prompts 运行 Claude Code
3. 使用 assertions 验证 expected behavior
4. 成功返回 0，失败返回 non-zero

## Example Test

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: My Skill ==="

# Ask Claude about the skill
output=$(run_claude "What does the my-skill skill do?" 30)

# Verify response
assert_contains "$output" "expected behavior" "Skill describes behavior"

echo "=== All tests passed ==="
```

## Current Tests

### Fast Tests（default 运行）

#### test-subagent-driven-development.sh
测试 skill content 和 requirements（约 2 分钟）：
- Skill loading and accessibility
- Workflow ordering（spec compliance before code quality）
- Self-review requirements documented
- Plan reading efficiency documented
- Spec compliance reviewer skepticism documented
- Review loops documented
- Task context provision documented

### Integration Tests（使用 --integration flag）

#### test-subagent-driven-development-integration.sh
完整 workflow execution test（约 10-30 分钟）：
- 创建真实 test project 和 Node.js setup
- 创建包含 2 个 tasks 的 implementation plan
- 使用 subagent-driven-development 执行 plan
- 验证实际 behaviors：
  - Plan 在开始时 read once（不是每个 task 都读）
  - Full task text 提供给 subagent prompts
  - Subagents report 前执行 self-review
  - Spec compliance review 先于 code quality
  - Spec reviewer 独立读取 code
  - 产出 working implementation
  - Tests pass
  - 创建 proper git commits

**What it tests:**
- Workflow 真的 end-to-end 工作
- 我们的 improvements 真的被应用
- Subagents 正确遵循 skill
- Final code functional and tested

#### test-requesting-code-review.sh
Code reviewer subagent 的 behavioral test（约 5 分钟）：
- 构建一个 tiny project 和 baseline commit
- 添加 second commit，植入两个真实 bugs（SQL injection、plaintext password handling）
- 通过 requesting-code-review skill dispatch code reviewer
- 验证 reviewer 以 Critical/Important severity 标记 planted bugs，并拒绝 approve

**What it tests:**
- Skill 真的 dispatch 一个 working code reviewer subagent
- Reviewer template 能产生抓住明显 security bugs 的 reviewers
- Reviewer 不 sycophantic：它不会 approve 带 planted Critical issues 的 diff

## Adding New Tests

1. 创建 new test file：`test-<skill-name>.sh`
2. Source test-helpers.sh
3. 使用 `run_claude` 和 assertions 编写 tests
4. 添加到 `run-skill-tests.sh` 的 test list
5. Make executable：`chmod +x test-<skill-name>.sh`

## Timeout Considerations

- Default timeout: 每个 test 5 分钟
- Claude Code 可能需要时间响应
- 如有需要，用 `--timeout` 调整
- Tests 应保持 focused，避免 long runs

## Debugging Failed Tests

使用 `--verbose` 会看到完整 Claude output：
```bash
./run-skill-tests.sh --verbose --test test-subagent-driven-development.sh
```

不使用 verbose 时，只有 failures 显示 output。

## CI/CD Integration

在 CI 中运行：
```bash
# Run with explicit timeout for CI environments
./run-skill-tests.sh --timeout 900

# Exit code 0 = success, non-zero = failure
```

## Notes

- Tests 验证 skill *instructions*，不是 full execution
- Full workflow tests 会非常慢
- 聚焦验证 key skill requirements
- Tests 应该 deterministic
- 避免测试 implementation details
