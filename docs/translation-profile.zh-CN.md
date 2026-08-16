# Superpowers 中文本地化档案

同步上游后，先读本档案，再处理新增或变更的中文内容。

## 项目定位

- 上游项目：`https://github.com/obra/superpowers`
- 中文 fork：`https://github.com/oldwinter/superpowers`
- 主要安装面：Codex plugin marketplace
- 目标用户：希望在 coding agent 中直接使用中文 Superpowers 工作流的开发者
- 用户安装后实际读取的入口文件：`skills/**/SKILL.md`、`hooks/` 与各 harness 的启动集成
- 不应宣传为中文版安装的入口：官方 marketplace、`obra/superpowers` URL 和上游 release
- 当前同步上游 commit：`b36e0829c6d0140e93cfef2ca599b1b07d4a7797`

## 本地化目标

本 fork 是可安装的中文发行版。安装后，agent 实际执行的 skill 与启动引导必须为中文，同时保留上游经过验证的行为塑造、安全边界和工作流顺序。

## 语气

- 使用直接、明确的中文，保留上游对 agent 行为的约束强度。
- 保留 agent、skill、plugin、workflow、prompt、runtime、TDD、YAGNI、DRY 等常用技术词。
- 操作步骤先给可执行命令，再解释结果。
- 不弱化 `MUST`、`NEVER`、红旗列表或停止条件。

## 术语表

| 英文 | 中文 | 备注 |
|---|---|---|
| skill | skill | Agent Skills 语境下保留英文小写 |
| agent | agent | 指 coding agent 时保留英文 |
| plugin | plugin | manifest 与命令语境保留英文 |
| workflow | 工作流 | 命令名或文件名中保留英文 |
| runtime | runtime | 指安装后实际加载内容 |
| upstream | 上游 | 指 `obra/superpowers` |
| fork | fork | GitHub fork 语境下保留英文 |

## 不翻译清单

- 命令、参数、环境变量、URL、文件路径、包名、plugin 名和 skill slug。
- YAML/JSON key、frontmatter 字段名、hook event 与 harness 协议字段。
- 测试 fixture、golden string、正则和执行器依赖的精确字符串。
- 代码块中的示例程序；只翻译周围说明。

## README 中文安装区块

README 顶部必须说明这是社区维护 fork、当前同步 commit，以及 Codex marketplace 命令。中文版安装命令必须指向 `oldwinter/superpowers`，并说明官方 marketplace 和上游 URL 不属于本中文版。

## 同步后检查

- `git diff --check`
- 精确冲突标记扫描：`rg -n '^(<<<<<<< .+|=======|>>>>>>> .+)$' .`
- README 中文安装命令指向 `oldwinter/superpowers`。
- Codex plugin manifest 仍指向 `skills/`，中文 skill runtime 可以被发现。
- 新增英文用户文案已中文化，执行敏感字符串未被误翻。
- 运行仓库的 plugin 基础设施测试。

## 项目特殊规则

- Skill 内容会塑造 agent 行为，不能为了行文顺滑而改变流程顺序、触发条件或禁止项。
- 上游官方安装说明可保留用于对照，但必须与中文版安装入口清楚区分。
- 新 harness 支持必须同时验证 session-start 引导会自动加载 `using-superpowers`。
