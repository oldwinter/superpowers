# Visual Brainstorming Refactor: Browser Displays, Terminal Commands

**Date:** 2026-02-19
**Status:** Approved
**Scope:** `lib/brainstorm-server/`, `skills/brainstorming/visual-companion.md`, `tests/brainstorm-server/`

## Problem

在 visual brainstorming 期间，Claude 会把 `wait-for-feedback.sh` 作为 background task 运行，并阻塞在 `TaskOutput(block=true, timeout=600s)`。这会完全占用 TUI，导致 visual brainstorming 运行时用户无法在 Claude 中输入。browser 变成唯一 input channel。

Claude Code 的 execution model 是 turn-based。单个 turn 中，Claude 无法同时监听两个 channels。blocking `TaskOutput` pattern 是错误的 primitive：它模拟了平台并不支持的 event-driven behavior。

## Design

### Core Model

**Browser = interactive display.** 显示 mockups，让用户 click 选择 options。Selections 记录在 server-side。

**Terminal = conversation channel.** 始终 unblocked，始终可用。用户在这里与 Claude 对话。

### The Loop

1. Claude 将 HTML file 写入 session directory
2. Server 通过 chokidar 检测到它，并向 browser push WebSocket reload（不变）
3. Claude 结束当前 turn，告诉用户查看 browser 并在 terminal 中回复
4. 用户查看 browser，可选地 click 选择 option，然后在 terminal 中输入 feedback
5. 下一 turn，Claude 读取 `$SCREEN_DIR/.events` 获取 browser interaction stream（clicks、selections），并与 terminal text 合并
6. Iterate or advance

不需要 background tasks。不需要 `TaskOutput` blocking。不需要 polling scripts。

### Key Deletion: `wait-for-feedback.sh`

完全删除。它的用途是在 “server logs events to stdout” 与 “Claude needs to receive those events” 之间搭桥。`.events` file 替代了它：server 会直接写入 user interaction events，Claude 用平台提供的任意 file-reading mechanism 读取它们。

### Key Addition: `.events` File (Per-Screen Event Stream)

Server 将所有 user interaction events 写到 `$SCREEN_DIR/.events`，每行一个 JSON object。这为 Claude 提供当前 screen 的完整 interaction stream：不只是 final selection，还包括用户的 exploration path（clicked A, then B, settled on C）。

用户探索 options 后的示例内容：

```jsonl
{"type":"click","choice":"a","text":"Option A - Preset-First Wizard","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Manual Config","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Hybrid Approach","timestamp":1706000115}
```

- 在同一个 screen 内 append-only。每个 user event 会作为新行 appended。
- 当 chokidar 检测到新的 HTML file（new screen pushed）时，该 file 会被 cleared（deleted），防止 stale events carry over。
- 如果 Claude 读取时 file 不存在，说明没有发生 browser interaction；Claude 只使用 terminal text。
- file 只包含 user events（`click` 等），不包含 server lifecycle events（`server-started`、`screen-added`）。这能保持内容小而聚焦。
- Claude 可以读取 full stream 理解用户的 exploration pattern，也可以只看最后一个 `choice` event 作为 final selection。

## Changes by File

### `index.js` (server)

**A. 将 user events 写入 `.events` file。**

在 WebSocket `message` handler 中，事件 log 到 stdout 后：通过 `fs.appendFileSync` 将事件作为 JSON line append 到 `$SCREEN_DIR/.events`。只写入 user interaction events（带 `source: 'user-event'` 的事件），不写 server lifecycle events。

**B. 新 screen 时清空 `.events`。**

在 chokidar `add` handler（检测到新的 `.html` file）中，如果 `$SCREEN_DIR/.events` 存在则删除。这是权威的 “new screen” signal，比在每次 reload 都会触发的 GET `/` 上清空更好。

**C. 替换 `wrapInFrame` content injection。**

当前 regex anchor 在 `<div class="feedback-footer">`，而该元素将被移除。改为 comment placeholder：移除 `#claude-content` 中现有 default content（`<h2>Visual Brainstorming</h2>` 和 subtitle paragraph），替换为单个 `<!-- CONTENT -->` marker。Content injection 变为 `frameTemplate.replace('<!-- CONTENT -->', content)`。更简单，也不会因 template formatting changes 而破裂。

### `frame-template.html` (UI frame)

**Remove:**
- `feedback-footer` div（textarea、Send button、label、`.feedback-row`）
- 相关 CSS（`.feedback-footer`、`.feedback-footer label`、`.feedback-row`、其中的 textarea 和 button styles）

**Add:**
- 在 `#claude-content` 中加入 `<!-- CONTENT -->` placeholder，替换 default text
- 在原 footer 位置加入 selection indicator bar，包含两种状态：
  - Default: "Click an option above, then return to the terminal"
  - After selection: "Option B selected — return to terminal to continue"
- indicator bar CSS（subtle，visual weight 与现有 header 类似）

**Keep unchanged:**
- Header bar with "Brainstorm Companion" title and connection status
- `.main` wrapper and `#claude-content` container
- 所有 component CSS（`.options`、`.cards`、`.mockup`、`.split`、`.pros-cons`、placeholders、mock elements）
- Dark/light theme variables and media query

### `helper.js` (client-side script)

**Remove:**
- `sendToClaude()` function 和 “Sent to Claude” page takeover
- `window.send()` function（它绑定到已移除的 Send button）
- Form submission handler：没有 feedback textarea 后无用途，且会增加 log noise
- Input change handler：同理
- `pageshow` event listener（此前用于修复 textarea persistence；现在没有 textarea）

**Keep:**
- WebSocket connection、reconnect logic、event queue
- Reload handler（server push 时 `window.location.reload()`）
- `window.toggleSelect()` 用于 selection highlighting
- `window.selectedChoice` tracking
- `window.brainstorm.send()` 和 `window.brainstorm.choice()`：它们与移除的 `window.send()` 不同。它们调用 `sendEvent`，通过 WebSocket log 到 server。对 custom full-document pages 有用。

**Narrow:**
- Click handler：只 capture `[data-choice]` clicks，不再 capture all buttons/links。之前 browser 作为 feedback channel 时需要 broad capture；现在只用于 selection tracking。

**Add:**
- `data-choice` click 时，更新 selection indicator bar text，显示选中的 option。

**Remove from `window.brainstorm` API:**
- `brainstorm.sendToClaude`：不再存在。

### `visual-companion.md` (skill instructions)

**Rewrite "The Loop" section** 为上面描述的 non-blocking flow。移除所有对以下内容的 references：
- `wait-for-feedback.sh`
- `TaskOutput` blocking
- Timeout/retry logic（600s timeout、30-minute cap）
- 描述 `send-to-claude` JSON 的 "User Feedback Format" section

**Replace with:**
- 新 loop（write HTML → end turn → user responds in terminal → read `.events` → iterate）
- `.events` file format documentation
- Guidance：terminal message 是 primary feedback；`.events` 提供完整 browser interaction stream，作为 additional context

**Keep:**
- Server startup/shutdown instructions
- Content fragment vs full document guidance
- CSS class reference and available components
- Design tips（按问题调整 fidelity、每屏 2-4 options 等）

### `wait-for-feedback.sh`

**Deleted entirely.**

### `tests/brainstorm-server/server.test.js`

需要更新的 tests：
- 断言 fragment responses 中存在 `feedback-footer` 的 test：改为断言 selection indicator bar 或 `<!-- CONTENT -->` replacement
- 断言 `helper.js` 包含 `send` 的 test：改为反映 narrowed API
- 断言 `sendToClaude` CSS variable usage 的 test：移除（function 不再存在）

## Platform Compatibility

Server code（`index.js`、`helper.js`、`frame-template.html`）完全 platform-agnostic：纯 Node.js 和 browser JavaScript。没有 Claude Code-specific references。通过 background terminal interaction 已证明可在 Codex 上工作。

Skill instructions（`visual-companion.md`）是 platform-adaptive layer。每个平台上的 Claude 使用自己的 tools 启动 server、读取 `.events` 等。non-blocking model 可自然跨平台工作，因为它不依赖任何 platform-specific blocking primitive。

## What This Enables

- **TUI always responsive** during visual brainstorming
- **Mixed input**：在 browser 中 click + 在 terminal 中输入，并自然合并
- **Graceful degradation**：browser down 或用户未打开？terminal 仍可工作
- **Simpler architecture**：无 background tasks、无 polling scripts、无 timeout management
- **Cross-platform**：同一 server code 适用于 Claude Code、Codex 和未来任意 platform

## What This Drops

- **Pure-browser feedback workflow**：用户必须回到 terminal 才能继续。selection indicator bar 会引导他们，但相比旧的 click-Send-and-wait flow 多一步。
- **Inline text feedback from browser**：textarea 已移除。所有 text feedback 都走 terminal。这是有意为之：terminal 是比 frame 中小 textarea 更好的 text input channel。
- **Immediate response on browser Send**：旧系统会在用户点击 Send 的瞬间让 Claude 响应。现在用户切到 terminal 期间会有间隔。实践中只是几秒，且用户可以在 terminal message 中补充 context。
