# 最终决策：收缩式整合

**决策日期**: 2026-03-12
**决策原则**: 收缩而非扩张，取舍而非保留

---

## 核心判断修正

**之前的判断**: "项目架构是 10/10，但文档和组件的过度工程导致效率低下"
**修正后判断**: "核心架构强，但外围上下文系统膨胀"

**关键洞察**: 问题不是"需要更多分析"，而是"需要删除冗余"。

---

## 最终决策结果

### 1. 保留为默认入口的清单

**项目根目录**:
- `CLAUDE.md` - 精简后（删除冗余检查清单、组件统计、长表格）
- `README.md` - 保持不变

**核心文档**:
- `docs/zh-CN/INSTALL.md` - 安装指南
- `docs/zh-CN/WORKFLOW-VISUAL.md` - 工作流可视化（唯一入口）
- `docs/zh-CN/VERSION-STRATEGY.md` - 版本管理（唯一入口）

**插件核心**:
- `plugins/compound-engineering/CLAUDE.md` - 精简后（删除开发者检查清单）
- `plugins/compound-engineering/README.md` - 保持不变

**总计**: 6 个默认入口文档

---

### 2. 保留但降级为参考的清单

**解决方案库**（按需搜索，不默认加载）:
- `docs/solutions/integration-issues/*.md` - 保留最详细版本
- `docs/solutions/PREVENTION-STRATEGIES.md` - 唯一预防策略文档

**开发文档**（开发者参考）:
- `docs/development/VERSIONING.md`
- `docs/zh-CN/CONCEPTS.md`
- `docs/zh-CN/SCRIPTS.md`
- `docs/zh-CN/SYNC.md`
- `docs/zh-CN/FORK-SETUP.md`

**分析报告**（已在 .gitignore，保留为历史参考）:
- `docs/analysis/*.md` - 全部保留但不加载

**总计**: ~20 个参考文档

---

### 3. 归档或删除的清单

#### P0: 立即删除（无风险）

**废弃功能**:
```bash
rm -rf .gemini/
rm -rf .gemini-test/
rm scripts/gemini-review-now.sh
rm scripts/doctor.sh  # 包含过时 Gemini 检查
```

**过时文档**:
```bash
rm -rf docs/brainstorms/  # 1,798 行
rm docs/plans/*-original.md  # 898 行
rm docs/plans/*-summary.md
```

**未使用脚本**:
```bash
rm scripts/validate-upstream-merge.ps1
rm scripts/sync-to-targets.ps1
```

**重复文档**:
```bash
# 上游合并主题（保留详细版）
rm UPSTREAM-MERGE-RECOMMENDATION.md
rm docs/MERGE-VISUAL-SUMMARY.md
# 保留: docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md

# 预防策略主题（保留唯一版）
rm docs/solutions/PREVENTION-IMPLEMENTATION-SUMMARY.md
rm docs/solutions/QUICK-REFERENCE.md
# 保留: docs/solutions/PREVENTION-STRATEGIES.md
```

**未使用文档**:
```bash
rm AGENTS.md  # 48 行，TypeScript CLI 开发指南（不相关）
```

**总计删除**: ~4,000 行

---

#### P1: 精简主规则文档

**全局 CLAUDE.md** (`~/.claude/CLAUDE.md`):
- 删除: "UI 设计理念" 章节（156-180 行）- 与 CLI 插件无关
- 删除: "交互提醒" 硬编码路径（16-28 行）- 改为原则性声明
- 保留: 胶水编程思维、执行戒律、代码品味

**项目 CLAUDE.md**:
- 删除: "当前组件统计" 表格（107-114 行）- 硬编码，需手动维护
- 删除: "更新检查清单" 三重冗余（182-215 行）- 只保留自动化工具入口
- 删除: "经验与解决方案索引" 长表格（249-266 行）- 改为"使用 Grep 搜索"
- 简化: "目录结构" 图（132-160 行）- 只保留关键路径
- 保留: "本项目的特殊性"、Codex 审核说明

**插件 CLAUDE.md** (`plugins/compound-engineering/CLAUDE.md`):
- 删除: "Skill Compliance Checklist"（249-280 行）- 移到开发文档
- 删除: "危险信号表" 冗余部分（40-52 行）- 精简为 3-5 个核心信号
- 简化: "Workflow 命令列表" 双命名说明（162-179 行）- 移到用户文档
- 保留: 技能检查协议（1% 规则）、Workflow Handoff 协议

**预期效果**: CLAUDE.md 总 Token 从 3,280 → ~2,000 (-39%)

---

### 4. 实际改动说明

#### 阶段 1: 删除废弃内容（5 分钟）

```bash
# 删除废弃功能
rm -rf .gemini/ .gemini-test/
rm scripts/gemini-review-now.sh
rm scripts/doctor.sh

# 删除过时文档
rm -rf docs/brainstorms/
rm docs/plans/2026-03-11-feat-superpowers-fusion-plan-original.md
rm docs/plans/2026-03-11-review-changes-summary.md

# 删除未使用脚本
rm scripts/validate-upstream-merge.ps1
rm scripts/sync-to-targets.ps1

# 删除重复文档
rm UPSTREAM-MERGE-RECOMMENDATION.md
rm docs/MERGE-VISUAL-SUMMARY.md
rm docs/solutions/PREVENTION-IMPLEMENTATION-SUMMARY.md
rm docs/solutions/QUICK-REFERENCE.md

# 删除不相关文档
rm AGENTS.md
```

**验收**: `git status` 应显示 ~4,000 行删除

---

#### 阶段 2: 精简主规则文档（15 分钟）

**全局 CLAUDE.md**:
1. 删除第 156-180 行（UI 设计理念）
2. 简化第 16-28 行（交互提醒）

**项目 CLAUDE.md**:
1. 删除第 107-114 行（组件统计表格）
2. 替换第 182-215 行为：
   ```markdown
   ## 更新插件

   **推荐**: `scripts/bump-version.ps1 -BumpType patch`
   **手动**: 见 [版本管理预防策略](docs/zh-CN/VERSION-STRATEGY.md)
   ```
3. 替换第 249-266 行为：
   ```markdown
   ## 经验库

   使用 Grep 搜索：
   - 全局: `~/.compound/solutions/`
   - 项目: `docs/solutions/`
   ```
4. 精简第 132-160 行（目录结构）

**插件 CLAUDE.md**:
1. 删除第 249-280 行（Skill Compliance Checklist）
2. 精简第 40-52 行（危险信号表）
3. 简化第 162-179 行（双命名说明）

**验收**: CLAUDE.md 总字数从 2,451 → ~1,500 words (-39%)

---

#### 阶段 3: 提交更改（5 分钟）

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

---

### 5. 如果只做 20% 工作，最值得先做的 3 件事

#### 第 1 件: 删除 docs/brainstorms/（5 分钟）

```bash
rm -rf docs/brainstorms/
```

**收益**:
- 删除 1,798 行过时文档
- 减少认知负担
- 无风险（已转化为 plans 和 solutions）

**ROI**: 极高 ⭐⭐⭐⭐⭐

---

#### 第 2 件: 删除重复的上游合并文档（2 分钟）

```bash
rm UPSTREAM-MERGE-RECOMMENDATION.md
rm docs/MERGE-VISUAL-SUMMARY.md
```

**收益**:
- 删除 811 行重复内容
- 保留唯一权威版本
- 单入口原则

**ROI**: 极高 ⭐⭐⭐⭐⭐

---

#### 第 3 件: 精简项目 CLAUDE.md 的更新检查清单（5 分钟）

替换第 182-215 行为 2 行：
```markdown
**推荐**: `scripts/bump-version.ps1 -BumpType patch`
**手动**: 见 [版本管理预防策略](docs/zh-CN/VERSION-STRATEGY.md)
```

**收益**:
- 减少 ~200 tokens
- 消除三重冗余
- 单入口原则

**ROI**: 高 ⭐⭐⭐⭐

---

**总计时间**: 12 分钟
**总计收益**: 删除 ~2,600 行，减少 ~200 tokens
**ROI**: 极高

---

## 与之前分析的对比

### 之前的方案（扩张式）

- ❌ 生成 6 个新的分析报告
- ❌ 提出三阶段优化路线图
- ❌ 建议索引化架构（Phase 2）
- ❌ 建议使用监控（Phase 3）
- ❌ 总消耗 ~506K tokens 分析

**问题**: 用"更多分析"解决"分析过多"的问题

---

### 现在的方案（收缩式）

- ✅ 删除 ~4,000 行冗余文档
- ✅ 精简主规则文档 ~1,200 tokens
- ✅ 单入口原则
- ✅ 不动核心架构
- ✅ 12 分钟拿最大收益

**原则**: 用"删除冗余"解决"上下文膨胀"的问题

---

## 最终判断

### 之前的分析是否是最优解？

**答案**: ❌ 不是

**原因**:
1. **方向错误**: 用"增量补丁"而非"收缩整合"
2. **过度分析**: 生成 6 个新报告，增加上下文负担
3. **优先级错误**: Phase 2/3 是架构重构，不是最小改动
4. **ROI 错误**: 花 506K tokens 分析，实际只需 12 分钟删除

### 正确的方案

**核心原则**: 收缩而非扩张

**执行顺序**:
1. P0: 删除废弃内容（5 分钟）
2. P0: 精简主规则文档（15 分钟）
3. P1: 收敛重复专题文档（10 分钟）
4. P2: 智能跳过（按需）

**总计时间**: 30 分钟
**总计收益**: 删除 ~4,000 行，减少 ~1,200 tokens

---

## 下一步行动

**立即执行**（今天）:
1. 删除 docs/brainstorms/
2. 删除重复的上游合并文档
3. 精简项目 CLAUDE.md 的更新检查清单

**本周执行**:
4. 删除所有废弃 Gemini 内容
5. 精简全局和插件 CLAUDE.md
6. 删除重复的预防策略文档

**暂不执行**:
- ❌ 索引化架构（Phase 2）
- ❌ 使用监控（Phase 3）
- ❌ 生成更多分析报告

---

**决策人**: Claude Opus 4.6
**审核人**: Codex（收缩式整合原则）
**最终确认**: 待用户批准
