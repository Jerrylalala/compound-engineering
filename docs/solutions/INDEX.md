---
title: Solutions Index — 知识库导航
description: docs/solutions/ 下所有文档的分类导航，按 problem_type 组织。
updated: 2026-04-08
---

# Solutions Index

> 本索引为手动维护 + compound-promotion-ladder 辅助。
> 新增 solution 文档后，运行 `/ce:compound` 时系统会提示更新本索引。

## 使用方法

- **人工导航**: 按问题类型找到相关文档
- **[R] 参数**: `learnings-researcher` 优先使用 Grep 搜索，本索引作为补充结构
- **compound-promotion-ladder**: 检测到高频模式后提示升级至 `patterns/critical-patterns.md`

---

## 架构决策 (architecture-decisions/)

| 文档 | 一句话摘要 |
|------|-----------|
| [glue-programming-implementation-analysis-2026-03-12](architecture-decisions/glue-programming-implementation-analysis-2026-03-12.md) | 胶水编程思维的实现分析：何时用库、何时写胶水层 |

## 最佳实践 (best-practices/)

| 文档 | 一句话摘要 |
|------|-----------|
| [conditional-visual-aids-in-generated-documents](best-practices/conditional-visual-aids-in-generated-documents-2026-03-29.md) | 生成文档中可视化辅助（图表/流程图）的条件使用规则 |

## 开发者体验 (developer-experience/)

| 文档 | 一句话摘要 |
|------|-----------|
| [branch-based-plugin-install-and-testing](developer-experience/branch-based-plugin-install-and-testing-2026-03-26.md) | 基于分支的插件安装和测试工作流 |
| [local-dev-shell-aliases-zsh-and-bunx-fixes](developer-experience/local-dev-shell-aliases-zsh-and-bunx-fixes-2026-03-26.md) | 本地开发 zsh alias 配置和 bunx 路径修复方案 |

## 集成问题 (integration-issues/)

| 文档 | 一句话摘要 |
|------|-----------|
| [skill-vs-agent-invocation](integration-issues/skill-vs-agent-invocation.md) | Skill 和 Agent 调用的区别和适用场景决策 |
| [subagent-driven-workflow-integration](integration-issues/subagent-driven-workflow-integration.md) | 子代理驱动的工作流集成模式 |
| [marketplace-update-failure-and-unicode-display](integration-issues/marketplace-update-failure-and-unicode-display.md) | Marketplace 更新失败和 Unicode 显示问题的修复 |
| [phantom-agent-references-in-workflows](integration-issues/phantom-agent-references-in-workflows.md) | 工作流中幽灵代理引用的检测和清理 |
| [upstream-sync-integration-workflow](integration-issues/upstream-sync-integration-workflow.md) | 上游同步集成工作流的完整流程 |
| [claude-code-runtime-updates-decisions-2026-02](integration-issues/claude-code-runtime-updates-decisions-2026-02.md) | Claude Code 运行时更新的决策记录（2026-02） |
| [upstream-merge-architectural-analysis-2026-02-10](integration-issues/upstream-merge-architectural-analysis-2026-02-10.md) | 上游合并的架构分析：commands→skills 迁移影响 |
| [sessionstart-hook-prompt-type-not-supported](integration-issues/sessionstart-hook-prompt-type-not-supported.md) | SessionStart hook 中 prompt type 不支持的根因和解决方案 |
| [superpowers-fusion-code-review-2026-03-11](integration-issues/superpowers-fusion-code-review-2026-03-11.md) | Superpowers Fusion 代码审查发现的集成问题 |
| [superpowers-architecture-deep-dive-2026-03-11](integration-issues/superpowers-architecture-deep-dive-2026-03-11.md) | Superpowers 架构深度分析（2026-03-11） |
| [workflows-plan-handoff-command-invocation-clarity-2026-03-11](integration-issues/workflows-plan-handoff-command-invocation-clarity-2026-03-11.md) | workflows:plan Handoff 命令调用清晰度问题 |
| [workflows-brainstorm-party-mode-never-worked-2026-03-11](integration-issues/workflows-brainstorm-party-mode-never-worked-2026-03-11.md) | brainstorm 派对模式从未正常工作的根因分析 |

## 集成方案 (integrations/)

| 文档 | 一句话摘要 |
|------|-----------|
| [agent-browser-chrome-authentication-patterns](integrations/agent-browser-chrome-authentication-patterns.md) | Agent 使用浏览器时的 Chrome 认证模式 |
| [colon-namespaced-names-break-windows-paths](integrations/colon-namespaced-names-break-windows-paths-2026-03-26.md) | 冒号命名空间在 Windows 路径中导致的兼容性问题 |
| [cross-platform-model-field-normalization](integrations/cross-platform-model-field-normalization-2026-03-29.md) | 跨平台 model 字段归一化方案（Codex/Gemini/Claude） |
| [github-native-video-upload-pr-automation](integrations/github-native-video-upload-pr-automation.md) | GitHub 原生视频上传与 PR 自动化集成 |

## Skill 设计 (skill-design/)

| 文档 | 一句话摘要 |
|------|-----------|
| [beta-promotion-orchestration-contract](skill-design/beta-promotion-orchestration-contract.md) | Beta Skill 升级编排合约设计 |
| [beta-skills-framework](skill-design/beta-skills-framework.md) | Beta Skills 框架：实验性功能的分级发布 |
| [claude-permissions-optimizer-classification-fix](skill-design/claude-permissions-optimizer-classification-fix.md) | Claude 权限优化器分类修复 |
| [compound-refresh-skill-improvements](skill-design/compound-refresh-skill-improvements.md) | compound-refresh skill 的改进方案 |
| [discoverability-check-for-documented-solutions-2026-03-30](skill-design/discoverability-check-for-documented-solutions-2026-03-30.md) | 已记录 solution 的可发现性检查机制 |
| [git-workflow-skills-need-explicit-state-machines](skill-design/git-workflow-skills-need-explicit-state-machines-2026-03-27.md) | Git 工作流 Skill 需要显式状态机设计 |
| [pass-paths-not-content-to-subagents](skill-design/pass-paths-not-content-to-subagents-2026-03-26.md) | 向子代理传递路径而非内容的最佳实践 |
| [research-agent-pipeline-separation](skill-design/research-agent-pipeline-separation-2026-04-05.md) | 研究代理流水线分离设计 |
| [script-first-skill-architecture](skill-design/script-first-skill-architecture.md) | Script-First Skill 架构：先脚本后 AI |

## 工作流 (workflow/)

| 文档 | 一句话摘要 |
|------|-----------|
| [manual-release-please-github-releases](workflow/manual-release-please-github-releases.md) | 手动触发 Release Please 和 GitHub Releases 的工作流 |
| [todo-status-lifecycle](workflow/todo-status-lifecycle.md) | Todo 状态生命周期管理（pending→ready→complete） |

## 根目录文档

| 文档 | 一句话摘要 |
|------|-----------|
| [PREVENTION-STRATEGIES](PREVENTION-STRATEGIES.md) | 常见问题预防策略汇总 |
| [prompt-design-analysis-2026-03-12](prompt-design-analysis-2026-03-12.md) | Prompt 设计分析：结构化提示的最佳实践 |
| [adding-converter-target-providers](adding-converter-target-providers.md) | 添加转换器目标提供者的步骤 |
| [agent-friendly-cli-principles](agent-friendly-cli-principles.md) | Agent 友好型 CLI 设计原则 |
| [codex-skill-prompt-entrypoints](codex-skill-prompt-entrypoints.md) | Codex Skill 提示词入口点设计 |
| [plugin-versioning-requirements](plugin-versioning-requirements.md) | 插件版本管理要求和约束 |

---

## 高频模式 (patterns/)

> 从上述 solution 中自动提升的关键模式。

→ 见 [patterns/critical-patterns.md](patterns/critical-patterns.md)
