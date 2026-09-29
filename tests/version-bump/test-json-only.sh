#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_SOURCE="${SCRIPT_SOURCE:-$REPO_ROOT/scripts/bump-version.sh}"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

make_fixture() {
  local repo="$1"
  mkdir -p "$repo/scripts"
  cp "$SCRIPT_SOURCE" "$repo/scripts/bump-version.sh"
  printf '%s\n' '{"files":[{"path":"package.json","field":"version"}],"audit":{"exclude":[]}}' > "$repo/.version-bump.json"
  printf '%s\n' '{"name":"fixture","version":"1.2.3"}' > "$repo/package.json"
}

for invalid in 2.3.4oops 2.3.4.5 01.2.3 1.02.3 1.2.03; do
  repo="$TEST_ROOT/invalid-${invalid//[^A-Za-z0-9]/-}"
  make_fixture "$repo"
  before="$(cat "$repo/package.json")"
  if bash "$repo/scripts/bump-version.sh" "$invalid" >/dev/null 2>&1; then
    fail "accepted invalid version: $invalid"
  fi
  [[ "$(cat "$repo/package.json")" == "$before" ]] || fail "invalid version changed package.json: $invalid"
done

valid_repo="$TEST_ROOT/valid"
make_fixture "$valid_repo"
bash "$valid_repo/scripts/bump-version.sh" '2.3.4-rc.1+build.5' >/dev/null
[[ "$(jq -r .version "$valid_repo/package.json")" == '2.3.4-rc.1+build.5' ]] || fail "valid semantic version was not written"

audit_repo="$TEST_ROOT/audit-undeclared"
make_fixture "$audit_repo"
printf '%s\n' 'Undeclared release reference: 1.2.3' > "$audit_repo/release-note.txt"
if bash "$audit_repo/scripts/bump-version.sh" --audit >/dev/null 2>&1; then
  fail "audit exited zero with an undeclared version reference"
fi

echo "JSON-only version boundaries passed"
