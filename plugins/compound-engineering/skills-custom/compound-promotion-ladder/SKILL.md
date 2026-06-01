---
name: compound-promotion-ladder
description: "Fork Overlay：经验分层沉淀升级阶梯。检测是否值得将 solution 升级为 pattern 或 skill。使用时机：ce:compound 完成后手动调用，分析 docs/solutions/ 中的重复模式。（不会自动触发，需主动加载此 skill）"
---

# Compound Promotion Ladder — 经验分层沉淀

> **Codex 洞察（P4→P5）**：本仓库强项不是"自动造 skill"，而是"把经验分层沉淀成可检索、可升级知识"。

---

## 升级阶梯

```
原始经验 → solution doc → critical pattern → existing skill 补充 → new skill
   ↑                                                                    ↑
  ce:compound 写入                                           手动决策后创建
```

| 层级 | 位置 | 形态 | 触发方式 |
|------|------|------|----------|
| **solution** | `docs/solutions/` | 具体事件记录 + YAML frontmatter | ce:compound 自动写入 |
| **critical pattern** | `docs/solutions/` + `pattern:` tag | 跨场景抽象规律 | 检测到 ≥2 次重复后提升 |
| **skill supplement** | 现有 `skills/*/SKILL.md` 新增章节 | 在已有 skill 内追加注意事项 | 检测到跨模块影响 |
| **new skill** | `skills-custom/` 新目录 | 独立 SKILL.md | 非显然模式 + 影响范围广 |

---

## P5a：ce:compound 后的自动检测

`ce:compound` 写入 solution doc 后，运行以下检测：

### 检测逻辑

```bash
# 1. 统计同类问题出现频次
# 检查 docs/solutions/ 中相同 tags 的文档数量
SIMILAR_COUNT=$(grep -rl "tags:.*$TAG" docs/solutions/ | wc -l)

# 2. 检查是否跨模块
AFFECTED_FILES=$(git log --all -- "$RELATED_FILE" --name-only | sort -u | wc -l)

# 3. 判断是否为非显然模式（无法通过直觉推导）
# 需要人工判断，但 AI 可以提示
```

### 升级触发条件

| 条件 | 行动 | 优先级 |
|------|------|--------|
| 同类问题 ≥ 2 次（相同 tags） | 建议提升为 `critical pattern` | 中 |
| 影响 ≥ 3 个不同模块 | 建议补充到相关 skill | 高 |
| 非显然模式 + 频繁出现 | 建议创建新 skill | 高 |
| 单次事件，无重复 | 保留 solution doc，不提升 | 低 |

### 检测输出格式

`ce:compound` 完成后，如果检测到升级条件，输出：

```
🪜 Compound Promotion 检测结果：

  同类问题出现 3 次（tags: windows-hooks, encoding）
  影响模块：hooks/, scripts/, .claude/

  建议：
  1. 将 docs/solutions/2026-04-05-windows-hooks-crlf.md 提升为 critical pattern
     → 添加 type: critical-pattern 到 frontmatter
  2. 在 skills/git-worktree/SKILL.md 的 Windows 注意事项节补充此模式

  执行？(y/n/skip)
```

---

## P5b：Recurrence Miner — 定期挖掘重复问题

手动调用时（或每月），从 `docs/solutions/` 挖掘重复模式：

```bash
# 1. 按 tags 统计频次
grep -r "^tags:" docs/solutions/*.md | \
  sed 's/.*tags: //' | tr ',' '\n' | \
  sort | uniq -c | sort -rn | head -20

# 2. 找出同一 file_path 出现多次的问题
grep -r "^  - " docs/solutions/*.md | \
  grep -E "file_path|affected_files" | \
  awk '{print $NF}' | sort | uniq -c | sort -rn | head -10
```

**输出分析报告**：`docs/solutions/recurrence-report-YYYY-MM-DD.md`

---

## 升级执行流程

### 提升为 Critical Pattern

在现有 solution doc 的 frontmatter 中：

```yaml
# 原 solution frontmatter
type: solution

# 提升后
type: critical-pattern
pattern_id: "CP-001"
first_seen: "2026-03-24"
recurrence_count: 3
affected_modules: ["hooks", "scripts", ".claude"]
```

### 补充到现有 Skill

在目标 skill 的 SKILL.md 中找合适章节，追加：

```markdown
## ⚠️ Windows 注意事项

> **来源**：CP-001（出现 3 次）

Windows 上运行 hooks 时注意：
- CRLF 换行符导致脚本解析失败 → 使用 `dos2unix` 或 git attributes
- 详见 docs/solutions/2026-04-05-windows-hooks-crlf.md
```

### 创建新 Skill

当模式足够独立、通用，且不适合补充到任何现有 skill：

```bash
# 1. 使用 create-agent-skills skill 创建
# 2. 放入 skills-custom/ (fork overlay)
# 3. 在 docs/solutions/ 中链接新 skill
```

---

## 防过拟合机制

| 风险 | 防御 |
|------|------|
| 为通过 eval 优化 prompt | Promotion 基于真实重复，不基于 eval 结果 |
| 过度抽象 | 升级需 ≥2 次真实出现，单次不升级 |
| eval 案例泄漏进 skill prompt | 铁律：`evals/` 内容绝不复制到 skill prompt |

---

## 与 ce:compound 的集成

```
ce:compound 完成写入 docs/solutions/<date>-<desc>.md
    ↓
自动运行 Promotion 检测（本 overlay P5a）
    ↓
检测到升级条件？
    ├─ 否 → 完成，结束
    └─ 是 → 展示升级建议 → 等待用户确认 → 执行升级
```
