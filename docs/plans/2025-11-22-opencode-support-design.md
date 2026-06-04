# OpenCode Support Design

**Date:** 2025-11-22
**Author:** Bot & Jesse
**Status:** Design Complete, Awaiting Implementation

## Overview

使用 native OpenCode plugin architecture 为 OpenCode.ai 添加完整 superpowers support，同时与现有 Codex implementation 共享 core functionality。

## Background

OpenCode.ai 是类似 Claude Code 和 Codex 的 coding agent。之前将 superpowers port 到 OpenCode 的尝试（PR #93、PR #116）使用 file-copying approaches。本 design 采用不同方式：使用 OpenCode 的 JavaScript/TypeScript plugin system 构建 native OpenCode plugin，同时与 Codex implementation 共享代码。

### Key Differences Between Platforms

- **Claude Code**：Native Anthropic plugin system + file-based skills
- **Codex**：No plugin system → bootstrap markdown + CLI script
- **OpenCode**：JavaScript/TypeScript plugins，带 event hooks 和 custom tools API

### OpenCode's Agent System

- **Primary agents**：Build（default，full access）和 Plan（restricted，read-only）
- **Subagents**：General（research、searching、multi-step tasks）
- **Invocation**：由 primary agents automatic dispatch，或使用 manual `@mention` syntax
- **Configuration**：custom agents 位于 `opencode.json` 或 `~/.config/opencode/agent/`

## Architecture

### High-Level Structure

1. **Shared Core Module** (`lib/skills-core.js`)
   - Common skill discovery and parsing logic
   - 由 Codex 和 OpenCode implementations 共同使用

2. **Platform-Specific Wrappers**
   - Codex：CLI script（`.codex/superpowers-codex`）
   - OpenCode：Plugin module（`.opencode/plugin/superpowers.js`）

3. **Skill Directories**
   - Core：`~/.config/opencode/superpowers/skills/`（或 installed location）
   - Personal：`~/.config/opencode/skills/`（shadows core skills）

### Code Reuse Strategy

从 `.codex/superpowers-codex` 中 extract common functionality 到 shared module：

```javascript
// lib/skills-core.js
module.exports = {
  extractFrontmatter(filePath),      // Parse name + description from YAML
  findSkillsInDir(dir, maxDepth),    // Recursive SKILL.md discovery
  findAllSkills(dirs),                // Scan multiple directories
  resolveSkillPath(skillName, dirs), // Handle shadowing (personal > core)
  checkForUpdates(repoDir)           // Git fetch/status check
};
```

### Skill Frontmatter Format

当前 format（没有 `when_to_use` field）：

```yaml
---
name: skill-name
description: Use when [condition] - [what it does]; [additional context]
---
```

## OpenCode Plugin Implementation

### Custom Tools

**Tool 1: `use_skill`**

将特定 skill 的 content 加载进 conversation（相当于 Claude 的 Skill tool）。

```javascript
{
  name: 'use_skill',
  description: 'Load and read a specific skill to guide your work',
  schema: z.object({
    skill_name: z.string().describe('Name of skill (e.g., "superpowers:brainstorming")')
  }),
  execute: async ({ skill_name }) => {
    const { skillPath, content, frontmatter } = resolveAndReadSkill(skill_name);
    const skillDir = path.dirname(skillPath);

    return `# ${frontmatter.name}
# ${frontmatter.description}
# Supporting tools and docs are in ${skillDir}
# ============================================

${content}`;
  }
}
```

**Tool 2: `find_skills`**

列出所有可用 skills 及其 metadata。

```javascript
{
  name: 'find_skills',
  description: 'List all available skills',
  schema: z.object({}),
  execute: async () => {
    const skills = discoverAllSkills();
    return skills.map(s =>
      `${s.namespace}:${s.name}
  ${s.description}
  Directory: ${s.directory}
`).join('\n');
  }
}
```

### Session Startup Hook

新 session starts（`session.started` event）时：

1. **Inject using-superpowers content**
   - using-superpowers skill 的 full content
   - 建立 mandatory workflows

2. **Run find_skills automatically**
   - upfront 显示所有 available skills 的完整 list
   - 为每个 skill 包含 skill directories

3. **Inject tool mapping instructions**
   ```markdown
   **Tool Mapping for OpenCode:**
   When skills reference tools you don't have, substitute:
   - `TodoWrite` → `update_plan`
   - `Task` with subagents → Use OpenCode subagent system (@mention)
   - `Skill` tool → `use_skill` custom tool
   - Read, Write, Edit, Bash → Your native equivalents

   **Skill directories contain:**
   - Supporting scripts (run with bash)
   - Additional documentation (read with read tool)
   - Utilities specific to that skill
   ```

4. **Check for updates**（non-blocking）
   - 带 timeout 的 quick git fetch
   - 如果 updates available 则 notify

### Plugin Structure

```javascript
// .opencode/plugin/superpowers.js
const skillsCore = require('../../lib/skills-core');
const path = require('path');
const fs = require('fs');
const { z } = require('zod');

export const SuperpowersPlugin = async ({ client, directory, $ }) => {
  const superpowersDir = path.join(process.env.HOME, '.config/opencode/superpowers');
  const personalDir = path.join(process.env.HOME, '.config/opencode/skills');

  return {
    'session.started': async () => {
      const usingSuperpowers = await readSkill('using-superpowers');
      const skillsList = await findAllSkills();
      const toolMapping = getToolMappingInstructions();

      return {
        context: `${usingSuperpowers}\n\n${skillsList}\n\n${toolMapping}`
      };
    },

    tools: [
      {
        name: 'use_skill',
        description: 'Load and read a specific skill',
        schema: z.object({
          skill_name: z.string()
        }),
        execute: async ({ skill_name }) => {
          // Implementation using skillsCore
        }
      },
      {
        name: 'find_skills',
        description: 'List all available skills',
        schema: z.object({}),
        execute: async () => {
          // Implementation using skillsCore
        }
      }
    ]
  };
};
```

## File Structure

```
superpowers/
├── lib/
│   └── skills-core.js           # NEW: Shared skill logic
├── .codex/
│   ├── superpowers-codex        # UPDATED: Use skills-core
│   ├── superpowers-bootstrap.md
│   └── INSTALL.md
├── .opencode/
│   ├── plugin/
│   │   └── superpowers.js       # NEW: OpenCode plugin
│   └── INSTALL.md               # NEW: Installation guide
└── skills/                       # Unchanged
```

## Implementation Plan

### Phase 1: Refactor Shared Core

1. Create `lib/skills-core.js`
   - Extract frontmatter parsing from `.codex/superpowers-codex`
   - Extract skill discovery logic
   - Extract path resolution（with shadowing）
   - Update to use only `name` and `description`（no `when_to_use`）

2. Update `.codex/superpowers-codex` to use shared core
   - Import from `../lib/skills-core.js`
   - Remove duplicated code
   - Keep CLI wrapper logic

3. Test Codex implementation still works
   - Verify bootstrap command
   - Verify use-skill command
   - Verify find-skills command

### Phase 2: Build OpenCode Plugin

1. Create `.opencode/plugin/superpowers.js`
   - Import shared core from `../../lib/skills-core.js`
   - Implement plugin function
   - Define custom tools（use_skill、find_skills）
   - Implement session.started hook

2. Create `.opencode/INSTALL.md`
   - Installation instructions
   - Directory setup
   - Configuration guidance

3. Test OpenCode implementation
   - Verify session startup bootstrap
   - Verify use_skill tool works
   - Verify find_skills tool works
   - Verify skill directories are accessible

### Phase 3: Documentation & Polish

1. Update README with OpenCode support
2. Add OpenCode installation to main docs
3. Update RELEASE-NOTES
4. Test both Codex and OpenCode work correctly

## Next Steps

1. **Create isolated workspace**（using git worktrees）
   - Branch：`feature/opencode-support`

2. **Follow TDD where applicable**
   - Test shared core functions
   - Test skill discovery and parsing
   - Integration tests for both platforms

3. **Incremental implementation**
   - Phase 1：Refactor shared core + update Codex
   - Verify Codex still works before moving on
   - Phase 2：Build OpenCode plugin
   - Phase 3：Documentation and polish

4. **Testing strategy**
   - Manual testing with real OpenCode installation
   - Verify skill loading、directories、scripts work
   - Test both Codex and OpenCode side-by-side
   - Verify tool mappings work correctly

5. **PR and merge**
   - Create PR with complete implementation
   - Test in clean environment
   - Merge to main

## Benefits

- **Code reuse**：skill discovery/parsing 的 single source of truth
- **Maintainability**：bug fixes 同时适用于两个 platforms
- **Extensibility**：未来 platforms（Cursor、Windsurf 等）容易添加
- **Native integration**：正确使用 OpenCode plugin system
- **Consistency**：跨 platforms 获得同样的 skill experience
