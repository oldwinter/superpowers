# Claude Code Skills Tests

使用 Claude Code CLI 自动测试超能力技能。

## Overview

该测试套件验证技能是否正确加载，并且 Claude 按预期遵循它们。测试在无头模式 (`claude -p`) 下调用 Claude Code 并验证行为。

## Requirements

- Claude Code CLI 已安装并位于 PATH 中（`claude --version` 应该可以工作）
- 安装本地超级大国插件（安装请参阅主要自述文件）

## Running Tests

### 运行所有快速测试（推荐）：
```bash
./run-skill-tests.sh
```

### 运行集成测试（缓慢，10-30 分钟）：
```bash
./run-skill-tests.sh --integration
```

### Run specific test:
```bash
./run-skill-tests.sh --test test-subagent-driven-development.sh
```

### Run with verbose output:
```bash
./run-skill-tests.sh --verbose
```

### Set custom timeout:
```bash
./run-skill-tests.sh --timeout 1800  # 30 minutes for integration tests
```

## Test Structure

### test-helpers.sh
技能测试常用功能：
- `run_claude "prompt" [timeout]` - 在提示符下运行克劳德
- `assert_contains output pattern name` - 验证模式是否存在
- `assert_not_contains output pattern name` - 验证模式不存在
- `assert_count output pattern count name` - 验证准确计数
- `assert_order output pattern_a pattern_b name` - 验证订单
- `create_test_project` - 创建临时测试目录
- `create_test_plan project_dir` - 创建示例计划文件

### Test Files

每个测试文件：
1. Sources `test-helpers.sh`
2. 使用特定提示运行 Claude Code
3. 使用断言验证预期行为
4. 成功时返回 0，失败时返回非零

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

### 快速测试（默认运行）

#### test-subagent-driven-development.sh
测试技能内容和要求（约 2 分钟）：
- 技能负载和可访问性
- 工作流程排序（规范合规性优先于代码质量）
- 记录自我审查要求
- 记录计划阅读效率
- 规范合规审查员的怀疑记录在案
- 审查记录的循环
- 记录任务上下文规定

### 集成测试（使用--integration标志）

#### test-subagent-driven-development-integration.sh
完整工作流程执行测试（约 10-30 分钟）：
- 使用 Node.js 设置创建真实的测试项目
- 创建包含 2 项任务的实施计划
- 使用子代理驱动开发执行计划
- 验证实际行为：
  - 计划在开始时阅读一次（不是每个任务）
  - 子代理提示中提供完整的任务文本
  - 下级代理在报告前进行自我审查
  - 规范合规性审查发生在代码质量之前
  - 规范审阅者独立阅读代码
  - 工作实施已产生
  - Tests pass
  - 创建正确的 git 提交

**测试什么：**
- 工作流程实际上是端到端的
- 我们的改进已实际应用
- 子代理正确遵循技能
- 最终代码可以正常运行并经过测试

#### test-worktree-native-preference.sh
对 using-git-worktrees 技能进行 RED-GREEN-REFACTOR 验证（约 5 分钟）：
- 红色：没有步骤 1a 的技能 — 代理应使用 `git worktree add`
- 绿色：步骤 1a 的技能 — 代理应使用本机 EnterWorktree 工具
- 压力：与紧急框架下的绿色相同，且具有预先存在的 `.worktrees/`
- 演练场景`worktree-creation-under-pressure.yaml`仅涵盖压力阶段

## Adding New Tests

1. 创建新的测试文件：`test-<skill-name>.sh`
2. Source test-helpers.sh
3. 使用 `run_claude` 和断言编写测试
4. 添加到`run-skill-tests.sh`中的测试列表
5. 使可执行文件：`chmod +x test-<skill-name>.sh`

## Timeout Considerations

- 默认超时：每次测试 5 分钟
- 克劳德·科德 可能需要一些时间才能回复
- 如果需要，用 `--timeout` 进行调整
- 测试应集中于避免长时间运行

## Debugging Failed Tests

使用 `--verbose`，您将看到完整的 Claude 输出：
```bash
./run-skill-tests.sh --verbose --test test-subagent-driven-development.sh
```

如果没有详细信息，则仅显示失败的输出。

## CI/CD Integration

在 CI 中运行：
```bash
# Run with explicit timeout for CI environments
./run-skill-tests.sh --timeout 900

# Exit code 0 = success, non-zero = failure
```

## Notes

- 测试验证技能*指令*，而不是完全执行
- 完整的工作流程测试会非常慢
- 专注于验证关键技能要求
- 测试应该是确定性的
- 避免测试实施细节
