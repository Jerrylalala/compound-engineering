---
title: "Claude Code 2.1.27-2.1.38 运行时更新整合决策"
category: integration-issues
tags: [upstream-sync, agent-teams, memory-frontmatter, hooks, runtime-updates, pdf-pages, fast-mode, claude-code-updates]
date_created: "2026-02-11"
status: implemented
severity: medium
module: plugin-integration
symptoms:
  - "上游 Claude Code 运行时更新评估"
  - "Agent Teams 是否需要深度整合"
  - "memory frontmatter 如何使用"
  - "hooks 系统是否可用"
  - "runtime updates 整合决策"
root_cause: "Claude Code 2.1.27-2.1.38 发布了 10 项更新，需评估对插件的影响"
resolution_type: documentation_update
---

# Claude Code 运行时更新整合决策（2026-02）

## 背景

Claude Code 从 2.1.27（Jan 31）到 2.1.38（Feb 10）发布了 10 项更新。通过五方协作评估（3 Claude 专家 + Codex GPT-5.2 + Gemini 2.5-Pro）确定整合策略。

## 决策总表

| 更新 | 版本 | 决策 | 已执行 | 重新评估条件 |
|------|------|:----:|:------:|-------------|
| Memory frontmatter | 2.1.33 | **做** | v2.42.0 | — |
| PDF pages 参数 | 2.1.30 | **做** | v2.42.0 | — |
| Fast mode 引导 | 2.1.36 | **做** | v2.42.0 | — |
| Agent Teams 深度整合 | 2.1.32 | **观望** | — | 当 Agent Teams 从 experimental 升级为 stable |
| TeammateIdle/TaskCompleted hooks | 2.1.33 | **不做** | — | 当 hooks 系统修复 Windows 兼容性和 type:prompt 支持 |
| `--from-pr` 标志 | 2.1.27 | **不做** | — | 用户明确需要时 |
| `/debug` 端点 | 2.1.30 | **不做** | — | 运行时自动可用，无需插件行动 |
| 68% resume 优化 | 2.1.30 | **不做** | — | 运行时自动获益 |
| VS Code 远程会话 | 2.1.32 | **不做** | — | 非插件职责 |
| Sandbox 安全修复 | 2.1.34 | **不做** | — | 运行时自动获益 |

## 已执行的整合（v2.42.0）

### Memory Frontmatter

**语法**：`memory: project | user | local`（不存在 `false` 或 `long-term`，Codex 验证）

已添加到 6 个 agents：
- 5 × `memory: project`：learnings-researcher、best-practices-researcher、git-history-analyzer、architecture-strategist、repo-research-analyst
- 1 × `memory: user`：framework-docs-researcher（跨项目共享框架知识）

**官方文档**：https://code.claude.com/docs/en/sub-agents

### PDF Pages

document-review skill Step 1 已更新，支持 `Read(pages="1-10")` 分页读取。

### Fast Mode

workflows:review 和 workflows:work 已添加 Performance Tip 提示用户使用 `/fast`。

## 观望中的整合

### Agent Teams

**现状**：已有 `orchestrating-swarms` skill（1718 行）+ `/slfg` 命令，可直接使用 Teams。

**未深度整合的原因**：
1. 官方标注 experimental，API 可能变更
2. 成本高（每个 teammate = 独立 Claude 实例，3 人团队 = 3× 费用）
3. Windows 上 tmux 后端不可用，只有 in-process 模式
4. 现有 Subagent-Driven 模式满足 90% 场景

**可能的试点方向**（当条件成熟时）：
- `/workflows:review-debate`：3 个 reviewer 组成 Team，分歧时互相讨论后达成共识
- `/workflows:full-stack-parallel`：前端/后端/DB 并行开发

**触发条件**：Agent Teams 从 experimental → stable，或用户频繁需要 agents 间通信。

### Hooks 系统

**历史**：hooks.json 实验失败（提交 `9d841bb` 清空），原因：
- `type: "prompt"` 在 SessionStart 不被支持
- `type: "command"` 在 Windows 阻塞终端
- 改用 CLAUDE.md 作为替代方案

**TeammateIdle/TaskCompleted**：只能在 `hooks.json` 或 `plugin.json` 中配置，不能在 .md 中声明。

**触发条件**：Claude Code 修复 hooks Windows 兼容性 + type:prompt 支持。

## 评估方法论

未来评估运行时更新时的分类框架：

| 分类 | 定义 | 插件行动 |
|------|------|---------|
| **运行时自动获益** | 底层优化/安全修复 | 无需行动 |
| **插件声明层** | 通过 frontmatter/hooks 利用 | 评估后添加 |
| **插件编排层** | 需要新 agent/skill/command | 高投入，需验证 ROI |

## 相关文档

- Brainstorm：`docs/brainstorms/2026-02-11-claude-code-runtime-updates-brainstorm.md`
- Plan：`docs/plans/2026-02-11-feat-integrate-runtime-updates-plan.md`
- Hooks 失败记录：`docs/solutions/integration-issues/sessionstart-hook-prompt-type-not-supported.md`
- 上游合并策略：`UPSTREAM-MERGE-RECOMMENDATION.md`
