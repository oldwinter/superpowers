# Visual Companion Guide

基于 browser 的 visual brainstorming companion，用于展示 mockups、diagrams 和 options。

## 何时使用

按每个 question 决定，而不是按整个 session 决定。判断标准：**用户看到它是否会比读到它更容易理解？**

**Use the browser** 当 content 本身是 visual：

- **UI mockups** — wireframes、layouts、navigation structures、component designs
- **Architecture diagrams** — system components、data flow、relationship maps
- **Side-by-side visual comparisons** — 比较两个 layouts、两个 color schemes、两个 design directions
- **Design polish** — 问题涉及 look and feel、spacing、visual hierarchy
- **Spatial relationships** — 渲染成 diagrams 的 state machines、flowcharts、entity relationships

**Use the terminal** 当 content 是 text 或 tabular：

- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
- **Conceptual A/B/C choices** — 在用文字描述的 approaches 之间选择
- **Tradeoff lists** — pros/cons、comparison tables
- **Technical decisions** — API design、data modeling、architectural approach selection
- **Clarifying questions** — 任何答案是文字而不是 visual preference 的问题

关于 UI topic 的问题不自动等于 visual question。"What kind of wizard do you want?" 是 conceptual，用 terminal。"Which of these wizard layouts feels right?" 是 visual，用 browser。

## 工作方式

Server 会 watch 一个 directory 中的 HTML files，并把最新文件 serve 给 browser。你把 HTML content 写到 `screen_dir`，用户在 browser 中看到它并可以点击选择 options。Selections 会记录到 `state_dir/events`，你在下一轮读取。

**Content fragments vs full documents:** 如果 HTML file 以 `<!DOCTYPE` 或 `<html` 开头，server 会原样 serve（只注入 helper script）。否则 server 会自动用 frame template 包裹 content：添加 header、CSS theme、selection indicator 和所有 interactive infrastructure。**默认写 content fragments。** 只有需要完整控制 page 时才写 full documents。

## Starting a Session

```bash
# Start server with persistence (mockups saved to project)
scripts/start-server.sh --project-dir /path/to/project

# Returns: {"type":"server-started","port":52341,"url":"http://localhost:52341",
#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
```

保存 response 中的 `screen_dir` 和 `state_dir`。告诉用户打开 URL。

**Finding connection info:** Server 会把 startup JSON 写到 `$STATE_DIR/server-info`。如果你在后台启动 server 且没有捕获 stdout，读取该文件获取 URL 和 port。使用 `--project-dir` 时，在 `<project>/.superpowers/brainstorm/` 中查找 session directory。

**Note:** 把 project root 作为 `--project-dir` 传入，这样 mockups 会持久化到 `.superpowers/brainstorm/` 并能在 server restarts 后保留。不传时，files 会进入 `/tmp` 并被清理。如果 `.superpowers/` 还没有加入 `.gitignore`，提醒用户添加。

**Launching the server by platform:**

**Claude Code (macOS / Linux):**
```bash
# Default mode works — the script backgrounds the server itself
scripts/start-server.sh --project-dir /path/to/project
```

**Claude Code (Windows):**
```bash
# Windows auto-detects and uses foreground mode, which blocks the tool call.
# Use run_in_background: true on the Bash tool call so the server survives
# across conversation turns.
scripts/start-server.sh --project-dir /path/to/project
```
通过 Bash tool 调用时，设置 `run_in_background: true`。下一轮读取 `$STATE_DIR/server-info` 获取 URL 和 port。

**Codex:**
```bash
# Codex reaps background processes. The script auto-detects CODEX_CI and
# switches to foreground mode. Run it normally — no extra flags needed.
scripts/start-server.sh --project-dir /path/to/project
```

**Gemini CLI:**
```bash
# Use --foreground and set is_background: true on your shell tool call
# so the process survives across turns
scripts/start-server.sh --project-dir /path/to/project --foreground
```

**Other environments:** Server 必须跨 conversation turns 持续在后台运行。如果你的 environment 会 reap detached processes，使用 `--foreground`，并通过平台的 background execution mechanism 启动 command。

如果 URL 无法从 browser 访问（remote/containerized setups 常见），绑定 non-loopback host：

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

使用 `--url-host` 控制 returned URL JSON 中打印的 hostname。

## The Loop

1. **Check server is alive**，然后把 **HTML 写入** `screen_dir` 中的新文件：
   - 每次写入前，检查 `$STATE_DIR/server-info` 是否存在。如果不存在（或 `$STATE_DIR/server-stopped` 存在），server 已 shut down：继续前用 `start-server.sh` 重启。Server 会在 30 分钟 inactivity 后 auto-exit。
   - 使用 semantic filenames：`platform.html`、`visual-style.html`、`layout.html`
   - **永远不要 reuse filenames**：每个 screen 都用 fresh file
   - 使用 Write tool，**不要用 cat/heredoc**（会把噪音 dump 到 terminal）
   - Server 自动 serve 最新 file

2. **告诉用户会看到什么，然后结束你的 turn：**
   - 提醒他们 URL（每一步都提醒，不只第一次）
   - 简短总结 screen 内容（例如 "Showing 3 layout options for the homepage"）
   - 请他们在 terminal 回应："Take a look and let me know what you think. Click to select an option if you'd like."

3. **下一轮** — 用户在 terminal 回应后：
   - 如果 `$STATE_DIR/events` 存在，读取它。它包含用户 browser interactions（clicks、selections）的 JSON lines
   - 将其与用户 terminal text 合并，获得完整 picture
   - Terminal message 是 primary feedback；`state_dir/events` 提供 structured interaction data

4. **Iterate or advance** — 如果 feedback 改变当前 screen，写新文件（例如 `layout-v2.html`）。只有当前 step 被 validated 后才进入下一个问题。

5. **Unload when returning to terminal** — 当下一步不需要 browser（例如 clarifying question、tradeoff discussion）时，push 一个 waiting screen 清掉 stale content：

   ```html
   <!-- filename: waiting.html (or waiting-2.html, etc.) -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">Continuing in terminal...</p>
   </div>
   ```

   这能防止用户在 conversation 已继续时还盯着已解决的选择。当下一个 visual question 出现时，照常 push 新 content file。

6. 重复直到完成。

## Writing Content Fragments

只写 page 内部 content。Server 会自动用 frame template 包裹它（header、theme CSS、selection indicator 和所有 interactive infrastructure）。

**Minimal example:**

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and visual hierarchy</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Single Column</h3>
      <p>Clean, focused reading experience</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>Two Column</h3>
      <p>Sidebar navigation with main content</p>
    </div>
  </div>
</div>
```

就这些。不需要 `<html>`、CSS 或 `<script>` tags。Server 会提供所有内容。

## CSS Classes Available

Frame template 为你的 content 提供这些 CSS classes：

### Options (A/B/C choices)

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Title</h3>
      <p>Description</p>
    </div>
  </div>
</div>
```

**Multi-select:** 给 container 添加 `data-multiselect`，让用户选择多个 options。每次点击都会 toggle item。Indicator bar 会显示 count。

```html
<div class="options" data-multiselect>
  <!-- same option markup — users can select/deselect multiple -->
</div>
```

### Cards (visual designs)

```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- mockup content --></div>
    <div class="card-body">
      <h3>Name</h3>
      <p>Description</p>
    </div>
  </div>
</div>
```

### Mockup container

```html
<div class="mockup">
  <div class="mockup-header">Preview: Dashboard Layout</div>
  <div class="mockup-body"><!-- your mockup HTML --></div>
</div>
```

### Split view (side-by-side)

```html
<div class="split">
  <div class="mockup"><!-- left --></div>
  <div class="mockup"><!-- right --></div>
</div>
```

### Pros/Cons

```html
<div class="pros-cons">
  <div class="pros"><h4>Pros</h4><ul><li>Benefit</li></ul></div>
  <div class="cons"><h4>Cons</h4><ul><li>Drawback</li></ul></div>
</div>
```

### Mock elements (wireframe building blocks)

```html
<div class="mock-nav">Logo | Home | About | Contact</div>
<div style="display: flex;">
  <div class="mock-sidebar">Navigation</div>
  <div class="mock-content">Main content area</div>
</div>
<button class="mock-button">Action Button</button>
<input class="mock-input" placeholder="Input field">
<div class="placeholder">Placeholder area</div>
```

### Typography and sections

- `h2` — page title
- `h3` — section heading
- `.subtitle` — title 下方的 secondary text
- `.section` — 带 bottom margin 的 content block
- `.label` — small uppercase label text

## Browser Events Format

当用户在 browser 中点击 options 时，他们的 interactions 会记录到 `$STATE_DIR/events`（每行一个 JSON object）。当你 push 新 screen 时，该文件会自动 clear。

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Complex Grid","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

完整 event stream 会显示用户的 exploration path：他们可能在确定前点击多个 options。最后一个 `choice` event 通常是最终 selection，但 click pattern 也能显示 hesitation 或值得追问的 preferences。

如果 `$STATE_DIR/events` 不存在，说明用户没有和 browser 互动：只使用他们的 terminal text。

## Design Tips

- **Scale fidelity to the question** — layout 问题用 wireframes，polish 问题用更精细 mockup
- **Explain the question on each page** — 写 "Which layout feels more professional?"，不要只写 "Pick one"
- **Iterate before advancing** — 如果 feedback 改变当前 screen，写新版本
- **2-4 options max** per screen
- **Use real content when it matters** — photography portfolio 用实际 images（Unsplash）。Placeholder content 会遮蔽 design issues。
- **Keep mockups simple** — 聚焦 layout 和 structure，不追求 pixel-perfect design

## File Naming

- 使用 semantic names：`platform.html`、`visual-style.html`、`layout.html`
- 永远不要 reuse filenames：每个 screen 必须是 new file
- Iterations：追加 version suffix，例如 `layout-v2.html`、`layout-v3.html`
- Server 按 modification time serve 最新 file

## Cleaning Up

```bash
scripts/stop-server.sh $SESSION_DIR
```

如果 session 使用了 `--project-dir`，mockup files 会保留在 `.superpowers/brainstorm/` 供以后参考。只有 `/tmp` sessions 会在 stop 时删除。

## Reference

- Frame template（CSS reference）：`scripts/frame-template.html`
- Helper script（client-side）：`scripts/helper.js`
