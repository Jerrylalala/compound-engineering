#!/bin/bash
# Codex 手动审核脚本
# 用法: ./scripts/codex-review-now.sh [scope]
# scope: uncommitted (默认), staged, branch, all

SCOPE=${1:-uncommitted}
OUTPUT_FILE="${TEMP:-/tmp}/codex-review-$(date +%Y%m%d-%H%M%S).txt"

echo "=== Codex Code Review ==="
echo "Scope: $SCOPE"
echo "Output: $OUTPUT_FILE"
echo ""

case $SCOPE in
  uncommitted)
    CHANGES=$(git diff --name-only HEAD 2>/dev/null)
    DIFF=$(git diff HEAD 2>/dev/null | head -500)
    ;;
  staged)
    CHANGES=$(git diff --name-only --cached 2>/dev/null)
    DIFF=$(git diff --cached 2>/dev/null | head -500)
    ;;
  branch)
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    BASE_BRANCH=${BASE_BRANCH:-main}
    CHANGES=$(git diff --name-only $BASE_BRANCH...HEAD 2>/dev/null)
    DIFF=$(git diff $BASE_BRANCH...HEAD 2>/dev/null | head -500)
    ;;
  all)
    CHANGES=$(git ls-files --modified --others --exclude-standard 2>/dev/null)
    DIFF=$(git diff HEAD 2>/dev/null | head -500)
    ;;
  *)
    echo "Unknown scope: $SCOPE"
    echo "Usage: $0 [uncommitted|staged|branch|all]"
    exit 1
    ;;
esac

if [ -z "$CHANGES" ]; then
  echo "No changes to review."
  exit 0
fi

echo "Files to review:"
echo "$CHANGES" | head -20
echo ""

REVIEW_PROMPT="You are reviewing code changes for a Claude Code plugin project (compound-engineering-plugin).

## Files Changed
$CHANGES

## Diff (truncated to 500 lines)
$DIFF

## Review Focus
1. **CRITICAL**: Security vulnerabilities, data loss risks
2. **WARNING**: Logic errors, performance issues, breaking changes
3. **INFO**: Code style, documentation, best practices

## Project Context
- This is a Claude Code plugin with agents, commands, and skills
- Key files: hooks.json, workflow commands (plan/work/review/compound)
- Documentation in docs/solutions/ and docs/zh-CN/

## Output Format
Provide a structured report:

### Summary
[1-2 sentence overview]

### Findings
#### CRITICAL
- [Issue 1]
- [Issue 2]

#### WARNING
- [Issue 1]

#### INFO
- [Issue 1]

### Recommendations
[Top 3 actionable items]"

echo "Starting Codex review..."
codex "$REVIEW_PROMPT" 2>&1 | tee "$OUTPUT_FILE"

echo ""
echo "=== Review Complete ==="
echo "Full output saved to: $OUTPUT_FILE"
