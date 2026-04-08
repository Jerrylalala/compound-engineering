---
title: Surface Inventory — 文件归属标记
created_at: "2026-04-08"
phase: P1-0
status: active
---

# Surface Inventory

> **目的**：在执行上游合并（P1-1 ~ P1-3）前，标清每个文件的归属，确定合并策略。
>
> 我们落后上游 **442 commits**（截至 2026-04-08）。

## 标记说明

| 标记 | 含义 | 合并策略 |
|------|------|----------|
| `[U]` | 上游拥有，本地未改 | 直接 fast-forward，接受上游版本 |
| `[UM]` | 上游拥有，本地有修改 | 需要三方合并，保留本地中文定制 |
| `[L]` | 本地新增（在上游目录中） | 合并后需手动确认是否保留 |
| `[P]` | 私有 Overlay（`skills-custom/`） | 永远不与上游冲突，无需处理 |
| `[R]` | 上游已重命名 | 本地旧名 → 上游新名，需迁移 |
| `[D]` | 上游已删除整个目录/文件 | 本地保留需明确决策 |

---

## plugins/compound-engineering/

### 根文件

| 文件 | 归属 | 备注 |
|------|------|------|
| `.claude-plugin/plugin.json` | `[UM]` | 本地版本号与上游不同 |
| `CHANGELOG.md` | `[UM]` | 本地有中文条目 |
| `CLAUDE.md` | `[UM]` | 本地有中文开发指南（重要！） |
| `LICENSE` | `[U]` | 无修改 |
| `README.md` | `[UM]` | 本地有中文说明 |

**上游新增，本地缺失：**
- `.cursor-plugin/plugin.json` — Cursor 插件支持
- `AGENTS.md` — Codex/Agent 入口文件

---

### agents/

#### agents/design/ — `[U]` 三个文件均同步
- `design-implementation-reviewer.md`
- `design-iterator.md`
- `figma-design-sync.md`

#### agents/docs/ — `[U]`
- `ankane-readme-writer.md`

#### agents/document-review/ — **上游新增，本地全部缺失** `[新增]`
- `adversarial-document-reviewer.md`
- `coherence-reviewer.md`
- `design-lens-reviewer.md`
- `feasibility-reviewer.md`
- `product-lens-reviewer.md`
- `scope-guardian-reviewer.md`
- `security-lens-reviewer.md`

#### agents/research/
| 文件 | 归属 | 备注 |
|------|------|------|
| `best-practices-researcher.md` | `[U]` | |
| `framework-docs-researcher.md` | `[U]` | |
| `git-history-analyzer.md` | `[U]` | |
| `learnings-researcher.md` | `[U]` | |
| `repo-research-analyst.md` | `[U]` | |
| `issue-intelligence-analyst.md` | `[新增]` | 上游新增，本地缺失 |
| `slack-researcher.md` | `[新增]` | 上游新增，本地缺失 |

#### agents/review/
| 文件 | 归属 | 备注 |
|------|------|------|
| `agent-native-reviewer.md` | `[U]` | |
| `architecture-strategist.md` | `[U]` | |
| `code-simplicity-reviewer.md` | `[U]` | |
| `data-integrity-guardian.md` | `[U]` | |
| `data-migration-expert.md` | `[U]` | |
| `deployment-verification-agent.md` | `[U]` | |
| `dhh-rails-reviewer.md` | `[U]` | |
| `julik-frontend-races-reviewer.md` | `[U]` | |
| `kieran-python-reviewer.md` | `[U]` | |
| `kieran-rails-reviewer.md` | `[U]` | |
| `kieran-typescript-reviewer.md` | `[U]` | |
| `pattern-recognition-specialist.md` | `[U]` | |
| `performance-oracle.md` | `[U]` | |
| `schema-drift-detector.md` | `[U]` | |
| `security-sentinel.md` | `[U]` | |
| `adversarial-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `api-contract-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `cli-agent-readiness-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `cli-readiness-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `correctness-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `data-migrations-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `maintainability-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `performance-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `previous-comments-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `project-standards-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `reliability-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `security-reviewer.md` | `[新增]` | 上游新增，本地缺失 |
| `testing-reviewer.md` | `[新增]` | 上游新增，本地缺失 |

#### agents/workflow/
| 文件 | 归属 | 备注 |
|------|------|------|
| `bug-reproduction-validator.md` | `[U]` | |
| `lint.md` | `[U]` | |
| `pr-comment-resolver.md` | `[U]` | |
| `spec-flow-analyzer.md` | `[U]` | |
| `every-style-editor.md` | `[L]` | 本地有，上游已迁移为 `skills/every-style-editor/` |

---

### commands/ — `[D]` **上游已整体删除此目录**

> ⚠️ **重大变更**：上游已将 `commands/workflows/` 迁移到 `skills/ce-*/SKILL.md`。
> 本地 `commands/` 目录在 P1 合并后将**完全失效**。

| 子目录/文件 | 状态 | 迁移目标 |
|-----------|------|----------|
| `commands/workflows/brainstorm.md` | `[D→R]` | → `skills/ce-brainstorm/SKILL.md` |
| `commands/workflows/plan.md` | `[D→R]` | → `skills/ce-plan/SKILL.md` |
| `commands/workflows/review.md` | `[D→R]` | → `skills/ce-review/SKILL.md` |
| `commands/workflows/work.md` | `[D→R]` | → `skills/ce-work/SKILL.md` |
| `commands/workflows/compound.md` | `[D→R]` | → `skills/ce-compound/SKILL.md` |
| `commands/workflows/doctor.md` | `[D→R]` | → 待确认 |
| `commands/workflows/pr.md` | `[D→R]` | → 待确认 |
| `commands/workflows/sync-upstream.md` | `[D→R]` | → 待确认 |
| `commands/ce/*` | `[D]` | 已被 `skills/ce-*/` 替代 |
| `commands/*.md`（其他） | `[D]` | 部分已迁移到 skills，部分待确认 |

**关键影响**：`scripts/sync-codex-workflows.ps1` 中的源路径需要从 `commands/workflows/` 更新为 `skills/ce-*/SKILL.md`。

---

### hooks/ — `[L]` 本地私有，上游无此目录

| 文件 | 归属 | 备注 |
|------|------|------|
| `hooks/hooks.json` | `[P-like]` | 本地 PeonPing 集成，不与上游冲突 |
| `hooks/notify-sound.sh` | `[P-like]` | 本地音效通知 |
| `hooks/session-start.sh` | `[P-like]` | 本地会话启动脚本 |
| `hooks/skill-checking-protocol.md` | `[P-like]` | 本地技能检查协议 |

---

### skills/ — 上游拥有的技能

#### 完全同步（`[U]`），上游有我们也有：
- `skills/agent-browser/`
- `skills/agent-native-architecture/`
- `skills/andrew-kane-gem-writer/`
- `skills/dhh-rails-style/`
- `skills/every-style-editor/`
- `skills/frontend-design/`
- `skills/gemini-imagegen/`
- `skills/git-worktree/`
- `skills/orchestrating-swarms/`
- `skills/rclone/`
- `skills/setup/`

#### 上游已重命名（`[R]`），本地用旧名：
| 本地旧名 | 上游新名 | 迁移策略 |
|----------|----------|----------|
| `skills/brainstorming/` | `skills/ce-brainstorm/` | P1 合并时接受新名，保留中文定制 |
| `skills/compound-docs/` | `skills/ce-compound/` + `ce-compound-refresh/` | P1 合并时接受新名 |
| `skills/file-todos/` | `skills/todo-create/` + `todo-resolve/` + `todo-triage/` | P1 合并时接受新拆分结构 |
| `skills/resolve-pr-parallel/` | `skills/resolve-pr-feedback/` | P1 合并时接受新名 |

#### 本地独有（`[L]`），上游无此文件，需明确保留决策：
| 本地文件 | 保留建议 | 理由 |
|----------|----------|------|
| `skills/create-agent-skills/` | ✅ 保留 | 本仓库特有的 skill 创建工具 |
| `skills/finishing-a-feature/` | ✅ 保留 | 工作流增强 |
| `skills/glue-coding/` | ✅ 保留 | 本仓库核心理念 |
| `skills/party-mode/` | ✅ 保留 | 本仓库特有的多角色模式 |
| `skills/receiving-code-review/` | ✅ 保留 | 本仓库工作流 |
| `skills/skill-creator/` | ⚠️ 评估 | 与 `create-agent-skills/` 功能重叠？ |
| `skills/spec-compliance-review/` | ✅ 保留 | 本仓库审查增强 |
| `skills/systematic-debugging/` | ✅ 保留 | 调试工作流 |
| `skills/test-driven-development/` | ✅ 保留 | TDD 工作流 |

#### 上游新增（`[新增]`），本地缺失，P1 合并后自动获得：
- `skills/ce-brainstorm/` — 新架构 brainstorm
- `skills/ce-compound/` + `ce-compound-refresh/` — 新架构 compound
- `skills/ce-ideate/` — 新增 ideate 工作流
- `skills/ce-plan/` — 新架构 plan
- `skills/ce-review/` — 新架构 review（含 findings-schema.json，P0-2 Review Contract 的基础）
- `skills/ce-work/` + `ce-work-beta/` — 新架构 work
- `skills/agent-native-audit/`
- `skills/changelog/`
- `skills/claude-permissions-optimizer/`
- `skills/deploy-docs/`
- `skills/feature-video/`
- `skills/git-clean-gone-branches/`
- `skills/git-commit/`
- `skills/git-commit-push-pr/`
- `skills/lfg/`
- `skills/onboarding/`
- `skills/proof/`
- `skills/report-bug-ce/`
- `skills/reproduce-bug/`
- `skills/resolve-pr-feedback/`
- `skills/slfg/`
- `skills/test-browser/`
- `skills/test-xcode/`
- `skills/todo-create/` + `todo-resolve/` + `todo-triage/`

---

### skills-custom/ — `[P]` 全部私有 Overlay，永不与上游冲突

| 文件 | 说明 |
|------|------|
| `skills-custom/findings-triage/SKILL.md` | 本地 findings 分类工具 |
| `skills-custom/review-prompt/SKILL.md` | Review 提示增强 |
| `skills-custom/root-cause-analysis/SKILL.md` | 根因分析 |
| `skills-custom/sync-targets/SKILL.md` | 同步目标管理 |
| `skills-custom/task-bundle/` | Phase 0 新增 Task Bundle |
| `skills-custom/user-first-design/SKILL.md` | 用户优先设计 |
| `skills-custom/README.zh-CN.md` | 中文说明 |

---

## 汇总统计

| 类别 | 数量 | 合并复杂度 |
|------|------|-----------|
| `[U]` 完全上游，无修改 | ~40 个文件 | 零冲突，直接接受 |
| `[UM]` 上游+本地修改 | ~5 个文件 | 需三方合并 |
| `[L]` 本地新增 | ~12 个技能目录 | 合并后手动确认 |
| `[P]` 私有 Overlay | ~7 个技能 | 永不冲突 |
| `[R]` 上游重命名 | ~4 组 | 接受新名，移植内容 |
| `[D]` 上游删除 | 整个 `commands/` 目录 | ⚠️ 本地中文定制需手动移植到 `skills/ce-*/` |
| `[新增]` 上游新增 | ~30 个技能/代理 | 合并后自动获得 |

---

## P1 合并风险点

### 风险 1：`commands/workflows/` 本地中文定制丢失 🔴 高

**影响文件**：`commands/workflows/brainstorm.md`, `plan.md`, `review.md`, `work.md`, `compound.md`

**缓解方案**：P1-2 阶段，先备份本地中文定制内容，再接受上游新架构，最后手动移植到 `skills/ce-*/SKILL.md`。

### 风险 2：`CLAUDE.md` 三方合并冲突 🟡 中

**影响文件**：`plugins/compound-engineering/CLAUDE.md`

**缓解方案**：以本地版本为基础，cherry-pick 上游改动。

### 风险 3：`skills/ce-review/references/findings-schema.json` 与 Review Contract 设计冲突 🟡 中

**说明**：上游已有 findings schema，P0-2 Review Contract 的设计需要在合并后与此对齐。P1 合并前不要实现 Review Contract 集成层。

### 风险 4：`scripts/sync-codex-workflows.ps1` 源路径失效 🟡 中

**影响**：合并后 `commands/workflows/` 不存在，脚本需更新为读取 `skills/ce-*/SKILL.md`。

---

## 下一步：P1-1 合并准备清单

- [ ] 备份 `commands/workflows/` 中所有本地中文定制内容（提取到临时文件）
- [ ] 确认 `CLAUDE.md` 本地与上游的差异（三方合并策略）
- [ ] 执行 `git merge upstream/main` 并处理冲突
- [ ] 验证 P1-1（bug fix 批次）无破坏性变更
- [ ] 执行 P1-2（commands→skills 架构迁移）
- [ ] 更新 `scripts/sync-codex-workflows.ps1` 源路径
