---
name: plan_review
description: Have multiple specialized agents review a plan in parallel
argument-hint: "[plan file path or plan content]"
---

Have @agent-dhh-rails-reviewer @agent-kieran-rails-reviewer @agent-code-simplicity-reviewer review this plan in parallel.

## Post-Review Actions

审查代理完成后，整合并展示所有审查意见摘要。

然后使用 **AskUserQuestion tool** 呈现选项：

**Question:** "计划审查完成。下一步？"

**Options:**
1. **更新计划后执行** - 根据审查意见修改计划，然后运行 `/workflows:work`（推荐）
2. **直接执行 `/workflows:work`** - 按原计划开始实现
3. **仅更新计划** - 修改计划但暂不执行
4. **重新审查** - 重新运行 `/plan_review`
5. **停止** - 不执行，稍后处理

Based on selection:
- **更新计划后执行** → 根据审查意见修改 plan 文件，修改完成后自动调用 `/workflows:work <plan_path>`
- **直接执行** → 直接调用 `/workflows:work <plan_path>`
- **仅更新计划** → 修改 plan 文件后回到选项菜单
- **重新审查** → 重新调用 `/plan_review <plan_path>`
- **停止** → 结束流程

⚠️ **约束**：选择"更新计划后执行"或"直接执行"时，必须通过 `/workflows:work <plan_path>` 执行计划，不得在主对话中直接编写代码实现计划中的任务。这确保 ≥2 任务时自动启用 Subagent 并行模式。

**注意**：`<plan_path>` 应从调用 `/plan_review` 时传入的参数中获取。如果参数为空，扫描 `docs/plans/*.md` 获取最近修改的计划文件。
