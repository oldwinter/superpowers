# Testing Superpowers

Superpowers 有两种不同类型的测试，每种测试都在自己的目录中：

- **`tests/`** — 插件的非 LLM 代码可以工作吗？ Bash + Node + Python 集成测试，用于头脑风暴服务器 JS、OpenCode 插件加载、codex 插件同步和分析实用程序。
- **`evals/`** — 代理在真实的 LLM 会话中行为是否正确？ Python 利用驱动 Claude Code / Codex / Gemini CLI 的真实 tmux 会话，并由 LLM 参与者和验证者判断技能合规性。

## Plugin tests

住在`tests/`。目前：

- `tests/brainstorm-server/` — 头脑风暴服务器 JS 代码的节点测试套件。
- `tests/opencode/` — OpenCode 插件加载、引导缓存和工具注册的 bash 测试。
- `tests/codex-plugin-sync/` — bash 同步验证。
- `tests/kimi/` — bash/Python 检查 Kimi 插件清单接线。
- `tests/claude-code/test-helpers.sh`, `analyze-token-usage.py` — 其余 bash 测试使用的实用程序。
- `tests/claude-code/test-subagent-driven-development.sh` — 代理可以描述 SDD 测试（无演练对应项；测试描述回忆，而不是行为）。
- `tests/claude-code/test-subagent-driven-development-integration.sh` — 扩展 SDD 与令牌分析集成（练习涵盖 YAGNI 子集；bash 添加提交计数、Claude Code 任务跟踪和令牌遥测断言）。
- `tests/claude-code/test-worktree-native-preference.sh` — 工作树技能的红绿重构验证（练习涵盖压力阶段；bash 还涵盖红/GREEN 基线）。
- `tests/explicit-skill-requests/` — 俳句特定的、多轮的、技能名称提示的测试，不包括在练习中。

通过相关目录的 `run-*.sh` 或 `npm test` 运行插件测试。

## Skill behavior evals

住在`evals/`。钻头就是吊带；场景位于`evals/scenarios/*.yaml`。请参阅`evals/README.md`进行设置。快速启动：

```bash
cd evals
uv sync --extra dev
export ANTHROPIC_API_KEY=sk-...
uv run drill run triggering-test-driven-development -b claude
```

演练场景很慢（每个场景 3-30 分钟以上），并且运行真正的 LLM 课程。如今，它们已不再是 CI 的一部分；自然的后续是分层模型（PR 的快速子集、每晚全面扫描 + 点播）。
