# Visual Companion Guide

基于浏览器的视觉头脑风暴伴侣，用于显示模型、图表和选项。

## When to Use

根据每个问题而不是每个会话来决定。测试：**用户通过查看它会比阅读它更好地理解它吗？**

**当内容本身是可视的时使用浏览器**：

- **UI 模型** — 线框、布局、导航结构、组件设计
- **架构图** — 系统组件、数据流、关系图
- **并排视觉比较** — 比较两种布局、两种配色方案、两种设计方向
- **设计完善**——当问题涉及外观和感觉、间距、视觉层次时
- **空间关系** — 状态机、流程图、呈现为图表的实体关系

**当内容是文本或表格时使用终端**：

- **需求和范围问题** - "X 是什么意思？"，"哪些功能在范围内？"
- **概念性 A/B/C 选择** — 在文字描述的方法之间进行选择
- **权衡列表** — 优点/cons，比较表
- **技术决策** — API 设计、数据建模、架构方法选择
- **澄清问题**——答案是文字的任何事情，而不是视觉偏好

*关于* UI 主题的问题不会自动成为视觉问题。 "你想要什么样的巫师？"是概念性的——使用终端。 "这些巫师布局中哪一个感觉正确？"是视觉的——使用浏览器。

## How It Works

服务器监视 HTML 文件的目录并向浏览器提供最新的文件。您将 HTML 内容写入 `screen_dir`，用户在浏览器中看到它并可以单击以选择选项。选择将记录到您在下一回合读取的`state_dir/events`。

**内容片段与完整文档：** 如果您的 HTML 文件以 `<!DOCTYPE` 或 `<html` 开头，服务器将按原样提供该文件（仅注入帮助程序脚本）。否则，服务器会自动将您的内容包装在框架模板中 - 添加标题、CSS 主题、连接状态和所有交互式基础设施。 **默认写入内容片段。** 仅当您需要完全控制页面时才写入完整文档。

## Starting a Session

```bash
# Start AFTER the user approves the companion. --open auto-opens their browser on
# the first screen; --project-dir persists mockups and enables same-port restart.
scripts/start-server.sh --project-dir /path/to/project --open

# Returns: {"type":"server-started","port":52341,
#           "url":"http://localhost:52341/?key=ab12…",
#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
```

从响应中保存 `screen_dir` 和 `state_dir`。使用 `--open`，当您按下第一个屏幕时，浏览器会自行打开 - 您不需要要求用户打开它，但仍然共享 URL 作为后备（无头/remote 设置不会自动打开）。

**URL 包含会话密钥 (`?key=…`)。** 服务器拒绝任何请求
如果没有它，请始终为用户提供来自 `url` 字段的 **完整** URL —
永远不要剥离查询字符串，也永远不要分发裸露的`http://host:port`。的
密钥门 HTTP 和 WebSocket 访问，因此流浪浏览器选项卡或另一台机器上
网络无法读取屏幕或注入事件。第一次加载后
浏览器通过 cookie 记住密钥，因此重新加载和 `/files/*` 资产可以工作
无需重复。

**查找连接信息：** 服务器将其启动 JSON 写入 `$STATE_DIR/server-info`。如果您在后台启动服务器并且没有捕获标准输出，请读取该文件以获取 URL 和端口。使用 `--project-dir` 时，请检查 `<project>/.superpowers/brainstorm/` 的会话目录。

**注意：** 将项目根目录传递为 `--project-dir`，以便模型保留在 `.superpowers/brainstorm/` 中并在服务器重新启动后继续存在。如果没有它，文件将转到 `/tmp` 并被清理。提醒用户将 `.superpowers/` 添加到 `.gitignore`（如果尚不存在）。

**按平台启动服务器：**

**Claude Code:**
```bash
# Default mode works — the script backgrounds the server itself.
scripts/start-server.sh --project-dir /path/to/project --open
```

在 Windows 上，脚本会自动检测并切换到前台模式（这会阻止工具调用）。在 Bash 工具调用上使用 `run_in_background: true`，以便服务器在会话轮次中存活，然后在下一轮读取 `$STATE_DIR/server-info` 以获取 URL 和端口。

**Codex:**
```bash
# Codex reaps background processes. The script auto-detects CODEX_CI and
# switches to foreground mode. Run it normally — no extra flags needed.
scripts/start-server.sh --project-dir /path/to/project --open
```

**Gemini CLI:**
```bash
# Use --foreground and set is_background: true on your shell tool call
# so the process survives across turns
scripts/start-server.sh --project-dir /path/to/project --open --foreground
```

**Copilot CLI:**
```bash
# Use --foreground and start the server via the bash tool with mode: "async"
# so the process survives across turns. Capture the returned shellId for
# read_bash / stop_bash if you need to interact with it later.
scripts/start-server.sh --project-dir /path/to/project --open --foreground
```

**其他环境：** 服务器必须在对话轮次期间保持在后台运行。如果您的环境获取分离的进程，请使用 `--foreground` 并使用您平台的后台执行机制启动该命令。

如果您的浏览器无法访问该 URL（常见于远程 /containerized 设置），请绑定非环回主机：

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

使用 `--url-host` 控制在返回的 URL JSON 中打印的主机名。

## The Loop

1. **检查服务器是否处于活动状态**，然后**将 HTML** 写入 `screen_dir` 中的新文件：
   - **必需：在引用 URL 或推送屏幕之前确认服务器处于活动状态。** 检查 `$STATE_DIR/server-info` 是否存在，而 `$STATE_DIR/server-stopped` 不存在。如果它已关闭，请使用 **相同​​的 `--project-dir`** 使用 `start-server.sh` 重新启动它 — 它会重用相同的端口，因此用户打开的选项卡会自行重新连接（当服务器关闭时，它会显示"暂停"覆盖），并且您不需要发送新的 URL。服务器闲置 4 小时后自动退出（可使用 `--idle-timeout-minutes` 配置）。
   - 使用语义文件名：`platform.html`、`visual-style.html`、`layout.html`
   - **永远不要重复使用文件名** - 每个屏幕都会获得一个新文件
   - 使用文件创建工具 - **永远不要使用 cat/heredoc** （将噪音转储到终端）
   - 服务器自动提供最新文件

2. **告诉用户会发生什么并结束你的回合：**
   - 提醒他们 URL（每一步，而不仅仅是第一步）
   - 提供屏幕上内容的简短文本摘要（例如，"显示主页的 3 个布局选项"）
   - 让他们在终端中回复："看一下，让我知道您的想法。如果您愿意，请单击选择一个选项。"

3. **在你的下一个回合** - 用户在终端中做出响应后：
   - 读取 `$STATE_DIR/events`（如果存在）——这包含用户的浏览器交互（点击、选择）作为 JSON 行
   - 与用户的终端文本合并以获得完整图片
   - 终端消息是主要反馈； `state_dir/events`提供结构化交互数据

4. **迭代或前进** - 如果反馈更改当前屏幕，则写入新文件（例如，`layout-v2.html`）。仅当当前步骤经过验证后才转到下一个问题。

5. **返回终端时卸载** - 当下一步不需要浏览器时（例如，澄清问题、权衡讨论），推送等待屏幕以清除陈旧内容：

   ```html
   <!-- filename: waiting.html (or waiting-2.html, etc.) -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">Continuing in terminal...</p>
   </div>
   ```

   这可以防止用户在对话继续时盯着已解决的选择。当出现下一个视觉问题时，像往常一样推送新的内容文件。

6. 重复直到完成。

## Writing Content Fragments

仅编写页面内的内容。服务器自动将其包装在框架模板中（标头、主题 CSS、连接状态和所有交互基础设施）。

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

就是这样。不需要 `<html>`，不需要 CSS，不需要 `<script>` 标签。服务器提供了所有这些。

## CSS Classes Available

框架模板为您的内容提供以下 CSS 类：

### 选项（A/B/C选项）

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

**多选：** 将`data-multiselect`添加到容器中，让用户选择多个选项。每次单击都会切换项目的选定样式。

```html
<div class="options" data-multiselect>
  <!-- same option markup — users can select/deselect multiple -->
</div>
```

### 卡片（视觉设计）

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

### 分割视图（并排）

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

### 模拟元素（线框构建块）

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

- `h2` — 页面标题
- `h3` — 节标题
- `.subtitle` — 标题下方的辅助文本
- `.section` — 带下边距的内容块
- `.label` — 小号大写标签文本

## Browser Events Format

当用户单击浏览器中的选项时，他们的交互将记录到 `$STATE_DIR/events` （每行一个 JSON 对象）。当您推入新屏幕时，该文件会自动清除。

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Complex Grid","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

完整的事件流显示了用户的探索路径——他们可能会在解决之前单击多个选项。最后一个 `choice` 事件通常是最终选择，但点击模式可以揭示值得询问的犹豫或偏好。

如果 `$STATE_DIR/events` 不存在，则用户不会与浏览器交互 - 仅使用终端文本。

## Design Tips

- **对问题的保真度** - 布局线框图，润色问题
- **解释每一页上的问题** — "哪种布局感觉更专业？"不只是"选一个"
- **前进之前迭代** - 如果反馈更改当前屏幕，则编写新版本
- **每个屏幕最多 2-4 个选项**
- **重要时使用真实内容** - 对于摄影作品集，请使用实际图像 (Unsplash)。占位符内容掩盖了设计问题。
- **保持模型简单** - 专注于布局和结构，而不是像素完美的设计

## File Naming

- 使用语义名称：`platform.html`、`visual-style.html`、`layout.html`
- 切勿重复使用文件名 - 每个屏幕都必须是一个新文件
- 对于迭代：附加版本后缀，例如 `layout-v2.html`、`layout-v3.html`
- 服务器按修改时间提供最新文件

## Cleaning Up

```bash
scripts/stop-server.sh $SESSION_DIR
```

如果会话使用`--project-dir`，模型文件将保留在`.superpowers/brainstorm/`中以供以后参考。只有 `/tmp` 会话会在停止时被删除。

## Reference

- 框架模板（CSS参考）：`scripts/frame-template.html`
- 帮助程序脚本（客户端）：`scripts/helper.js`
