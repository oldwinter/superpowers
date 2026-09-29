#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

tests=(
  "bash tests/readme/test-skill-map.sh"
  "bash tests/hooks/test-session-start.sh"
  "bash tests/codex/test-marketplace-manifest.sh"
  "bash tests/devin/test-devin-plugin.sh"
  "bash tests/kimi/run-tests.sh"
  "bash tests/opencode/run-tests.sh"
  "node tests/pi/test-pi-extension.mjs"
  "bash tests/antigravity/run-tests.sh"
  "bash tests/systematic-debugging/test-find-polluter.sh"
  "bash tests/using-superpowers/test-platform-adaptation.sh"
)

for test_command in "${tests[@]}"; do
  printf '\n>>> %s\n' "$test_command"
  bash -c "$test_command"
done

printf '\nFast plugin baseline passed (%s suites).\n' "${#tests[@]}"
