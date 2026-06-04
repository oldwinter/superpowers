# Go Fractals CLI - Design

## 概览

一个生成 ASCII art fractals 的 command-line tool。支持两种 fractal types，并提供 configurable output。

## Usage

```bash
# Sierpinski triangle
fractals sierpinski --size 32 --depth 5

# Mandelbrot set
fractals mandelbrot --width 80 --height 24 --iterations 100

# Custom character
fractals sierpinski --size 16 --char '#'

# Help
fractals --help
fractals sierpinski --help
```

## Commands

### `sierpinski`

使用 recursive subdivision 生成 Sierpinski triangle。

Flags:
- `--size`（default: 32）- Triangle base 的 width，单位为 characters
- `--depth`（default: 5）- Recursion depth
- `--char`（default: '*'）- Filled points 使用的 character

Output: Triangle printed to stdout, one line per row.

### `mandelbrot`

把 Mandelbrot set 渲染成 ASCII art。将 iteration count 映射到 characters。

Flags:
- `--width`（default: 80）- Output width in characters
- `--height`（default: 24）- Output height in characters
- `--iterations`（default: 100）- Escape calculation 的 maximum iterations
- `--char`（default: gradient）- Single character，或省略以使用 gradient " .:-=+*#%@"

Output: Rectangle printed to stdout.

## Architecture

```
cmd/
  fractals/
    main.go           # Entry point, CLI setup
internal/
  sierpinski/
    sierpinski.go     # Algorithm
    sierpinski_test.go
  mandelbrot/
    mandelbrot.go     # Algorithm
    mandelbrot_test.go
  cli/
    root.go           # Root command, help
    sierpinski.go     # Sierpinski subcommand
    mandelbrot.go     # Mandelbrot subcommand
```

## Dependencies

- Go 1.21+
- `github.com/spf13/cobra` for CLI

## Acceptance Criteria

1. `fractals --help` shows usage
2. `fractals sierpinski` outputs a recognizable triangle
3. `fractals mandelbrot` outputs a recognizable Mandelbrot set
4. `--size`, `--width`, `--height`, `--depth`, `--iterations` flags work
5. `--char` customizes output character
6. Invalid inputs produce clear error messages
7. All tests pass
