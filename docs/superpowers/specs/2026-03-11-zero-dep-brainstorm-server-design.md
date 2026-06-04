# Zero-Dependency Brainstorm Server

用单个 zero-dependency `server.js` 替换 brainstorm companion server 的 vendored node_modules（express、ws、chokidar，共 714 个 tracked files），只使用 Node.js built-ins。

## Motivation

将 node_modules vendoring 进 git repo 会造成 supply chain risk：冻结的 dependencies 无法获得 security patches，714 个 third-party code files 未经 audit 就被提交，且对 vendored code 的修改看起来像普通 commits。虽然实际风险较低（localhost-only dev server），但消除它很直接。

## Architecture

单个 `server.js` file（约 250-300 行），使用 `http`、`crypto`、`fs` 和 `path`。该文件承担两个角色：

- **When run directly** (`node server.js`)：启动 HTTP/WebSocket server
- **When required** (`require('./server.js')`)：导出 WebSocket protocol functions 供 unit testing

### WebSocket Protocol

只为 text frames 实现 RFC 6455：

**Handshake:** 使用 SHA-1 + RFC 6455 magic GUID，根据 client 的 `Sec-WebSocket-Key` 计算 `Sec-WebSocket-Accept`。返回 101 Switching Protocols。

**Frame decoding (client to server):** 处理三种 masked length encodings：
- Small: payload < 126 bytes
- Medium: 126-65535 bytes（16-bit extended）
- Large: > 65535 bytes（64-bit extended）

使用 4-byte mask key 对 payload 做 XOR-unmask。返回 `{ opcode, payload, bytesConsumed }`，或在 buffer 不完整时返回 `null`。拒绝 unmasked frames。

**Frame encoding (server to client):** 使用同样三种 length encodings 的 unmasked frames。

**Opcodes handled:** TEXT (0x01)、CLOSE (0x08)、PING (0x09)、PONG (0x0A)。未识别 opcodes 返回 close frame，status 为 1003（Unsupported Data）。

**Deliberately skipped:** Binary frames、fragmented messages、extensions（permessage-deflate）、subprotocols。localhost clients 之间的小型 JSON text messages 不需要这些能力。Extensions 和 subprotocols 在 handshake 中协商；由于不 advertise，它们永远不会 active。

**Buffer accumulation:** 每个 connection 维护一个 buffer。收到 `data` 时 append，并循环 `decodeFrame`，直到返回 null 或 buffer 为空。

### HTTP Server

三条 routes：

1. **`GET /`**：按 mtime 提供 screen directory 中最新 `.html`。检测 full documents vs fragments，wrap fragments in frame template，并 inject helper.js。返回 `text/html`。没有 `.html` files 时，返回硬编码 waiting page（"Waiting for Claude to push a screen..."），并注入 helper.js。
2. **`GET /files/*`**：从 screen directory 提供 static files，MIME type 通过 hardcoded extension map 查找（html、css、js、png、jpg、gif、svg、json）。未找到则返回 404。
3. **Everything else**：404。

WebSocket upgrade 通过 HTTP server 上的 `'upgrade'` event 处理，与 request handler 分离。

### Configuration

Environment variables（全部 optional）：

- `BRAINSTORM_PORT`：bind port（default：random high port 49152-65535）
- `BRAINSTORM_HOST`：bind interface（default：`127.0.0.1`）
- `BRAINSTORM_URL_HOST`：startup JSON 中 URL 使用的 hostname（default：当 host 为 `127.0.0.1` 时为 `localhost`，否则与 host 相同）
- `BRAINSTORM_DIR`：screen directory path（default：`/tmp/brainstorm`）

### Startup Sequence

1. 如果 `SCREEN_DIR` 不存在，则创建它（`mkdirSync` recursive）
2. 从 `__dirname` 加载 frame template 和 helper.js
3. 在 configured host/port 上启动 HTTP server
4. 在 `SCREEN_DIR` 上启动 `fs.watch`
5. listen 成功后，将 `server-started` JSON log 到 stdout：`{ type, port, host, url_host, url, screen_dir }`
6. 将同一 JSON 写到 `SCREEN_DIR/.server-info`，这样当 stdout 被隐藏（background execution）时 agents 仍能找到 connection details

### Application-Level WebSocket Messages

当从 client 收到 TEXT frame：

1. 作为 JSON parse。parse 失败时 log 到 stderr 并继续。
2. 以 `{ source: 'user-event', ...event }` log 到 stdout。
3. 如果 event 包含 `choice` property，将 JSON append 到 `SCREEN_DIR/.events`（每行一个 event）。

### File Watching

`fs.watch(SCREEN_DIR)` 替换 chokidar。对于 HTML file events：

- 新文件（`rename` event 且 file 存在）：如果 `.events` file 存在则删除（`unlinkSync`），并以 JSON 向 stdout log `screen-added`
- 文件变更（`change` event）：以 JSON 向 stdout log `screen-updated`（不要清除 `.events`）
- 两种 events：向所有 connected WebSocket clients 发送 `{ type: 'reload' }`

按 filename 使用约 100ms timeout debounce，防止重复 events（macOS 和 Linux 上常见）。

### Error Handling

- WebSocket clients 发来的 malformed JSON：log 到 stderr，继续
- Unhandled opcodes：以 status 1003 close
- Client disconnects：从 broadcast set 移除
- `fs.watch` errors：log 到 stderr，继续
- 无 graceful shutdown logic；shell scripts 通过 SIGTERM 处理 process lifecycle

## What Changes

| Before | After |
|---|---|
| `index.js` + `package.json` + `package-lock.json` + 714 `node_modules` files | `server.js`（single file） |
| express, ws, chokidar dependencies | none |
| No static file serving | `/files/*` serves from screen directory |

## What Stays the Same

- `helper.js`：无变更
- `frame-template.html`：无变更
- `start-server.sh`：一行更新：`index.js` 改为 `server.js`
- `stop-server.sh`：无变更
- `visual-companion.md`：无变更
- 所有现有 server behavior 和 external contract

## Platform Compatibility

- `server.js` 只使用 cross-platform Node built-ins
- `fs.watch` 对 macOS、Linux 和 Windows 上的单层 flat directories 是可靠的
- Shell scripts 需要 bash（Windows 上为 Git Bash，这是 Claude Code 需要的）

## Testing

**Unit tests** (`ws-protocol.test.js`): 通过 require `server.js` exports，直接测试 WebSocket frame encoding/decoding、handshake computation 和 protocol edge cases。

**Integration tests** (`server.test.js`): 测试完整 server behavior：HTTP serving、WebSocket communication、file watching、brainstorming workflow。使用 `ws` npm package 作为 test-only client dependency（不 shipping 给 end users）。
