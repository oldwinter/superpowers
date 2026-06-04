# Go Fractals CLI - Implementation Plan

使用 `superpowers:subagent-driven-development` skill 执行这个 plan。

## Context

构建一个生成 ASCII fractals 的 CLI tool。完整 specification 见 `design.md`。

## Tasks

### Task 1: Project Setup

创建 Go module 和 directory structure。

**Do:**
- Initialize `go.mod` with module name `github.com/superpowers-test/fractals`
- 创建 directory structure：`cmd/fractals/`、`internal/sierpinski/`、`internal/mandelbrot/`、`internal/cli/`
- 创建 minimal `cmd/fractals/main.go`，打印 "fractals cli"
- 添加 `github.com/spf13/cobra` dependency

**Verify:**
- `go build ./cmd/fractals` succeeds
- `./fractals` prints "fractals cli"

---

### Task 2: CLI Framework with Help

设置 Cobra root command 和 help output。

**Do:**
- 创建 `internal/cli/root.go` with root command
- 配置 help text，显示 available subcommands
- 把 root command 接入 `main.go`

**Verify:**
- `./fractals --help` shows usage with "sierpinski" and "mandelbrot" listed as available commands
- `./fractals`（no args）shows help

---

### Task 3: Sierpinski Algorithm

实现 Sierpinski triangle generation algorithm。

**Do:**
- 创建 `internal/sierpinski/sierpinski.go`
- 实现 `Generate(size, depth int, char rune) []string`，返回 triangle lines
- 使用 recursive midpoint subdivision algorithm
- 创建 `internal/sierpinski/sierpinski_test.go`，包含 tests：
  - Small triangle（size=4, depth=2）matches expected output
  - Size=1 returns single character
  - Depth=0 returns filled triangle

**Verify:**
- `go test ./internal/sierpinski/...` passes

---

### Task 4: Sierpinski CLI Integration

把 Sierpinski algorithm 接到 CLI subcommand。

**Do:**
- 创建 `internal/cli/sierpinski.go` with `sierpinski` subcommand
- 添加 flags：`--size`（default 32）、`--depth`（default 5）、`--char`（default '*'）
- 调用 `sierpinski.Generate()` 并把 result print 到 stdout

**Verify:**
- `./fractals sierpinski` outputs a triangle
- `./fractals sierpinski --size 16 --depth 3` outputs smaller triangle
- `./fractals sierpinski --help` shows flag documentation

---

### Task 5: Mandelbrot Algorithm

实现 Mandelbrot set ASCII renderer。

**Do:**
- 创建 `internal/mandelbrot/mandelbrot.go`
- 实现 `Render(width, height, maxIter int, char string) []string`
- 将 complex plane region（-2.5 to 1.0 real, -1.0 to 1.0 imaginary）映射到 output dimensions
- 将 iteration count 映射到 character gradient " .:-=+*#%@"（如果提供 single char，则使用它）
- 创建 `internal/mandelbrot/mandelbrot_test.go`，包含 tests：
  - Output dimensions match requested width/height
  - Known point inside set（0,0）maps to max-iteration character
  - Known point outside set（2,0）maps to low-iteration character

**Verify:**
- `go test ./internal/mandelbrot/...` passes

---

### Task 6: Mandelbrot CLI Integration

把 Mandelbrot algorithm 接到 CLI subcommand。

**Do:**
- 创建 `internal/cli/mandelbrot.go` with `mandelbrot` subcommand
- 添加 flags：`--width`（default 80）、`--height`（default 24）、`--iterations`（default 100）、`--char`（default ""）
- 调用 `mandelbrot.Render()` 并把 result print 到 stdout

**Verify:**
- `./fractals mandelbrot` outputs recognizable Mandelbrot set
- `./fractals mandelbrot --width 40 --height 12` outputs smaller version
- `./fractals mandelbrot --help` shows flag documentation

---

### Task 7: Character Set Configuration

确保 `--char` flag 在两个 commands 中表现一致。

**Do:**
- 验证 Sierpinski `--char` flag 把 character 传给 algorithm
- Mandelbrot 中，`--char` 应使用 single character 而不是 gradient
- 添加 custom character output tests

**Verify:**
- `./fractals sierpinski --char '#'` uses '#' character
- `./fractals mandelbrot --char '.'` uses '.' for all filled points
- Tests pass

---

### Task 8: Input Validation and Error Handling

添加 invalid inputs validation。

**Do:**
- Sierpinski: size must be > 0, depth must be >= 0
- Mandelbrot: width/height must be > 0, iterations must be > 0
- 为 invalid inputs 返回 clear error messages
- 添加 error cases tests

**Verify:**
- `./fractals sierpinski --size 0` prints error, exits non-zero
- `./fractals mandelbrot --width -1` prints error, exits non-zero
- Error messages are clear and helpful

---

### Task 9: Integration Tests

添加调用 CLI 的 integration tests。

**Do:**
- 创建 `cmd/fractals/main_test.go` 或 `test/integration_test.go`
- 测试两个 commands 的 full CLI invocation
- 验证 output format 和 exit codes
- 测试 error cases return non-zero exit

**Verify:**
- `go test ./...` passes all tests including integration tests

---

### Task 10: README

记录 usage 和 examples。

**Do:**
- 创建 `README.md`，包含：
  - Project description
  - Installation: `go install ./cmd/fractals`
  - Usage examples for both commands
  - Example output（small samples）

**Verify:**
- README accurately describes the tool
- Examples in README actually work
