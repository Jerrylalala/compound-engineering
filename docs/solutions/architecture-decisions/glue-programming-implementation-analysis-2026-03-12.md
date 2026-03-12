---
date: 2026-03-12
topic: 胶水编程实现方案架构分析
status: completed
tags: [architecture, glue-programming, yagni, documentation, cost-benefit]
---

# 胶水编程实现方案架构分析

## 执行摘要

**结论：当前方案过度工程化，违反 YAGNI 原则。推荐方案 D（最小化实现）。**

| 维度 | 当前方案 | 推荐方案 D |
|------|---------|-----------|
| 文件数量 | 6 个文件 | 2 个文件 |
| 总行数 | ~385 行 | ~100 行 |
| 维护成本 | 高（6 处同步） | 低（2 处同步） |
| 冗余度 | 209 行重复 | 0 行重复 |
| 实际价值 | 低（理念已在全局 CLAUDE.md） | 高（聚焦可执行检查点） |
| YAGNI 评分 | ❌ 违反 | ✅ 符合 |

---

## 问题陈述

### 当前实现（方案 A）

**新增内容：**
1. `.claude/rules/glue-programming.md` - 46 行项目级规则
2. `CLAUDE.md` - 新增"设计哲学：胶水编程"章节（~15 行）
3. `plugins/compound-engineering/CLAUDE.md` - 新增"设计哲学"章节（~10 行）
4. `plugins/compound-engineering/commands/workflows/brainstorm.md` - Phase 1.1b（~16 行）
5. `plugins/compound-engineering/commands/workflows/plan.md` - Step 1.1（~18 行）
6. `plugins/compound-engineering/skills/glue-coding/SKILL.md` - 270 行完整技能
7. `plugins/compound-engineering/skills/glue-coding/references/glue-coding-principles.md` - 70 行速查表
8. `docs/brainstorms/2026-03-12-glue-programming-analysis-brainstorm.md` - 分析文档

**统计：**
- 总文件：8 个（6 个新增/修改 + 2 个 skill 文件）
- 总行数：~445 行
- 冗余内容：209 行（Codex 识别）
- Git 状态：`.claude/rules/glue-programming.md` 未暂存

**Codex 发现的问题：**
- 🔴 文档冗余（209 行重复）
- 🟡 工作流搜索无离线降级
- 🟡 搜索语法混乱
- 🔵 `.claude/rules/glue-programming.md` 未暂存

---

## 架构层面分析

### 1. YAGNI 违反评估

**核心问题：胶水编程理念已在全局 CLAUDE.md 中定义。**

```markdown
# 全局 CLAUDE.md（用户私有配置）
## 胶水编程思维（默认生效）
> 写任何代码之前，先问：GitHub 上有没有人已经做过这个？

### 核心原则
- 凡是能不写的就不写
- 优先使用社区验证过的库
- 自定义代码只做连接

### 执行流程
需求 → 搜索 GitHub 有无现成库 → 有则推荐使用 → 无则自己实现
```

**这意味着：**
- ✅ AI 助手已经知道胶水编程原则（全局生效）
- ✅ 任何编码任务都会自动考虑"有没有现成库"
- ❌ 项目级重复定义是冗余的
- ❌ 工作流中强制检查点是过度工程

### 2. 本项目的特殊性

**本项目本身就是胶水层：**
- 产出物：Skills、Agents、Commands（编排组件）
- 职责：组合 Claude Code、Codex、Gemini、Context7
- 不实现：LLM 推理、代码分析算法、git 功能

**因此：**
- 创建新的 Skill/Agent/Command **不违反**胶水编程原则
- 这些组件**就是**胶水代码本身
- 不需要在工作流中额外检查"是否有现成的 Skill"

### 3. 实际需求分析

**用户真正需要什么？**

| 场景 | 需要 | 不需要 |
|------|------|--------|
| 新项目启动 | 完整架构规划（`/glue-coding` skill） | 项目级规则文件 |
| 日常编码 | 全局思维提醒（已在 CLAUDE.md） | 工作流强制检查点 |
| 技术选型 | 搜索和对比工具（`/glue-coding` skill） | 重复的哲学文档 |
| 添加功能 | 自动考虑现成库（全局生效） | 手动检查清单 |

**结论：**
- `/glue-coding` skill（270 行）- ✅ 有价值，提供完整工作流
- 全局 CLAUDE.md 思维 - ✅ 有价值，自动生效
- 项目级规则文件 - ❌ 冗余
- 工作流检查点 - ❌ 过度工程

---

## 方案对比

### 方案 A：当前实现（多层文档 + 工作流集成）

**结构：**
```
全局 CLAUDE.md（胶水编程思维）
    ↓
项目 CLAUDE.md（设计哲学引用）
    ↓
.claude/rules/glue-programming.md（项目级规则）
    ↓
插件 CLAUDE.md（设计哲学说明）
    ↓
brainstorm.md（Phase 1.1b 检查）
    ↓
plan.md（Step 1.1 检查）
    ↓
/glue-coding skill（完整工作流）
```

**优点：**
- 覆盖全面
- 多层强化

**缺点：**
- ❌ 209 行冗余内容
- ❌ 6 处需要同步维护
- ❌ 违反 YAGNI（理念已在全局）
- ❌ 工作流检查点无离线降级
- ❌ 增加认知负担（用户需要理解层级关系）
- ❌ 本项目特殊性（创建 Skill 不违反原则）被忽视

**维护成本：** 高
**实际价值：** 低（理念已存在）

---

### 方案 B：最小化（只保留全局 CLAUDE.md）

**结构：**
```
全局 CLAUDE.md（胶水编程思维，已存在）
    ↓
/glue-coding skill（完整工作流，已存在）
```

**优点：**
- ✅ 零冗余
- ✅ 最低维护成本
- ✅ 符合 YAGNI
- ✅ 全局自动生效

**缺点：**
- 项目 CLAUDE.md 没有说明本项目的特殊性
- 新贡献者可能不理解"为什么可以创建新 Skill"

**维护成本：** 最低
**实际价值：** 中等

---

### 方案 C：中间态（项目级简单引用）

**结构：**
```
全局 CLAUDE.md（胶水编程思维）
    ↓
项目 CLAUDE.md（2-3 段说明本项目特殊性）
    ↓
插件 CLAUDE.md（1 句话引用）
    ↓
/glue-coding skill（完整工作流）
```

**项目 CLAUDE.md 内容示例：**
```markdown
### 设计哲学：胶水编程

本项目遵循胶水编程原则（详见全局 CLAUDE.md）。

**本项目的特殊性：**
本项目本身就是胶水层——Skills、Agents、Commands 是编排组件，
用于组合 Claude Code、Codex、Gemini 等工具。因此：
- ✅ 创建新的 Skill/Agent/Command 是本项目的核心工作
- ✅ 这些组件就是"胶水代码"本身
- ❌ 不实现 LLM 推理、代码分析、git 功能

完整架构规划见 `/glue-coding` 技能。
```

**优点：**
- ✅ 说明本项目特殊性
- ✅ 避免冗余
- ✅ 清晰的文档层级
- ✅ 低维护成本

**缺点：**
- 仍需维护 2-3 处文档

**维护成本：** 低
**实际价值：** 高

---

### 方案 D：推荐方案（最小化 + 本项目说明）

**结构：**
```
全局 CLAUDE.md（胶水编程思维，已存在）
    ↓
项目 CLAUDE.md（仅说明本项目特殊性，5-8 行）
    ↓
/glue-coding skill（完整工作流，已存在）
```

**删除：**
- ❌ `.claude/rules/glue-programming.md`（46 行）
- ❌ 插件 CLAUDE.md 的"设计哲学"章节（10 行）
- ❌ brainstorm.md Phase 1.1b（16 行）
- ❌ plan.md Step 1.1（18 行）

**保留：**
- ✅ 全局 CLAUDE.md 胶水编程思维（已存在）
- ✅ `/glue-coding` skill（270 行，提供完整工作流）
- ✅ 项目 CLAUDE.md 添加 5-8 行说明本项目特殊性

**项目 CLAUDE.md 新增内容：**
```markdown
### 本项目与胶水编程

本项目本身是胶水层：Skills/Agents/Commands 组合现有工具（Claude Code、Codex、Gemini），
不实现核心逻辑。创建新组件是本项目的核心工作，不违反胶水编程原则。

需要完整架构规划时使用 `/glue-coding` 技能。
```

**优点：**
- ✅ 零冗余（只在必要处说明）
- ✅ 符合 YAGNI（不重复已有内容）
- ✅ 说明本项目特殊性（避免混淆）
- ✅ 最低维护成本（2 处：全局 + 项目）
- ✅ 保留完整工作流（`/glue-coding` skill）
- ✅ 不干扰现有工作流（brainstorm/plan）

**缺点：**
- 无（这是最优解）

**维护成本：** 最低
**实际价值：** 最高

---

## 性价比分析

| 方案 | 投入（行数） | 维护点 | 冗余度 | 实际价值 | 性价比 |
|------|------------|--------|--------|---------|--------|
| A（当前） | ~445 行 | 6 处 | 209 行 | 低 | ❌ 极低 |
| B（最小化） | 0 行 | 0 处 | 0 行 | 中 | ✅ 高 |
| C（中间态） | ~30 行 | 3 处 | 0 行 | 高 | ✅ 高 |
| **D（推荐）** | **~8 行** | **2 处** | **0 行** | **最高** | **✅ 最高** |

**计算：**
- 方案 A：445 行 / 低价值 = 极低性价比
- 方案 D：8 行 / 最高价值 = 最高性价比

---

## 影响范围分析

### 如果采用方案 D，需要调整的文件：

**删除/回滚：**
1. `.claude/rules/glue-programming.md` - 删除整个文件
2. `CLAUDE.md` - 删除"设计哲学：胶水编程"章节（保留引用）
3. `plugins/compound-engineering/CLAUDE.md` - 删除"设计哲学"章节
4. `plugins/compound-engineering/commands/workflows/brainstorm.md` - 删除 Phase 1.1b
5. `plugins/compound-engineering/commands/workflows/plan.md` - 删除 Step 1.1

**保留：**
1. 全局 CLAUDE.md 胶水编程思维（已存在，不动）
2. `/glue-coding` skill 及其 references（已存在，不动）
3. `docs/brainstorms/2026-03-12-glue-programming-analysis-brainstorm.md`（历史记录）

**新增：**
1. 项目 CLAUDE.md - 添加 5-8 行说明本项目特殊性

**Git 操作：**
```bash
# 删除未暂存的规则文件
rm .claude/rules/glue-programming.md

# 回滚工作流修改
git checkout plugins/compound-engineering/commands/workflows/brainstorm.md
git checkout plugins/compound-engineering/commands/workflows/plan.md

# 编辑 CLAUDE.md（项目级和插件级）
# 添加简短说明到项目 CLAUDE.md
```

---

## 长期维护成本

### 方案 A（当前）

**每次更新胶水编程理念时：**
1. 更新全局 CLAUDE.md
2. 更新 `.claude/rules/glue-programming.md`
3. 更新项目 CLAUDE.md
4. 更新插件 CLAUDE.md
5. 检查 brainstorm.md 是否需要调整
6. 检查 plan.md 是否需要调整
7. 更新 `/glue-coding` skill

**总计：7 处需要同步**

**年度维护时间估算：**
- 假设每年更新 2 次理念
- 每次需要 2-3 小时同步 7 处文档
- 年度成本：4-6 小时

---

### 方案 D（推荐）

**每次更新胶水编程理念时：**
1. 更新全局 CLAUDE.md
2. 更新 `/glue-coding` skill（如果涉及完整工作流）

**总计：2 处需要同步**

**年度维护时间估算：**
- 假设每年更新 2 次理念
- 每次需要 30 分钟同步 2 处文档
- 年度成本：1 小时

**节省：5 小时/年（83% 减少）**

---

## 最终推荐

### 推荐方案：D（最小化 + 本项目说明）

**理由：**
1. **符合 YAGNI** - 不重复已有内容（全局 CLAUDE.md）
2. **零冗余** - 每个文件只说明必要内容
3. **最低维护成本** - 只需维护 2 处
4. **最高实际价值** - 说明本项目特殊性，避免混淆
5. **不干扰工作流** - brainstorm/plan 保持简洁
6. **保留完整功能** - `/glue-coding` skill 提供完整工作流

**实施步骤：**
1. 删除 `.claude/rules/glue-programming.md`
2. 回滚 brainstorm.md 和 plan.md 的修改
3. 简化项目 CLAUDE.md 和插件 CLAUDE.md 的"设计哲学"章节
4. 在项目 CLAUDE.md 添加 5-8 行说明本项目特殊性
5. 更新 CHANGELOG.md（记录架构决策）
6. 创建本文档到 `docs/solutions/architecture-decisions/`

**预期效果：**
- 文档总行数：从 ~445 行降至 ~8 行（98% 减少）
- 维护点：从 6 处降至 2 处（67% 减少）
- 冗余内容：从 209 行降至 0 行（100% 消除）
- 实际价值：从低提升至最高

---

## 附录：Codex 发现的其他问题

### 1. 工作流搜索无离线降级

**问题：** brainstorm.md Phase 1.1b 和 plan.md Step 1.1 要求 WebSearch，但无网络失败降级。

**方案 D 的解决方案：** 删除这些检查点，问题自动消失。

**理由：**
- 全局 CLAUDE.md 已有胶水编程思维，AI 会自动考虑
- 不需要在工作流中强制检查
- 避免增加复杂性和失败点

### 2. 搜索语法混乱

**问题：** 不同文件使用不同的搜索语法示例。

**方案 D 的解决方案：** 统一在 `/glue-coding` skill 中定义，其他地方不重复。

### 3. `.claude/rules/glue-programming.md` 未暂存

**问题：** 文件创建但未 `git add`。

**方案 D 的解决方案：** 直接删除该文件，不需要暂存。

---

## 经验教训

### 1. 警惕"理念传播"的过度工程

**反模式：**
- 在多个层级重复相同理念
- 在工作流中强制检查已有的全局思维
- 创建项目级规则文件重复全局配置

**正确做法：**
- 理念在全局定义一次
- 项目级只说明特殊性
- 工作流保持简洁，依赖全局思维

### 2. YAGNI 在文档中同样适用

**问题：**
- 文档也会过度工程化
- 冗余文档比冗余代码更难维护（没有编译器检查）

**解决：**
- 每个文档都要问：这是必要的吗？
- 能引用就不重复
- 能简化就不详述

### 3. 本项目的特殊性需要明确说明

**问题：**
- 胶水编程原则可能让人误以为"不应该创建新 Skill"
- 需要明确：本项目的产出物就是胶水层本身

**解决：**
- 在项目 CLAUDE.md 明确说明本项目特殊性
- 5-8 行足够，不需要长篇大论

---

## 参考资料

- **Codex Review:** 识别出 209 行冗余、工作流搜索无降级等问题
- **全局 CLAUDE.md:** 已定义胶水编程思维（自动生效）
- **`/glue-coding` skill:** 提供完整的架构规划工作流（270 行）
- **YAGNI 原则:** You Aren't Gonna Need It
- **DRY 原则:** Don't Repeat Yourself

---

## 决策记录

**日期：** 2026-03-12
**决策者：** AI 助手（架构分析）
**决策：** 推荐方案 D（最小化 + 本项目说明）
**理由：** 最高性价比、符合 YAGNI、零冗余、最低维护成本
**下一步：** 等待用户确认后实施
