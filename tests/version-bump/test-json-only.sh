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

drift_repo="$TEST_ROOT/audit-drift"
mkdir -p "$drift_repo/scripts"
cp "$SCRIPT_SOURCE" "$drift_repo/scripts/bump-version.sh"
printf '%s\n' '{"files":[{"path":"one.json","field":"version"},{"path":"two.json","field":"version"}],"audit":{"exclude":[]}}' > "$drift_repo/.version-bump.json"
printf '%s\n' '{"version":"1.2.3"}' > "$drift_repo/one.json"
printf '%s\n' '{"version":"1.2.4"}' > "$drift_repo/two.json"
if bash "$drift_repo/scripts/bump-version.sh" --audit >/dev/null 2>&1; then
  fail "audit exited zero with declared manifest drift"
fi

empty_repo="$TEST_ROOT/empty-config"
mkdir -p "$empty_repo/scripts"
cp "$SCRIPT_SOURCE" "$empty_repo/scripts/bump-version.sh"
printf '%s\n' '{"files":[],"audit":{"exclude":[]}}' > "$empty_repo/.version-bump.json"
if empty_output=$(bash "$empty_repo/scripts/bump-version.sh" --check 2>&1); then
  fail "empty files config exited zero"
fi
[[ "$empty_output" == *"files must be a non-empty array"* ]] || fail "empty files config lacked an actionable error"
[[ "$empty_output" != *"unbound variable"* ]] || fail "empty files config crashed with an unbound variable"

for extra_args in '--check unexpected' '--audit unexpected' '--help unexpected' '2.0.0 unexpected'; do
  arity_repo="$TEST_ROOT/arity-${extra_args//[^A-Za-z0-9]/-}"
  make_fixture "$arity_repo"
  before="$(cat "$arity_repo/package.json")"
  read -r -a invocation <<< "$extra_args"
  if bash "$arity_repo/scripts/bump-version.sh" "${invocation[@]}" >/dev/null 2>&1; then
    fail "accepted extra arguments: $extra_args"
  fi
  [[ "$(cat "$arity_repo/package.json")" == "$before" ]] || fail "extra arguments changed package.json: $extra_args"
done

echo "JSON-only version boundaries passed"
