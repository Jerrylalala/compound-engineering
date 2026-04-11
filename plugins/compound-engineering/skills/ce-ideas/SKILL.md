---
name: ce:ideas
description: "管理想法停车场 IDEAS.md：无参数时展示并推荐已有想法，有参数时生成新方向"
argument-hint: "[功能方向或关注点，留空则从 IDEAS.md 选]"
---

# Ideas 管理命令

**Note: The current year is 2026.** Use this when dating new entries added to IDEAS.md.

`ce:ideas` 是想法停车场的统一入口：
- **无参数**：展示 IDEAS.md，推荐优先方向，引导进入 brainstorm
- **有参数**：针对该方向生成新改进建议（原 ideate 行为），结束时询问是否存入 IDEAS.md

IDEAS.md 路径：`IDEAS.md`（项目根目录）

## Interaction Method

使用平台的阻塞问答工具（Claude Code 中为 `AskUserQuestion`）。每次只问一个问题，优先使用单选。

## Focus Argument

<focus_argument> #$ARGUMENTS </focus_argument>

---

## Execution Flow

### Phase 0: 路由检测

检测 `$ARGUMENTS` 是否有实质内容（去除空格后为空 = 无参数）：

- **无参数** → 进入 **Phase 1A（停车场路径）**
- **有参数** → 进入 **Phase 1B（生成路径）**

---

### Phase 1A: 停车场路径（无参数）

**目标**：展示 IDEAS.md，帮用户从已有想法中选一个方向。

#### 1A.1 读取 IDEAS.md

读取项目根目录的 `IDEAS.md`。

- 若文件不存在 → 提示「IDEAS.md 还没有内容，帮你生成第一批想法」→ 跳转 **Phase 1B**（无 focus_argument，open-ended）
- 若文件存在但无未完成条目（`- [ ]` = 0）→ 提示「IDEAS.md 的所有想法都已完成，帮你生成新方向」→ 跳转 **Phase 1B**

#### 1A.2 展示并推荐

展示所有未完成条目（`- [ ]`），格式：

```
IDEAS.md 中有 N 个待执行方向：

1. **[想法标题]** — [简短描述]
   来源：[来源链接]

2. **[想法标题]** — [简短描述]
   来源：[来源链接]

...

推荐优先探索（前 2-3 个）：
⭐ [序号]. [理由，1 句话]
⭐ [序号]. [理由，1 句话]
```

**推荐排序逻辑**（简单启发式）：
1. 来源文件近期（近 30 天）且仍存在 → 优先级高
2. 来源文件明确标记 `active` → 优先级高
3. 其余按出现顺序

#### 1A.3 AskUserQuestion

使用 `AskUserQuestion` 询问：

> 「IDEAS.md 中有 [N] 个待执行方向。你想怎么做？」

选项：
1. 选择一个方向（输入序号或名称）→ 进入 **Phase 2（handoff）**，以选中方向为目标
2. 生成新想法 → 跳转 **Phase 1B**
3. 退出

---

### Phase 1B: 生成路径（有参数，或从 1A 跳转）

**目标**：针对给定方向生成新改进建议，参考 `ce-ideate` 的生成逻辑。

#### 1B.1 准备 focus

- 若从 Phase 1A 跳转（原本无参数）→ 用 `AskUserQuestion` 询问：「你想探索哪个方向？描述一下」
- 若有原始 focus_argument → 直接使用

#### 1B.2 快速仓库扫描

派发一个 haiku model 子代理（快速扫描，省 token）：

> 读取项目的 AGENTS.md 或 CLAUDE.md，再扫描顶层目录结构（Glob pattern `*` 和 `*/*`）。返回不超过 20 行的简报：项目形态（语言/框架/目录布局）、明显痛点和杠杆点。
> Focus: {focus}

#### 1B.3 生成候选方向

基于扫描结果，针对 focus 生成 5-8 个有根据的改进方向候选，每个包含：
- 标题（简短）
- 1-2 句描述（说清楚做什么、为什么有价值）
- 关键风险或依赖

#### 1B.4 批判过滤

对候选列表批判筛选：
- 去除重复现有功能的
- 去除与已有 IDEAS.md 条目高度重叠的（读取 IDEAS.md 对比）
- 去除当前阶段不现实的（依赖缺失、工作量极大且收益低）

保留 3-5 个最有价值的，按「价值 / 实现成本」排序输出。

#### 1B.5 展示结果

```
针对「[focus]」的改进方向建议：

🥇 [标题]
   [描述]
   风险：[简要]

🥈 [标题]
   [描述]
   风险：[简要]

...
```

进入 **Phase 2（handoff）**。

---

### Phase 2: Handoff

用户已选中一个方向（来自 Phase 1A 或 Phase 1B）后执行此阶段。

#### 2.1 询问是否存入 IDEAS.md

**仅当选中方向不在 IDEAS.md 中时询问**（Phase 1A 选中的已有条目跳过此步）：

使用 `AskUserQuestion`：

> 「是否将「[选中方向标题]」存入 IDEAS.md，以便下次继续？」

选项：
1. 存入 IDEAS.md → 追加条目，格式：
   ```
   - [ ] **[标题]**：[1 句描述]
     来源：[当前日期，格式 YYYY-MM-DD]
   ```
   写入到 `IDEAS.md` 末尾的最合适分类下（若有对应分类）或末尾新增。
2. 不存入，直接继续

#### 2.2 引导进入 brainstorm

无论是否存入，都引导进入 brainstorm：

```
Invoke skill compound-engineering:ce-brainstorm with args: [选中方向描述]
```
