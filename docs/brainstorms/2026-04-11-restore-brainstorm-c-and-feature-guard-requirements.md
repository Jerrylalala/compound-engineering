---
date: 2026-04-11
topic: restore-brainstorm-c-and-feature-guard
---

# 恢复 ce:brainstorm [C] + 功能丢失防护机制

## Problem Frame

1. `ce:brainstorm [C]` 的 Codex 集成在上游架构迁移（commands/ → skills/）时意外丢失。参数声明还在，但 200+ 行实现逻辑（Phase 2.5）消失了 65 天才被发现。
2. 项目由 AI 全权开发，用户不逐行审查，需要自动化机制防止类似功能丢失再次发生。

## Requirements

### 议题 1：恢复 [C][G] 功能

- R1. 将 `98030d3` 版本中的 Phase 2.5 外部 AI 咨询逻辑迁移到当前 `skills/ce-brainstorm/SKILL.md`
- R2. 包含：参数解析（CODEX_ENABLED/GEMINI_ENABLED）、CLI 可用性检查、结构化 prompt 构建、前台调用 Codex、结果整合到文档
- R3. 包含：三方对比表（Claude/Codex/Gemini）、超时降级（5 分钟）、失败不中断主流程
- R4. 适配当前 SKILL.md 的 Phase 结构（旧文件是 commands/ 格式，需适配 skills/ 的 Phase 编号）
- R5. Codex 模型使用当前项目标准：不指定 `-m` 参数，使用 Codex 默认（见 CLAUDE.md Codex 模型策略）

### 议题 2：功能丢失防护

- R6. 参数声明-实现一致性校验脚本：扫描所有 SKILL.md 的 argument-hint 中声明的参数标志（如 `[C]`、`[P]`、`[R]`），检查文件正文是否包含对应实现关键词
- R7. pre-commit hook 集成：SKILL.md 行数骤降超过 30% 时告警
- R8. 上游同步保护：`sync-upstream` 命令增加本地扩展覆盖检测

## Success Criteria

- `/ce:brainstorm [C]` 能正常调用 Codex 并整合结果
- 参数一致性校验脚本能检测出「声明了 [C] 但无实现」的情况
- SKILL.md 行数骤降时 pre-commit hook 阻止提交

## Scope Boundaries

- 不重写 Phase 2.5 逻辑，直接从 git 历史迁移并适配
- 不改 ce:review 的裁决协议（已完善）
- 不改 ce:work 的 [C] 标志（设计为审计标记）

## Key Decisions

- 从 `98030d3` 提取旧代码而非重写（已验证可用 65 天）
- 参数一致性校验用脚本而非 CI（项目无 CI 跑测试）
- 行数骤降检测放在 pre-commit hook（与现有 gitleaks hook 并列）
