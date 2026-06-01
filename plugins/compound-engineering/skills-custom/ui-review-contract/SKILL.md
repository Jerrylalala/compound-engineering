---
name: ui-review-contract
description: "Fork Overlay：UI Review Contract — 四信号门触发协议。自动检测任务是否涉及 UI，决定是否在 ce:review 中加入视觉审查层。使用时机：运行 ce:work 或 ce:review 时，系统自动检查四信号门以决定是否触发 design review。"
---

# UI Review Contract — 四信号门触发协议

> **背景（Codex P9 → P4 提前）**：`ce:work` 已有 Figma Design Sync 步骤，但缺乏统一的触发协议。
> 本 overlay 收敛现有 UI 检测行为为可预期的四信号门规则。

---

## 四信号门定义

| 信号 | 类型 | 检测内容 |
|------|------|----------|
| **Plan Signal** | 计划/需求 | 出现 UI 相关词：`component`、`page`、`screen`、`layout`、`style`、`design`、`responsive`、`visual`、`UI`、`UX`、`界面`、`页面`、`样式`、`组件` |
| **File Signal** | 改动文件 | 匹配：`*.css`、`*.scss`、`*.tsx`、`*.jsx`、`*.vue`、`*.html`、`components/`、`pages/`、`views/`、`styles/`、`design-tokens/` |
| **Artifact Signal** | 工件引用 | 出现：Figma URL、`screenshot`、`visual diff`、`design spec`、`mockup` |
| **Exclusion Signal** | 排除条件 | 匹配：`API design`、`database design`、`schema`、纯 CLI/后端任务（无 File Signal 匹配时排除） |

### 触发规则

**满足以下任意一组组合**才触发 Design Review（单个信号不触发）：

| 组合 | 说明 |
|------|------|
| `Plan + File` | 计划提到 UI + 有前端文件改动 |
| `File + Artifact` | 有前端文件改动 + 有设计工件引用 |
| `Plan + Artifact` | 计划提到 UI + 有设计工件 |

**Exclusion Signal 覆盖**：如果 Exclusion Signal 触发且 File Signal 未触发，不做 Design Review。

---

## 触发后行为

当四信号门判断需要 Design Review 时，在 `ce:review` 的 Advisory Tier 中增加 UI 审查：

### 1. 加载设计审查代理（并行）

```
design-implementation-reviewer — 视觉对齐检查（如有 Figma URL）
figma-design-sync              — Figma 设计同步检查（如有 Figma URL）
design-iterator                — 迭代改进建议（N 轮截图-分析-改进循环）
```

### 2. 设计审查输出格式

使用 Review Contract 的 Advisory Tier 规则（`autofix_class: advisory`），额外字段：

```yaml
# 设计 finding 额外字段
design_check:
  figma_url: "https://figma.com/..."    # 如有
  screenshot: "path/to/screenshot.png"  # 如有
  visual_diff: "描述视觉差异"
  severity: P2 | P3                     # 设计问题最高 P2（不 blocking）
```

### 3. 输出 Checklist

设计审查完成后生成 checklist（插入 review.md）：

```markdown
## UI Review Checklist

- [ ] 组件间距符合设计规范
- [ ] 颜色/字体与 design token 一致
- [ ] 响应式布局在移动端正常
- [ ] 无障碍性（aria labels、contrast ratio）
- [ ] 加载/空/错误状态已实现
```

---

## 与现有工作流集成

### ce:work 中的集成点

在 ce:work Phase 3 质量检查阶段，已有 Figma Design Sync 步骤：

```
# 原有步骤（保留）
6. Figma Design Sync (if applicable)

# 本 overlay 增加
6.5 四信号门检查：是否需要 Design Review？
    └─ 是 → 加载 design-implementation-reviewer
    └─ 否 → 跳过
```

### ce:review 中的集成点

`ce:review` 的 persona-catalog 决定哪些 reviewer 被派发。本 overlay 增加：

```
如果四信号门触发 → 在 Advisory Tier 中自动添加 design-implementation-reviewer
如果有 Figma URL → 同时添加 figma-design-sync
```

---

## 信号门检测命令

在 ce:work Phase 1 完成环境扫描后，运行信号检测：

```bash
# Plan Signal: 检查计划文件中的 UI 关键词
# $PLAN_FILE = 当前任务的计划文件路径，如 docs/plans/2026-04-08-*.md
# 调用前需确定计划文件路径，或用 $(ls docs/plans/*.md | tail -1) 取最新文件
PLAN_FILE="${PLAN_FILE:-$(ls docs/plans/*.md 2>/dev/null | tail -1)}"
grep -i "component\|page\|screen\|layout\|style\|design\|UI\|UX" "$PLAN_FILE" 2>/dev/null || true

# File Signal: 检查改动文件
git diff --name-only HEAD | grep -E "\.(css|scss|tsx|jsx|vue|html)$|components/|pages/"

# Artifact Signal: 检查工件引用
DIFF_OUTPUT="${DIFF_OUTPUT:-$(git diff HEAD 2>/dev/null)}"
grep -ri "figma\.com\|screenshot\|visual.diff\|design.spec" "$PLAN_FILE" 2>/dev/null || true
echo "$DIFF_OUTPUT" | grep -i "figma\.com\|screenshot" || true

# Exclusion Signal
grep -i "API.design\|database.design\|schema" "$PLAN_FILE" 2>/dev/null || true
```

---

## 不触发示例（避免过度审查）

| 任务 | 信号 | 结果 |
|------|------|------|
| 修复 SQL 注入 | 仅 Exclusion Signal | ❌ 不触发 |
| 更新 README | 无任何信号 | ❌ 不触发 |
| 添加 API 端点 | Plan: "API design" (Exclusion) | ❌ 不触发 |
| 修复 Button 样式 | File: `button.css` + Plan: "style fix" | ✅ Plan+File 触发 |
| Figma 设计同步 | Artifact: Figma URL + File: `*.tsx` | ✅ File+Artifact 触发 |
