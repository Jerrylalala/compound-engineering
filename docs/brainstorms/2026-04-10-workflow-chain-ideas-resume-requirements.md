---
date: 2026-04-10
topic: workflow-chain-ideas-resume
---

# 工作流链路重构：IDEAS.md + /ce:ideas + /ce:resume

## Problem Frame

独立开发者间歇性回到项目时，面临三个断点：

1. **创意断点**：早期 brainstorm 里构想了很多方向，但没有执行的都散落在各个文件里，下次回来已经不记得
2. **入口断点**：没有"我回来了，从哪开始？"的统一入口，每次要手动翻 git log 和计划文件定向
3. **链路错位**：现有工作流假设从创意出发，但 bug 修复、已知任务等场景根本不需要创意阶段，缺少旁路

当前 `/ce:ideate` 和拟议中的 `/ce:next` 功能高度重叠，单独成命令增加认知负担。

## Requirements

**IDEAS.md — 想法停车场（幕后机制）**
- R1. 项目根目录创建 `IDEAS.md`，格式：每条一行 + 简要描述 + 来源链接
- R2. 条目包含：想法标题、1-2 句描述、来源文档链接（repo-relative）、记录日期
- R3. 完成的条目打 `[x]` 或删除；文件永远保持精简（目标 < 50 行）
- R4. `IDEAS.md` 是文件机制，不出现在工作流命令链路中

**`/ce:ideas` — ideate + next 合并命令（新增）**
- R5. 无参数时：展示 IDEAS.md 当前内容，推荐优先级最高的 2-3 个，引导选择进入 brainstorm
- R6. 有参数时（如 `/ce:ideas 性能优化`）：针对该方向生成新改进建议（原 ideate 行为）
- R7. 生成新想法后，询问是否存入 IDEAS.md；用户选"是"则追加到文件
- R8. brainstorm 结束时，若有旁支想法未被采纳，提示用户是否存入 IDEAS.md

**`/ce:resume` — 回归入口（新增，移至链路起点）**
- R9. 读取 git log 最近 5 条提交，识别上次工作内容
- R10. 读取 IDEAS.md，列出待处理条目数量
- R11. 扫描 docs/plans/ 中有未完成 checkbox 的最新计划文件
- R12. 输出三段式摘要：上次做了什么 / 有什么在等待 / 建议下一步是什么
- R13. 提供选项让用户直接跳入：继续上次任务 / 从 IDEAS.md 选 / 全新开始

**链路旁路（已知任务 / bug 修复）**
- R14. `/ce:plan` 和 `/ce:work` 可直接调用，不强制经过 ideate/brainstorm
- R15. CLAUDE.md 和文档中明确说明三条入口路径（见 Key Decisions）

## Success Criteria

- 用户回到项目，运行 `/ce:resume` 在 30 秒内知道"我上次在哪，下一步做什么"
- 早期 brainstorm 中未执行的方向，90% 能在 IDEAS.md 中找到对应条目
- bug 修复类任务可以直接 `/ce:plan` 开始，无需经过创意阶段

## Scope Boundaries

- **不做**：IDEAS.md 自动维护（AI 不主动写入，只在用户确认时写）
- **不做**：IDEAS.md 与 GitHub Issues 同步
- **不做**：`/ce:resume` 自动在每次会话开始时触发（只在用户主动调用时运行）
- **不做**：想法老化提醒机制（可作为未来扩展放入 IDEAS.md）
- `/ce:next` 不作为独立命令实现，其功能完全由 `/ce:ideas` 覆盖

## Key Decisions

- **resume 是入口不是出口**：Party Mode + Codex 一致认定，`/ce:resume` 应作为回归项目的起点，而非链路末尾
- **ideate + next 合并为 /ce:ideas**：两者功能重叠（生成方向 vs 选择方向），合并后用参数区分行为，减少命令数量
- **IDEAS.md 是机制不是节点**：文件不出现在可见的工作流链路里，是命令之间的隐式共享状态
- **三条入口路径**：A）`resume` 回归定向 → 任意节点；B）`ideas` + `brainstorm` 全新创意路径；C）`plan` 直接入口（已知任务/bug）

## Dependencies / Assumptions

- `ideate` skill 文件（`skills/ce-ideate/SKILL.md`）已存在，`/ce:ideas` 命令在其基础上扩展
- `IDEAS.md` 第一版内容需从现有 22 个 brainstorm 文件 + 55 个 plan 文件中提取未执行方向

## Outstanding Questions

### Resolve Before Planning

- `/ce:ideas` 无参数时，如果 IDEAS.md 为空（全新项目），应该默认触发 ideate 行为还是提示"还没有想法，先运行 /ce:ideate 或描述一个方向"？

### Can Resolve During Planning

- `/ce:resume` 扫描 plan 文件时，如何判断"未完成"——是检测未勾选的 checkbox，还是读取 frontmatter 的 status 字段？
