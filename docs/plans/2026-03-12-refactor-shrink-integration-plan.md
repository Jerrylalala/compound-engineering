# 收缩式整合执行计划

**创建日期**: 2026-03-12
**目标**: 删除冗余文档，精简主规则文档
**原则**: 收缩而非扩张，取舍而非保留

---

## 执行摘要

**总时间**: 30 分钟
**总收益**: 删除 ~4,000 行，减少 ~1,200 tokens
**风险等级**: 低（只删除文档，不改代码）

---

## 阶段 1: 删除废弃内容（5 分钟）

### 任务 1.1: 删除废弃 Gemini 功能

```bash
rm -rf .gemini/
rm -rf .gemini-test/
rm scripts/gemini-review-now.sh
rm scripts/doctor.sh
```

**验收**: 无 Gemini 相关文件

---

### 任务 1.2: 删除过时文档

```bash
rm -rf docs/brainstorms/
rm docs/plans/2026-03-11-feat-superpowers-fusion-plan-original.md
rm docs/plans/2026-03-11-review-changes-summary.md
```

**验收**: 无 brainstorms 目录，无 -original/-summary 文件

---

### 任务 1.3: 删除未使用脚本

```bash
rm scripts/validate-upstream-merge.ps1
rm scripts/sync-to-targets.ps1
```

**验收**: 脚本目录只保留活跃脚本

---

### 任务 1.4: 删除重复文档

```bash
# 上游合并主题
rm UPSTREAM-MERGE-RECOMMENDATION.md
rm docs/MERGE-VISUAL-SUMMARY.md

# 预防策略主题
rm docs/solutions/PREVENTION-IMPLEMENTATION-SUMMARY.md
rm docs/solutions/QUICK-REFERENCE.md
```

**验收**: 每个主题只保留一个权威文档

---

### 任务 1.5: 删除不相关文档

```bash
rm AGENTS.md
```

**验收**: 无 TypeScript CLI 开发指南

---

## 阶段 2: 精简主规则文档（15 分钟）

### 任务 2.1: 精简全局 CLAUDE.md

**文件**: `~/.claude/CLAUDE.md`

**删除**:
- 第 156-180 行: UI 设计理念章节

**简化**:
- 第 16-28 行: 交互提醒（移除硬编码路径）

**验收**: 字数从 524 → ~350 words

---

### 任务 2.2: 精简项目 CLAUDE.md

**文件**: `CLAUDE.md`

**删除**:
- 第 107-114 行: 当前组件统计表格

**替换**:
- 第 182-215 行 → 2 行:
  ```markdown
  ## 更新插件

  **推荐**: `scripts/bump-version.ps1 -BumpType patch`
  **手动**: 见 [版本管理预防策略](docs/zh-CN/VERSION-STRATEGY.md)
  ```

**替换**:
- 第 249-266 行 → 3 行:
  ```markdown
  ## 经验库

  使用 Grep 搜索：
  - 全局: `~/.compound/solutions/`
  - 项目: `docs/solutions/`
  ```

**精简**:
- 第 132-160 行: 目录结构（只保留关键路径）

**验收**: 字数从 933 → ~600 words

---

### 任务 2.3: 精简插件 CLAUDE.md

**文件**: `plugins/compound-engineering/CLAUDE.md`

**删除**:
- 第 249-280 行: Skill Compliance Checklist

**精简**:
- 第 40-52 行: 危险信号表（保留 3-5 个核心信号）
- 第 162-179 行: 双命名说明（移到用户文档）

**验收**: 字数从 994 → ~700 words

---

## 阶段 3: 提交更改（5 分钟）

### 任务 3.1: 验证更改

```bash
git status
git diff --stat
```

**验收**:
- 删除 ~4,000 行
- 修改 3 个 CLAUDE.md 文件

---

### 任务 3.2: 提交到 Git

```bash
git add -A
git commit -m "refactor: 收缩式整合 - 删除冗余和精简主规则文档

**删除**:
- 废弃 Gemini 功能（~500 行）
- 过时 brainstorm/plans 文档（~2,700 行）
- 重复的上游合并/预防策略文档（~1,200 行）
- 未使用脚本和不相关文档（~250 行）

**精简**:
- 全局 CLAUDE.md（-200 tokens）
- 项目 CLAUDE.md（-600 tokens）
- 插件 CLAUDE.md（-400 tokens）

**总计**:
- 删除 ~4,000 行文档
- 精简 ~1,200 tokens CLAUDE.md
- 默认上下文减少 ~40%

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

**验收**: Commit 成功

---

### 任务 3.3: 推送到远程

```bash
git push
```

**验收**: 推送成功

---

## 快速路径（12 分钟）

如果只做 20% 工作，按此顺序执行：

### 1. 删除 docs/brainstorms/（5 分钟）

```bash
rm -rf docs/brainstorms/
git add -A
git commit -m "refactor: 删除过时 brainstorm 文档（1,798 行）"
git push
```

---

### 2. 删除重复的上游合并文档（2 分钟）

```bash
rm UPSTREAM-MERGE-RECOMMENDATION.md
rm docs/MERGE-VISUAL-SUMMARY.md
git add -A
git commit -m "refactor: 删除重复的上游合并文档（811 行）"
git push
```

---

### 3. 精简项目 CLAUDE.md 的更新检查清单（5 分钟）

编辑 `CLAUDE.md`，替换第 182-215 行为 2 行。

```bash
git add CLAUDE.md
git commit -m "refactor: 精简项目 CLAUDE.md 的更新检查清单（~200 tokens）"
git push
```

---

## 验收标准

### 文档数量

- 删除前: ~11,000 行
- 删除后: ~7,000 行
- 减少: ~36%

### Token 消耗

- 删除前: 3,280 tokens (CLAUDE.md)
- 删除后: ~2,000 tokens
- 减少: ~39%

### 默认入口

- 保留: 6 个默认入口文档
- 降级: ~20 个参考文档
- 删除: ~4,000 行冗余文档

---

## 风险评估

| 风险 | 影响 | 概率 | 缓解 |
|------|------|------|------|
| 误删有用文档 | 中 | 低 | Git 可恢复 |
| 破坏现有功能 | 低 | 极低 | 只删除文档，不改代码 |
| 引用失效 | 低 | 低 | 保留权威版本 |

---

## 回滚方案

如果发现问题：

```bash
git reset --hard HEAD~1
git push --force
```

---

## 后续优化（可选）

### P1: 收敛重复专题文档（10 分钟）

- 检查其他重复主题
- 应用单入口原则

### P2: 智能跳过（按需）

- 小任务不走重型流程
- 非研究任务不读取分析材料

---

**计划创建**: 2026-03-12
**预计执行**: 立即
**预计完成**: 30 分钟内
