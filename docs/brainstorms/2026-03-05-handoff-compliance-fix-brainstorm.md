---
date: 2026-03-05
topic: handoff-compliance-fix
---

# Workflow Handoff 合规修复

## What We're Building

修复 7 个 workflow 命令的 Handoff 协议合规问题，建立协议分级制度（主链档 vs 工具档）。

## Why This Approach

### 问题现状

在建立 Handoff 协议（6 条规则）后，对 9 个命令全面审查发现仅 2 个完全合规（work.md、compound.md），7 个存在不同程度问题。

最常见问题：
1. 缺少 `Based on selection:` 行为约束（4个文件）
2. 英文描述未改中文（4个文件）
3. 第一选项不是流程下一步命令（3个文件）

### 评估的方案

| 方案 | 描述 | 结论 |
|------|------|------|
| A: 仅修高优先级 | 只修缺行为约束的 4 个文件 | 不够 — 语言不统一 |
| B: 全面统一修复 | 一次性修完 7 个文件 | 中等 — 但缺分级 |
| **C: 协议分级 + 全面修复** | **分主链档/工具档 + 修完全部** | **最终选定** |

### 最终方案：协议分级

| 档位 | 适用命令 | 规则要求 |
|------|----------|----------|
| **主链档** | brainstorm, plan, work, review, compound | 6 条全满足 |
| **工具档** | load, sync-upstream, deepen-plan, plan_review | 至少满足规则 2/4/5 |

主链档：严格遵循全部 6 条协议
工具档：至少满足 AskUserQuestion(规则2) + 停止选项(规则4) + 行为约束(规则5)，规则 1(Handoff命名)/3(首选项)/6(中文) 宽松

## Key Decisions

### 1. 一次性修完 7 个文件（三方一致）

避免分批管理开销，每个文件改动量小（补几行文本）。

### 2. plan.md 重排选项但保留全部（三方一致）

将 `/workflows:work` 调到第一位，补"停止"选项，保留 7+1 个选项。不做两层菜单（AskUserQuestion 不支持嵌套）。

### 3. load.md 合并两个 Handoff 为统一出口（三方一致）

减少分叉状态，通过条件化选项保留原有能力。

### 4. sync-upstream 不完全豁免（Codex + Party Mode 一致）

独立工具也需 Based on selection 约束，但"首选项必须是主链下一步"可放宽。

### 5. plan_review 不改标题（Party Mode 一致）

已是所有文件中 Handoff 质量最好的（有 ⚠️ 约束），仅差命名。改动价值为零。

### 6. lint 脚本增强（Codex 建议采纳）

现有 check-handoff.sh 只检查 AskUserQuestion 会产生"假通过"。增加检查 `Based on selection`。

## 具体改动清单

| 文件 | 修复内容 |
|------|----------|
| brainstorm.md | 补 `Based on selection:` + 中文化 Question/选项 |
| plan.md | 重排选项（work 第一）+ 补"停止"选项 + 中文化 + 标题改 Handoff |
| review.md | 补 `Based on selection:` 3 行 |
| load.md | 合并两个 Handoff 为统一出口 + 补 `Based on selection:` + 中文化 |
| sync-upstream.md | 补 `Based on selection:` |
| deepen-plan.md | 重排选项（plan_review 第一）+ 补"停止"选项 + 中文化 |
| check-handoff.sh | 增加检查 `Based on selection` |
| CLAUDE.md | 更新 Handoff 协议，加入分级制度 |

## 外部 AI 咨询结果

| 评估维度 | Claude Party Mode | Codex (gpt-5.3) | 共识度 |
|----------|-------------------|------------------|:------:|
| 一次性修完 | 推荐 | 推荐 | 一致 |
| 协议分级 | 未提出 | 建议主链/工具分档 | 采纳 |
| plan.md 两层菜单 | 不支持 | 建议 | 不采纳 |
| load.md 合并 | 推荐 | 推荐 | 一致 |
| lint 增强 | 未提出 | 建议检查更多规则 | 采纳 |
| 命名空间统一 | 未讨论 | 建议未来重构 | 记录 |

## Open Questions

- 命名空间不一致（/deepen-plan vs /workflows:*）是否需要在本轮修复？（建议：不改，记录为未来优化）

## Next Steps

→ `/workflows:plan` 将此设计转化为实施计划
