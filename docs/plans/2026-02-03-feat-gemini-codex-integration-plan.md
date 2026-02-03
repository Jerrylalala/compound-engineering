---
title: "feat: Gemini CLI 集成（简化版）"
type: feat
date: 2026-02-03
---

# Gemini CLI 集成（简化版）

## Overview

在 Claude Code 的 `/workflows:review` 命令中添加 `[G]` 参数支持，调用 Gemini CLI 进行额外代码审核。

**基于 Gemini 官方建议简化实现**。

## Gemini CLI 调用规范（来自 Gemini 官方回复）

```bash
# 核心调用方式
cat combined_input.txt | gemini --approval-mode plan -o json > output.json 2> log.txt

# 超时处理：用系统 timeout 命令（Gemini CLI 无内置超时）
timeout 300 bash -c 'cat input | gemini --approval-mode plan -o json > output.json 2> log.txt'

# 输出解析
node -e "console.log(JSON.parse(require('fs').readFileSync('output.json', 'utf8')).response)"
```

**关键差异**（vs Codex）：
| 特性 | Codex | Gemini |
|------|-------|--------|
| 输出到文件 | `--output-last-message file` | `> file`（重定向） |
| 格式控制 | `--json` | `-o json` |
| 模式 | `exec` 子命令 | `--approval-mode plan` |
| 长文本 | 需截断 | **不需要截断**（1M+ tokens） |

## Acceptance Criteria

- [ ] `/workflows:review [G]` 调用 Gemini 额外审核
- [ ] `/workflows:review [C][G]` 同时调用 Codex 和 Gemini
- [ ] 转换到 Codex/Gemini 格式时自动过滤 `[C]` `[G]` 参数说明

---

## Task Breakdown（4 个核心任务）

### Task 1: 创建 Gemini 审核脚本（简化版）

**文件**: `scripts/gemini-review-now.sh`

**代码**:
```bash
#!/bin/bash
# Gemini 智能审核脚本（简化版 - 基于 Gemini 官方建议）
# 用法: ./scripts/gemini-review-now.sh [scope] [timeout_seconds]

set -e

SCOPE=${1:-uncommitted}
TIMEOUT_SECONDS=${2:-300}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="${TEMP:-/tmp}/gemini-review"
OUTPUT_FILE="$OUTPUT_DIR/result-$TIMESTAMP.json"
LOG_FILE="$OUTPUT_DIR/log-$TIMESTAMP.txt"
INPUT_FILE="$OUTPUT_DIR/input-$TIMESTAMP.txt"

mkdir -p "$OUTPUT_DIR"

# 清理函数
cleanup() {
  rm -f "$INPUT_FILE" 2>/dev/null
}
trap cleanup EXIT

echo "=== Gemini Code Review ==="
echo "Scope: $SCOPE | Timeout: ${TIMEOUT_SECONDS}s"

# 检查依赖
if ! command -v gemini &> /dev/null; then
    echo "❌ Gemini CLI 未安装，请运行: npm install -g @google/gemini-cli"
    exit 1
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ 当前目录不是 Git 仓库"
    exit 1
fi

# 参数验证
if ! [[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]]; then
    echo "❌ timeout 必须是正整数"
    exit 1
fi

# 获取 diff（不截断 - Gemini 支持 1M+ tokens）
case $SCOPE in
  uncommitted) DIFF=$(git diff HEAD 2>/dev/null || true) ;;
  staged)      DIFF=$(git diff --cached 2>/dev/null || true) ;;
  branch)
    BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    DIFF=$(git diff "$BASE"...HEAD 2>/dev/null || true) ;;
  all)         DIFF=$(git diff HEAD 2>/dev/null || true) ;;
  *)           echo "Usage: $0 [uncommitted|staged|branch|all] [timeout]"; exit 1 ;;
esac

if [ -z "$DIFF" ]; then
  echo "✅ No changes to review."
  exit 0
fi

# 构建输入（Diff + Prompt 组合，通过 stdin 传递）
cat > "$INPUT_FILE" << 'PROMPT_END'
You are a senior code reviewer. Review these changes and provide actionable feedback.

## Review Focus
1. **CRITICAL**: Security vulnerabilities, data loss risks, breaking changes
2. **WARNING**: Logic errors, performance issues, race conditions
3. **INFO**: Code style, best practices, documentation

## Output Format
### Summary
[1-2 sentence overview]

### Findings
#### 🔴 CRITICAL
- [Issue with file:line and explanation]

#### 🟡 WARNING
- [Issue with file:line and explanation]

#### 🔵 INFO
- [Suggestion with file:line]

### Recommendations
1. [Most important action]
2. [Second priority]
3. [Third priority]

## Code Changes to Review
PROMPT_END

echo '```diff' >> "$INPUT_FILE"
echo "$DIFF" >> "$INPUT_FILE"
echo '```' >> "$INPUT_FILE"

echo "🚀 Calling Gemini..."

# 调用 Gemini（使用系统 timeout 命令）
if timeout "$TIMEOUT_SECONDS" bash -c "cat '$INPUT_FILE' | gemini --approval-mode plan -o json > '$OUTPUT_FILE' 2> '$LOG_FILE'"; then
  echo "=== ✅ Review Complete ==="

  # 解析 JSON 输出
  if command -v jq &> /dev/null; then
    jq -r '.response // .' "$OUTPUT_FILE" 2>/dev/null || cat "$OUTPUT_FILE"
  else
    OUTPUT_FILE="$OUTPUT_FILE" node -e "
      const data = JSON.parse(require('fs').readFileSync(process.env.OUTPUT_FILE, 'utf8'));
      console.log(data.response || JSON.stringify(data, null, 2));
    " 2>/dev/null || cat "$OUTPUT_FILE"
  fi
else
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 124 ]; then
    echo "=== ⏱️ Timeout (${TIMEOUT_SECONDS}s) ==="
    echo "增加超时重试: ./scripts/gemini-review-now.sh $SCOPE 600"
  else
    echo "=== ❌ Failed (exit $EXIT_CODE) ==="
    [ -f "$LOG_FILE" ] && tail -10 "$LOG_FILE"
  fi
  exit $EXIT_CODE
fi
```

**验证**:
```bash
# 确认脚本可执行
chmod +x scripts/gemini-review-now.sh
bash scripts/gemini-review-now.sh uncommitted
```

---

### Task 2: 修改 review.md 添加 [G] 支持

**文件**: `plugins/compound-engineering/commands/workflows/review.md`

**修改内容**:

1. **Frontmatter** (行 1-5):
```yaml
---
name: workflows:review
description: "Step 4: [C][G] 使用多代理分析进行全面代码审查"
argument-hint: "[PR number, GitHub URL, branch name, or latest] [C] [G]"
---
```

2. **参数说明表格** (行 15-30):
```markdown
| 参数 | 说明 | 示例 |
|------|------|------|
| PR 号 | GitHub PR 编号 | `/workflows:review 123` |
| URL | GitHub PR URL | `/workflows:review https://...` |
| 分支名 | 审核指定分支 | `/workflows:review feature-branch` |
| `[C]` | 自动调用 Codex 额外审核 | `/workflows:review [C]` |
| `[G]` | 自动调用 Gemini 额外审核 | `/workflows:review [G]` |

<!-- CLAUDE-CODE-ONLY-START -->
**注意**：`[C]` 和 `[G]` 参数仅在 Claude Code 中有效。
<!-- CLAUDE-CODE-ONLY-END -->

**示例：**
```bash
/workflows:review [G]          # 当前分支 + Gemini 审核
/workflows:review [C][G]       # 当前分支 + Codex + Gemini
/workflows:review 123 [C][G]   # PR #123 + 双重审核
```

3. **Prerequisites** (行 34-40):
```markdown
- **For Codex review `[C]`**: `npm install -g @openai/codex`
- **For Gemini review `[G]`**: `npm install -g @google/gemini-cli`
```

4. **参数解析** (行 44-63):
```markdown
### 0. 解析参数（检测 [C] 和 [G] 标志）

检查参数：
- 包含 `[C]` → CODEX_ENABLED = true
- 包含 `[G]` → GEMINI_ENABLED = true
- 移除标志后剩余部分作为审核目标
```

5. **添加 Gemini 审核章节**（在 Codex 章节后）:
```markdown
### 8. Gemini 额外审核（参数 `[G]` 触发）

<!-- CLAUDE-CODE-ONLY-START -->

当 GEMINI_ENABLED = true 时：

**Step 8.1: 检查 Gemini CLI**
```bash
command -v gemini || echo "❌ 请运行: npm install -g @google/gemini-cli"
```

**Step 8.2: 调用 Gemini 审核**
```bash
./scripts/gemini-review-now.sh uncommitted 300
```

**Step 8.3: 整合结果**
```markdown
## 🤖 Gemini 额外审核结果
[Gemini 输出内容]
```

<!-- CLAUDE-CODE-ONLY-END -->
```

**验证**: 确认 `/workflows:review [G]` 显示 Gemini 参数说明

---

### Task 3: 转换器添加 Claude-Code-Only 过滤

**文件**: `src/utils/filter-claude-code-only.ts`（新建）

**代码**:
```typescript
/**
 * 过滤 Claude Code 专属内容
 * 用于转换到 Codex/Gemini 格式时移除 [C] [G] 参数说明
 */
export function filterClaudeCodeOnly(content: string): string {
  // 移除 CLAUDE-CODE-ONLY 块
  let result = content.replace(
    /<!--\s*CLAUDE-CODE-ONLY-START\s*-->[\s\S]*?<!--\s*CLAUDE-CODE-ONLY-END\s*-->/gi,
    ''
  )
  // 移除 [C] [G] 参数
  result = result.replace(/\[C\]\s*/gi, '')
  result = result.replace(/\[G\]\s*/gi, '')
  // 清理多余空行
  result = result.replace(/\n{3,}/g, '\n\n')
  return result
}
```

**修改 `src/converters/claude-to-codex.ts`**:
```typescript
import { filterClaudeCodeOnly } from "../utils/filter-claude-code-only"

// 在 convertCommandSkill 函数中使用
const filteredBody = filterClaudeCodeOnly(command.body.trim())
```

**修改 `src/converters/claude-to-gemini.ts`**:
```typescript
import { filterClaudeCodeOnly } from "../utils/filter-claude-code-only"

// 在 buildCommandPrompt 函数中使用
const body = filterClaudeCodeOnly(cmd.body?.trim() || "")
```

**验证**:
```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex
bun run src/index.ts install ./plugins/compound-engineering --to gemini
# 检查输出不包含 [C] [G]
```

---

### Task 4: 更新文档和版本号

**修改文件**:
1. `plugins/compound-engineering/CHANGELOG.md` - 添加 v2.37.0 记录
2. `plugins/compound-engineering/hooks/skill-checking-protocol.md` - 添加 [G] 行
3. 版本号同步（两个 JSON 文件）

**CHANGELOG 内容**:
```markdown
## v2.37.0 (2026-02-03)

### 新功能
- **Gemini CLI 集成**：`/workflows:review [G]` 支持调用 Gemini 进行额外代码审核
- **多工具协同审核**：`/workflows:review [C][G]` 同时调用 Codex 和 Gemini
- **转换器智能过滤**：转换到 Codex/Gemini 格式时自动过滤 `[C]` `[G]` 参数说明

### 技术细节
- 基于 Gemini 官方建议：`gemini --approval-mode plan -o json`
- 使用系统 `timeout` 命令处理超时
- 不截断 diff（Gemini 支持 1M+ tokens）
```

**验证**:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

---

## 验收测试

```bash
# 1. 测试 Gemini 脚本
./scripts/gemini-review-now.sh uncommitted

# 2. 测试 [G] 参数
/workflows:review [G]

# 3. 测试转换
bun run src/index.ts install ./plugins/compound-engineering --to gemini
grep -r "\[G\]" .gemini/ && echo "❌ 过滤失败" || echo "✅ 过滤成功"
```
