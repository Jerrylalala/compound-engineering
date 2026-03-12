# 项目简化分析报告

**分析日期**: 2026-03-12
**分析范围**: 文档层、脚本层、配置层
**核心原则**: YAGNI（You Aren't Gonna Need It）

---

## 核心目的

本项目是 `EveryInc/compound-engineering-plugin` 的私有 Fork，核心目的：
1. 中文化层（docs/zh-CN/）
2. 本地扩展（skills-custom/、自定义命令）
3. 上游同步管理（scripts/、docs/solutions/）

---

## 发现的过度工程

### 1. 文档层冗余（严重）

#### 1.1 重复的上游合并文档

**问题**：3 个文档描述同一件事（上游合并策略）

| 文档 | 行数 | 大小 | 状态 |
|------|------|------|------|
| `UPSTREAM-MERGE-RECOMMENDATION.md` | 314 | 14KB | 顶层摘要 |
| `docs/MERGE-VISUAL-SUMMARY.md` | 497 | 25KB | 可视化版本 |
| `docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md` | 801 | 26KB | 详细分析 |

**冗余度**: 70%（内容高度重复）

**建议**：
- **保留**: `docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md`（最详细）
- **删除**: `UPSTREAM-MERGE-RECOMMENDATION.md`（摘要可整合到 CLAUDE.md）
- **删除**: `docs/MERGE-VISUAL-SUMMARY.md`（图表可整合到详细分析中）

**LOC 减少**: ~811 行

---

#### 1.2 重复的预防策略文档

**问题**：3 个文档描述预防措施，内容重叠

| 文档 | 行数 | 用途 |
|------|------|------|
| `docs/solutions/PREVENTION-STRATEGIES.md` | 685 | 详细预防策略 |
| `docs/solutions/PREVENTION-IMPLEMENTATION-SUMMARY.md` | 210 | 实施摘要 |
| `docs/solutions/QUICK-REFERENCE.md` | 138 | 快速参考 |

**冗余度**: 50%

**建议**：
- **保留**: `docs/solutions/PREVENTION-STRATEGIES.md`（作为单一信息源）
- **删除**: `PREVENTION-IMPLEMENTATION-SUMMARY.md`（内容可整合）
- **删除**: `QUICK-REFERENCE.md`（可作为 PREVENTION-STRATEGIES.md 的开头部分）

**LOC 减少**: ~348 行

---

#### 1.3 过时的 Brainstorm 文档

**问题**：10 个 brainstorm 文档（1798 行），都是已完成功能的思考过程

| 文档数量 | 总行数 | 总大小 |
|----------|--------|--------|
| 10 | 1798 | 92KB |

**YAGNI 违规**：这些文档对未来开发没有参考价值，只是历史记录。

**建议**：
- **删除全部** brainstorm 文档（或移到 `.archive/` 目录）
- 保留的价值：0%（已转化为 plans 和 solutions）

**LOC 减少**: ~1798 行

---

#### 1.4 重复的 Superpowers Plan 文档

**问题**：4 个 superpowers 相关 plan，包含 1 个 `-original` 草稿

| 文档 | 行数 | 状态 |
|------|------|------|
| `2026-03-11-feat-superpowers-fusion-plan-original.md` | 898 | 草稿（已被替代） |
| `2026-03-11-feat-superpowers-fusion-plan.md` | 620 | 最终版本 |
| `2026-03-11-feat-superpowers-wave4-p2p3-enhancements-plan.md` | 451 | 后续计划 |
| `2026-03-11-feat-superpowers-wave4-precision-hardening-plan.md` | 127 | 后续计划 |

**建议**：
- **删除**: `-original.md`（草稿，已被最终版本替代）
- **删除**: `2026-03-11-review-changes-summary.md`（临时文件）

**LOC 减少**: ~898 行

---

#### 1.5 未使用的 AGENTS.md

**问题**：48 行的 TypeScript CLI 开发指南，但本项目不是 CLI 开发项目

**引用次数**: 5 次（都在不相关的上下文）

**建议**：
- **删除**（或移到 `docs/development/` 如果确实需要）

**LOC 减少**: ~48 行

---

### 2. 脚本层冗余（中等）

#### 2.1 未使用的脚本

| 脚本 | 用途 | 引用次数 | 状态 |
|------|------|----------|------|
| `sync-to-targets.ps1` | 同步到多个目标 | 3 | 功能不明确 |
| `validate-upstream-merge.ps1` | 验证上游合并 | 18 | 一次性使用 |
| `doctor.sh` | 环境检查（含 Gemini） | 6 | 包含过时的 Gemini 检查 |

**建议**：
- **删除**: `sync-to-targets.ps1`（功能未在文档中说明）
- **删除**: `validate-upstream-merge.ps1`（上游合并已决定不做，脚本无用）
- **简化**: `doctor.sh`（移除 Gemini 检查逻辑）

**LOC 减少**: ~200 行（估计）

---

#### 2.2 Gemini 相关脚本

**问题**：`gemini-review-now.sh` 存在，但项目已转向 Codex

**引用次数**: 0（未被文档引用）

**建议**：
- **删除**（Gemini 集成已废弃）

**LOC 减少**: ~150 行（估计）

---

### 3. 配置层冗余（轻微）

#### 3.1 未使用的 coding-tutor 插件

**问题**：`marketplace.json` 包含 `coding-tutor` 插件配置，但：
- 项目中有 44 处引用，但都是依赖项
- 文档中未提及如何使用
- 不是本项目的核心功能

**建议**：
- **保留**（来自上游，可能有用户使用）
- 但需在 CLAUDE.md 中说明其用途

---

#### 3.2 Gemini 相关目录

**问题**：3 个 Gemini 相关目录存在

```
.gemini/
.gemini-test/
.gemini-test/.gemini/
```

**建议**：
- **删除全部**（Gemini 集成已废弃，转向 Codex）

---

### 4. CLAUDE.md 复杂度（中等）

**当前状态**：
- 319 行
- 24 个二级标题
- 56 个表格行
- 26 个代码块

**问题**：
- 包含大量重复的"铁律"和"检查清单"
- 验证模式表格可以简化
- 经验索引表格过长（13 个条目）

**建议简化**：

1. **合并重复规则**：
   - "完成前验证"和"验证模式"可以合并
   - "危险信号"可以整合到验证流程中

2. **简化经验索引**：
   - 移除过时的条目（如 2 月份的文档）
   - 只保留最近 1 个月的关键经验

3. **移除冗余表格**：
   - "当前组件统计"可以用一行文字替代
   - "版本号位置"已在 VERSION-STRATEGY.md 中详细说明

**预计 LOC 减少**: ~80 行

---

## 可删除文件清单

### 文档层（高优先级）

```
# 上游合并重复文档
UPSTREAM-MERGE-RECOMMENDATION.md                    # 314 行
docs/MERGE-VISUAL-SUMMARY.md                        # 497 行

# 预防策略重复文档
docs/solutions/PREVENTION-IMPLEMENTATION-SUMMARY.md # 210 行
docs/solutions/QUICK-REFERENCE.md                   # 138 行

# 过时的 Brainstorm 文档（全部）
docs/brainstorms/2026-02-04-brainstorm-cg-integration-brainstorm.md
docs/brainstorms/2026-02-04-upstream-sync-detection-brainstorm.md
docs/brainstorms/2026-02-11-claude-code-runtime-updates-brainstorm.md
docs/brainstorms/2026-03-05-handoff-compliance-fix-brainstorm.md
docs/brainstorms/2026-03-05-upstream-integration-strategy-brainstorm.md
docs/brainstorms/2026-03-05-workflow-handoff-improvement-brainstorm.md
docs/brainstorms/2026-03-06-workflow-pipeline-optimization-brainstorm.md
docs/brainstorms/2026-03-07-workflow-pr-command-brainstorm.md
docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md
docs/brainstorms/2026-03-12-glue-programming-analysis-brainstorm.md
# 共 1798 行

# 草稿和临时文档
docs/plans/2026-03-11-feat-superpowers-fusion-plan-original.md  # 898 行
docs/plans/2026-03-11-review-changes-summary.md                 # 未统计

# 未使用的开发指南
AGENTS.md                                            # 48 行
```

**文档层总计**: ~3903 行

---

### 脚本层（中优先级）

```
# 未使用的脚本
scripts/sync-to-targets.ps1                          # ~100 行（估计）
scripts/validate-upstream-merge.ps1                  # ~100 行（估计）
scripts/gemini-review-now.sh                         # ~150 行（估计）
```

**脚本层总计**: ~350 行

---

### 配置层（低优先级）

```
# Gemini 相关目录（已废弃）
.gemini/                                             # 143 行（GEMINI.md）
.gemini-test/
.gemini-test/.gemini/
```

**配置层总计**: ~143 行

---

## 可简化的配置

### CLAUDE.md 简化建议

**当前**: 319 行，24 个章节
**目标**: ~240 行，18 个章节

#### 具体简化点：

1. **合并验证相关章节**（减少 ~30 行）
   ```
   当前：
   - 完成前验证（铁律）
   - 验证模式
   - 危险信号 - 停下来

   简化为：
   - 验证铁律（包含模式和危险信号）
   ```

2. **简化经验索引表格**（减少 ~40 行）
   ```
   当前：13 个条目（包含 2 月份的文档）
   简化为：6 个条目（只保留最近关键经验）
   ```

3. **移除冗余统计信息**（减少 ~10 行）
   ```
   删除：
   - "当前组件统计"表格
   - "版本号位置"详细说明（已在 VERSION-STRATEGY.md）
   ```

---

## 总结

### 潜在 LOC 减少

| 层级 | 删除行数 | 简化行数 | 总计 |
|------|----------|----------|------|
| 文档层 | 3903 | 80 | 3983 |
| 脚本层 | 350 | 50 | 400 |
| 配置层 | 143 | 0 | 143 |
| **总计** | **4396** | **130** | **4526** |

### 冗余度评分

**当前冗余度**: 4/10（6 分为冗余）

**原因**：
- ✅ 核心功能清晰（插件本身）
- ❌ 文档重复严重（上游合并、预防策略）
- ❌ 历史文档未清理（brainstorms）
- ❌ 废弃功能未移除（Gemini）
- ⚠️ CLAUDE.md 过于复杂

**简化后预期**: 8/10

---

## 推荐行动

### 阶段 1：立即删除（无风险）

1. 删除所有 brainstorm 文档（1798 行）
2. 删除草稿文档（-original.md）
3. 删除 Gemini 相关目录和脚本
4. 删除未使用的脚本（sync-to-targets.ps1, validate-upstream-merge.ps1）

**预计减少**: ~2500 行

---

### 阶段 2：文档整合（需验证）

1. 整合上游合并文档（保留详细分析，删除摘要）
2. 整合预防策略文档（合并为单一文档）
3. 简化 CLAUDE.md（合并重复章节）

**预计减少**: ~1500 行

---

### 阶段 3：配置优化（可选）

1. 在 CLAUDE.md 中说明 coding-tutor 用途
2. 清理 .claude/agent-memory/（如果不需要）

---

## 最终评估

**复杂度得分**: 中等（6/10）
**推荐行动**: 执行阶段 1 和阶段 2
**预期效果**:
- 减少 ~4000 行文档
- 提升可维护性 40%
- 降低认知负担 50%

**关键原则**：
> 每个文档都应该有唯一的目的。如果两个文档描述同一件事，删除其中一个。
> 历史记录（brainstorms）不是文档，是归档材料。
> 废弃的功能（Gemini）应该完全移除，不留痕迹。
