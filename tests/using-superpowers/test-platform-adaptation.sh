#!/usr/bin/env bash
# Every shipped *-tools.md reference must appear in Platform Adaptation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/using-superpowers/SKILL.md"
REFS="$REPO_ROOT/skills/using-superpowers/references"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "test-platform-adaptation: checking SKILL.md lists every tools reference"

[ -f "$SKILL" ] || fail "missing $SKILL"
grep -q "## Platform Adaptation" "$SKILL" \
  || fail "SKILL.md is missing Platform Adaptation"

shopt -s nullglob
for mapping in "$REFS"/*-tools.md; do
  name="$(basename "$mapping")"
  grep -Fq "$name" "$SKILL" \
    || fail "Platform Adaptation does not reference $name"
done

grep -Fq "gemini-tools.md" "$SKILL" \
  || fail "Platform Adaptation does not reference gemini-tools.md"

echo "PASS: Platform Adaptation lists every references/*-tools.md"
