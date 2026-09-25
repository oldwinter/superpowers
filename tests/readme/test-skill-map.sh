#!/usr/bin/env bash
# README skill identity must be the on-disk slug, with a next-step link.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
README="$REPO_ROOT/README.md"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "test-skill-map: checking README slugs and SKILL.md links"

[ -f "$README" ] || fail "missing $README"

library="$(awk '/^### Skills Library$/{p=1;next} /^## /{if(p) exit} p' "$README")"
[ -n "$library" ] || fail "missing Skills Library section"

workflow="$(awk '/^## 基本工作流$/{p=1;next} /^## /{if(p) exit} p' "$README")"
[ -n "$workflow" ] || fail "missing 基本工作流 section"

echo "$library" | grep -Fq '| 译名 |' \
  || fail "Skills Library is missing a 译名 column"
echo "$library" | grep -Fq '| slug |' \
  || fail "Skills Library is missing a slug column"
echo "$library" | grep -Fq '| 路径 |' \
  || fail "Skills Library is missing a 路径 column"

missing=0
shopt -s nullglob
for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
  slug="$(basename "$(dirname "$skill_md")")"
  link="](skills/${slug}/SKILL.md)"
  if ! echo "$library" | grep -Fq "$link"; then
    echo "FAIL: Skills Library does not link skills/${slug}/SKILL.md" >&2
    missing=1
  fi
  echo "$library" | grep -Fq "\`skills/${slug}/\`" \
    || { echo "FAIL: Skills Library missing path skills/${slug}/" >&2; missing=1; }
  if ! echo "$workflow" | grep -q "$slug"; then
    case "$slug" in
      systematic-debugging|verification-before-completion|dispatching-parallel-agents|receiving-code-review|writing-skills|using-superpowers)
        ;;
      *)
        echo "FAIL: 基本工作流 missing slug $slug" >&2
        missing=1
        ;;
    esac
  fi
done
[ "$missing" -eq 0 ] || fail "README skill map is incomplete"

for zh in 头脑风暴 写作计划 测试驱动开发 系统调试 完成前验证 执行计划 请求代码审查 接收代码审查 完成开发分支 子代理驱动开发 写作技能; do
  if echo "$workflow" | grep -qE "^[[:space:]]*[0-9]+\\. \\*\\*${zh}\\*\\*"; then
    fail "基本工作流 still uses ${zh} as skill identity"
  fi
done

grep -Fq 'docs/plans/' "$README" \
  || fail "README missing docs/plans/ map"
grep -Fq 'docs/superpowers/plans/' "$README" \
  || fail "README missing docs/superpowers/plans/ map"

if grep -qE '\]\(skills/[^a-z0-9./_-]' "$README"; then
  fail "README links a non-slug skill path"
fi

echo "PASS: README skill map uses slugs and links every SKILL.md"
