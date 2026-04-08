# Feature Extensions: 5 个功能扩展探索

**日期**：2026-04-08  
**触发**：来自 docs/analysis/compound-engineering-guide.html 的功能差距分析  
**模式**：派对模式 [P] + Codex 咨询 [C]  
**参与专家**：🏗️ 李明远（架构师）、📊 陈思琪（分析师）、💻 张晓峰（开发者）、🛡️ 赵安全（安全专家）  
**外部咨询**：Codex gpt-5.4（127K tokens）

---

## What We're Building

基于 compound-engineering-guide.html 差距分析，探索 5 个功能扩展的最优实现方案：

1. **`[R]` 研究入口**：在 ce:brainstorm/ce:work 加可选的 learnings-researcher 触发参数
2. **知识索引建设**：创建 `docs/solutions/INDEX.md` + `critical-patterns.md`（Librarian 增强）
3. **Patch Approval 强化**：Codex/Gemini 建议的写入安全控制
4. **Intent Gate 深度访谈**：ce:work Large 任务前的 5 问边界清晰机制
5. **中文 Writer Agent**：技术文档中文写作专家

---

## 现状盘点（研究结论）

| 功能 | 现状 | 差距 |
|------|------|------|
| team-research | 有 7 个专业研究 agent，ce:plan 自动触发，brainstorm/work 无入口 | 用户无法主动触发 |
| Librarian/知识库 | learnings-researcher + context7，37 个 solutions 文档，无 INDEX.md | 结构化程度不足，critical-patterns.md 不存在 |
| Patch Approval | overlay 存在（skills-custom/）但未接通；Codex 返回文本不是 patch；Patch Gate 仅限 [team] 模式 | 安全机制碎片化 |
| Intent Gate | intent-gate skill 存在（skills-custom/）；ce:work Phase 0 有 3 级复杂度路由；无 5 问前置机制 | 大任务前置清晰度不足 |
| 中文 Writer | 完全缺失 | 空白 |

---

## Why This Approach（核心决策）

### 决策 1：Q2 → Q1 顺序（Codex 强化确认）

**先建知识索引，再连入口**——这是 Codex 的关键裁决，与 Claude 初始方案（Q1 先）相反。

**原因**：`[R]` 参数如果在 `docs/solutions/` 无良好结构时触发，会返回噪音。索引建好后，`[R]` 的检索质量才有保证。

**依赖关系**：
```
docs/solutions/INDEX.md + critical-patterns.md  ← 基础设施
         ↓
[R] 参数（brainstorm/work）                     ← 使用入口
         ↓
结果闭合到 Phase 2 方案对比                      ← 信息流完整
```

### 决策 2：Patch Approval 不全局强制，只限外部模型

**不做**：全局 Patch Gate（需要 .team-contract.md，影响非 team 用户）  
**做**：ce:review 整合阶段加规则——所有来自 Codex/Gemini 的建议强制 `autofix_class = "gated_auto"`

**理由**：
- Codex 当前返回文本报告而非 patch，全局隔离沙箱是额外工程
- `[team]` 模式的 Patch Gate 已覆盖合约场景
- 最小代价解决真实安全顾虑：外部 AI 建议永不自动应用

### 决策 3：Intent Gate 仅限 Large 裸提示场景

**不做**：所有 Large 任务都强制 5 问  
**做**：Large complexity + bare prompt（无 plan 文档）时触发 5 问

**理由（Codex 确认）**：有 plan 文档时问 5 问是干扰（plan 已回答这些问题）。只在「用户直接描述需求但没规划」的场景才真正有价值。

### 决策 4：critical-patterns.md 接入 compound-promotion-ladder

**不做**：手工维护 critical-patterns.md  
**做**：接入已有的 `compound-promotion-ladder` skill，当某个 solution 被引用次数超过阈值，自动提示升级为 pattern

**理由**：compound-promotion-ladder 已存在，直接复用。手工维护 critical-patterns 一定会变成死文档。

---

## Key Decisions

### Q1：`[R]` 参数设计

```
ce:brainstorm [R] → Phase 1 开始前触发 learnings-researcher
                    检索结果：标注到 Phase 2 方案对比的「历史参考」节
                    去重机制：同 session 内相同 topic 不重复搜索
                    
ce:work [R] → Phase 0 Input Triage 完成后，bare prompt 场景触发
              检索结果：注入执行上下文（不影响 plan 文档格式）
```

**不做**：完整 team-research 角色（我们的 7 个专业 agent 已经更优）

### Q2：知识索引结构

```
docs/solutions/
├── INDEX.md                    ← 新建：按 problem_type 分类导航
├── patterns/
│   └── critical-patterns.md   ← 新建：高频模式（接入 compound-promotion-ladder 自动更新）
└── （现有 37 个文档不变）
```

`INDEX.md` 格式：每个 problem_type 一节，列出该目录下的文档标题 + 一句话摘要。

### Q3：Patch Approval 强化规则

在 `ce:review/SKILL.md` 的 Codex/Gemini 整合阶段（Stage 5.5）加一条规则：

```
来源为 Codex/Gemini 的所有 finding：
  → 强制 autofix_class = "gated_auto"
  → 不允许 safe_auto（即使 agent 评为低风险）
  → 原因标注："外部 AI 建议需人工确认"
```

### Q4：Intent Gate 5 问模板

触发条件：`ce:work Large complexity + 输入为 bare prompt（非文件路径）`

```
执行前 5 问（AskUserQuestion）：
1. 范围：这次改动的边界是什么？哪些文件/模块在范围内？
2. 约束：有什么不能改的？（pre-defines forbidden_surfaces）
3. 验收：怎么知道做完了？（defines acceptance criteria）
4. 风险：最可能出错的地方是？
5. 回滚：如果失败，如何快速撤销？

实现：inline 在 ce:work SKILL.md Phase 0 的 Large 分支（不建独立 agent，YAGNI）
```

### Q5：中文 Writer Agent 设计

```yaml
name: cn-tech-writer
description: 中文技术文档写作专家。覆盖：技术博客/设计文档/需求文档/架构说明。
             ⚠️ 安全提示：生成内容在发布前需人工审查，避免泄露内部 API 路径、安全配置等敏感信息。
```

覆盖场景：
- 技术博客（结构清晰、深入浅出）
- 设计文档（背景/目标/方案/决策/风险）
- 需求文档（用户故事/验收标准/边界条件）
- 架构说明（组件关系/数据流/部署图说明）

---

## 实施顺序（Claude + Codex 综合推荐）

```
Sprint 1（立即可做，低风险）：
  ① 创建 docs/solutions/INDEX.md + patterns/critical-patterns.md
  ② 接入 compound-promotion-ladder 的自动升级机制说明
  ③ 创建 agents/docs/cn-tech-writer.md（独立，无依赖）
  
Sprint 2（基础设施就绪后）：
  ④ ce:brainstorm 加 [R] 参数（含去重/降噪逻辑）
  ⑤ ce:work 加 [R] 参数（bare prompt 场景）
  ⑥ [R] 结果闭合到 Phase 2 历史参考节

Sprint 3（安全强化）：
  ⑦ ce:review Codex/Gemini 建议强制 gated_auto
  ⑧ ce:work Large + bare prompt 触发 5 问 Intent Gate
```

---

## Open Questions

1. **`[R]` 的去重机制**：如何判断「同 topic」？用 hash 还是语义相似度？简单方案：session 内记录已搜索 keywords，完全匹配则跳过
2. **compound-promotion-ladder 触发阈值**：引用 N 次升级为 pattern？建议 3 次引用触发提示
3. **中文 Writer 与 every-style-editor 的关系**：two tracks（中/英），不合并，各自独立
4. **Intent Gate 5 问是否需要保存为前置合约？** 可以选择性地在无 [team] 模式时生成一个轻量 `.work-intent.md`，但这可能过度工程
5. **Patch Approval gated_auto 的回退路径**：用户确认后如何应用？直接走现有 gated_auto 人工确认流程（已有实现）

---

## Codex 评估（gpt-5.4）

**共识点**（Claude 与 Codex 一致）：
- Q2 → Q1 顺序正确（索引先于入口）
- Patch Approval 不应全局强制，只限外部模型
- 中文 Writer 价值真实，优先级最低

**Codex 独有贡献**（Claude 未覆盖）：
- `[R]` 需要去重/缓存/降噪机制
- `critical-patterns.md` 不能手工维护，需接入 compound-promotion-ladder

**分歧点**：
- Claude 认为中文 Writer 是 P1（容易高价值），Codex 认为优先级最低 → 选择 Codex（因为它依赖其他基础设施最少，但对整体工作流影响也最小，适合并行独立完成，不影响主线）

---

## 遗漏点（派对模式发现）

**陈思琪发现的架构盲点**：brainstorm 里即使加了 `[R]`，检索结果如果没有明确的 handoff 步骤，会被孤立。需要在 ce:brainstorm Phase 1 中明确：`[R]` 的结果作为 Phase 2 的上下文输入，而不是独立的搜索展示。

**赵安全发现的安全盲点**：中文 Writer Agent 的输出可能携带内部敏感信息。Agent frontmatter 需要加明确的安全标注，用户发布前必须人工审查。

---

## Next Step

运行 `/workflows:plan` 将以上决策转化为可执行计划。

优先级：
1. `docs/solutions/INDEX.md` + `critical-patterns.md`（基础设施）
2. `agents/docs/cn-tech-writer.md`（独立，无依赖，可并行）
3. `[R]` 参数接入（ce:brainstorm + ce:work）
4. Patch Approval gated_auto 规则（ce:review）
5. Intent Gate 5 问（ce:work Phase 0）
