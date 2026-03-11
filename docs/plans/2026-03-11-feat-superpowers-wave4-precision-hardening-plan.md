---
title: "feat: Superpowers Wave 4 精准手术 — 一致性修复 + 关键路径硬化"
type: feat
date: 2026-03-11
risk_score: 1
risk_level: low
risk_note: "纯 Markdown 文件修改，完全可逆，无外部依赖"
brainstorm: docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md
---

# Superpowers Wave 4: 精准手术 — 一致性修复 + 关键路径硬化

## Overview

**Goal**: 基于 Claude 三专家辩论 + Codex 分析的综合共识，对 v2.44.0 融合成果做精准增强
**Tech Stack**: Markdown（Skills + Commands）

## 背景

v2.44.0 已完成 Superpowers Wave 1-3 融合。本次 Wave 4 是多方分析后的精准手术：
- Claude 三专家辩论（极简主义者 + 质量工程师 + 实用主义架构师）
- Codex 架构分析（发现一致性问题）
- 综合共识：仅在关键安全节点硬化，其他保持 CE 灵活设计

(see brainstorm: docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md)

## Acceptance Criteria

- [x] `finishing-a-feature` 的 3 个断裂链接全部修复
- [x] `finishing-a-feature` 的 description 格式符合插件规范
- [x] 测试验证步骤从"建议"升级为"阻断"（不提供跳过选项）
- [x] `git-worktree` 创建后添加基线测试提醒
- [x] `workflows:work` 标准模式添加 TDD 触发提醒
- [x] 版本号更新 2.44.0 → 2.44.1
- [x] CHANGELOG.md 更新

## Tasks

### Task 1: 修复 finishing-a-feature 断裂链接 + description 格式

**文件**: `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md:2-3,105-109`
**操作**:
- [x] 修复 description 为 "This skill should be used when..." 格式
- [x] 修复关联技能链接（3 个全部断裂）

**代码**:
```yaml
# frontmatter description 修复
description: This skill should be used when completing a feature branch and deciding how to integrate changes (merge, PR, or push). It verifies tests, presents options, and cleans up worktrees.
```

```markdown
# 关联技能链接修复
## 关联技能

- [git-worktree](../git-worktree/SKILL.md) - Worktree 管理
- [test-driven-development](../test-driven-development/SKILL.md) - TDD 流程
- [workflows:work](../../commands/workflows/work.md) - 工作流执行
```

**验证**:
- [x] 检查 3 个链接路径是否存在

### Task 2: 关键路径硬化 — 测试验证阻断

**文件**: `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md:30`
**操作**:
- [x] 将 "如果测试失败，停止流程并修复问题。" 替换为阻断语言

**代码**:
```markdown
**铁律：测试失败 = 流程终止。**

不提供"继续"或"跳过"选项。修复所有测试后重新进入此流程。
```

**验证**:
- [x] 确认文件中不再有"跳过"相关选项

### Task 3: Worktree 基线测试提醒

**文件**: `plugins/compound-engineering/skills/git-worktree/SKILL.md:96-99`
**操作**:
- [x] 在 `create` 命令的 "What happens" 列表末尾添加基线测试提醒步骤

**代码**:
```markdown
6. **（推荐）运行基线测试验证环境**：
   ```bash
   # 在新 worktree 中验证环境完整性
   npm test --bail 2>/dev/null || echo "⚠️ 基线测试失败，环境可能需要额外配置（检查依赖安装、数据库迁移等）"
   ```
   如果基线测试失败，先解决环境问题再开始开发，否则后续所有测试结果不可信。
```

**验证**:
- [x] 确认新步骤添加在 step 5 之后

### Task 4: Work 标准模式 TDD 触发提醒

**文件**: `plugins/compound-engineering/commands/workflows/work.md:191-206`
**操作**:
- [x] 在标准模式的 Task Execution Loop 开头添加 TDD 触发提醒

**代码**:
```markdown
   > **TDD 提醒**：如果当前任务涉及新功能实现或 bug 修复，在编写任何代码前先调用 `test-driven-development` skill 写失败测试。
```

**验证**:
- [x] 确认提醒位于 execution loop 代码块前

### Task 5: 版本号更新 + CHANGELOG

**文件**: `.claude-plugin/marketplace.json`, `plugins/compound-engineering/.claude-plugin/plugin.json`, `plugins/compound-engineering/CHANGELOG.md`
**操作**:
- [x] 版本号 2.44.0 → 2.44.1
- [x] CHANGELOG 添加 Wave 4 记录

**验证**:
- [x] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致

## References

- [Superpowers 融合 Brainstorm](../brainstorms/2026-03-11-superpowers-fusion-brainstorm.md)
- [Superpowers 融合代码审查](../solutions/integration-issues/superpowers-fusion-code-review-2026-03-11.md)
- [Superpowers 架构深度分析](../solutions/integration-issues/superpowers-architecture-deep-dive-2026-03-11.md)
