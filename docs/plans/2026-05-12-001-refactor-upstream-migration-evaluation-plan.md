---
title: refactor: Upstream-first Compound Engineering migration
type: refactor
status: active
date: 2026-05-12
origin: docs/sync-reports/2026-05-12-upstream-sync.md
---

# refactor: Upstream-first Compound Engineering migration

## Overview

把本 fork 从“本地扩展为主、偶尔同步上游”改造成“直接上游结构优先 + 本地增强 overlay”。直接上游 `EveryInc/compound-engineering-plugin` 的结构和功能尽可能整合；本地中文化、Harness Fusion、Codex/Gemini、`skills-custom/**`、`/sil`、多上游检测必须保留。完成后 Claude Code 和 Codex 都要有可验证的可用链路。

## Problem Frame

当前仓库落后直接上游约两个月。本地已出现 `/ce:*` 补全重复，根因是安装态旧 command 壳层与新 skill 同名并存。与此同时，上游已经更彻底地 skill 化、agent 扁平化、引入 Codex manifest / converter 方向，并修复了多个 core workflow 可靠性问题。

本次不是小 cherry-pick，而是一次 upstream-first 迁移：优先复用直接上游的新结构、新命名、新 workflow 修正和 Codex 兼容设计；本地私有能力以 overlay 形式重新套回去。

## Requirements Trace

- R1. 主入口全部 skill 化，消除 `/ce:*` 重复补全，并保留中文 description / argument hint。
- R2. 尽可能整合直接上游 EveryInc 的结构：commands 清空、skills 主入口、agents 扁平化、`ce-` 前缀、上游新增 docs/skills。
- R3. 尽可能整合直接上游核心功能修正：ce-plan、ce-brainstorm、ce-work、ce-review、ce-compound、doc-review、Codex 相关修正。
- R4. 保留本地能力：中文化、Codex/Gemini external review、Harness Fusion、Agent Teams `[T]`、验证 `[V]`、`skills-custom/**`、多上游检测、`/sil` 最小同步安全策略。
- R5. Codex 可用：短期保留三 workflow sync，整合上游 Codex manifest / agents-only converter / hooks 经验，逐步扩大 Codex 可用 surface。
- R6. 其他上游和流行插件只吸收功能和模式，不直接 vendoring。
- R7. 每阶段必须有 source → package/release → installed cache → runtime/Codex 的完整验证链路。

## Scope Boundaries

- 允许大规模改造本 fork 的结构，但不允许无验证地破坏本地关键能力。
- 不直接无脑 `git merge upstream/main`；采用 upstream-first reconstruction：以直接上游为结构基准，逐层套回本地 overlay。
- 不把 `/sil` 改成多上游扫描器；多上游扫描属于 `/ce:sync-upstream`。
- 不用全插件 `install --to codex` 污染用户 Codex；若引入上游 Codex manifest，也必须保持 managed/isolated/可审计。
- 其他流行插件只做模式吸收：Use externally / Adapt pattern / Integrate / Reject / Defer。

## Key Technical Decisions

- **直接上游优先**：EveryInc 是结构基准，其他仓库只提供功能/模式参考。
- **本地能力 overlay 化**：`skills-custom/**`、中文 docs、Codex/Gemini、Harness Fusion 不和上游主结构纠缠，作为覆盖层重新接入。
- **先 inventory 再移动**：agents 扁平化涉及 path/name/invocation/persona catalog/installed registry，不做盲迁移。
- **Codex 双轨**：短期 `/sil` 继续只同步 brainstorm/plan/review；中期引入上游 Codex manifest 思想；长期评估更多 skills/agents 给 Codex 使用。
- **中文补全来自 skill frontmatter**：迁移后所有用户入口的中文显示写在 `SKILL.md` frontmatter，并通过安装态验证。
- **runtime parity 是完成条件**：源码测试通过不等于完成，必须验证实际 Claude Code 插件缓存和 Codex 用户目录。

## Phased Delivery

### P0 — Baseline and Safety Net

建立迁移前基线，避免改完后无法判断哪一层坏了。

**Deliverables**
- `docs/sync-reports/2026-05-12-runtime-surface-baseline.md`
- `docs/sync-reports/2026-05-12-upstream-local-mapping.md`
- source/package/installed/Codex inventories

**Verification**
- 本地 source surface、上游 surface、installed plugin cache、`~/.claude/commands`、`~/.codex/skills` 均有记录。
- 当前重复 `/ce:*` 来源明确。

### P1 — Upstream Skill Surface and Command Removal

整合上游 commands 清空、主入口 skill 化方向。

**Deliverables**
- 所有 `/ce:*` 入口由 `skills/ce-*/SKILL.md` 提供。
- 剩余 `commands/ce/{pr,doctor,sync-upstream}.md` 迁移或明确保留理由；最终目标是和上游一致清空 commands 用户入口。
- 中文 frontmatter 保留。

**Verification**
- source 和 release preview 没有主 workflow command+skill 同名重复。
- 安装态 Claude Code `/ce` 补全无重复，中文说明可见。

### P2 — Agent Flattening and `ce-` Prefix Migration

复用上游 agents 扁平化结构，但先解决身份模型。

**Deliverables**
- `docs/sync-reports/2026-05-12-agent-identity-matrix.md`
- old path/name/invocation → upstream flat path/name/invocation 映射
- alias/rewrite/breaking decision
- 分批迁移 agents 到上游扁平结构

**Verification**
- `ce-review`、`document-review`、research/workflow agents dispatch 均可解析。
- plugin component counts 与 metadata 正确。
- installed runtime agent names 与文档一致。

### P3 — Core Workflow Upstream Feature Merge

整合上游核心流程修正，同时保留本地参数协议。

**Adopt/adapt targets**
- `ce-plan`: synthesis compression、Implementation Units heading、handoff 修复、origin trace / U-ID 相关改进。
- `ce-brainstorm`: scope synthesis、rigor probe、interaction rules 修复。
- `ce-work`: parallel subagent safety、worktree isolation、Codex delegation 可复用部分。
- `ce-review`: finding number stability、pipe escaping、reviewer queue、autofix rubric、external review adjudication 兼容。
- `ce-compound`: `mode:headless`、YAML/frontmatter safety。
- `ce-doc-review`: 降噪、persona scope、autofix/interaction 改进。

**Preserve invariants**
- `ce:brainstorm [P][P+][C][G][R]`
- `ce:plan [T]`
- `ce:work [T][T+][V][V+][R]`
- `ce:review mode:autofix [C][G][T]`
- Codex/Gemini 裁决协议
- `skills-custom/team-mode`、`review-contract`、`ui-review-contract`、`executor-capability-gate`、`codex-first-executor`

**Verification**
- workflow contract tests pass。
- `/sil` 后 Codex brainstorm/plan/review 与 Claude 侧共享协议一致。

### P4 — Codex Compatibility Upgrade

让 Codex 不只依赖旧三 skill 文件，同时不破坏当前安全策略。

**Deliverables**
- `/sil` strengthened: managed marker、dry-run、exact allowlist、path containment、user edit detection。
- 对照上游 Codex native plugin manifests / agents-only converter，设计本 fork 的 Codex manifest 输出。
- `.codex/hooks.json` 兼容性评估。
- Codex 可用 surface 分层：must-have brainstorm/plan/review，optional compound/doc-review/simplify/strategy。

**Verification**
- `scripts/sync-codex-workflows.ps1` 在 temp CodexHome 和真实 CodexHome 下均可审计。
- 不删除用户 unrelated Codex skills。
- Codex 能调用更新后的 `$workflows-brainstorm`、`$workflows-plan`、`$workflows-review`。

### P5 — Upstream New Skills Integration

尽可能整合直接上游新增 skills，但避免重复入口。

**Strong candidates**
- `ce-simplify-code`：和本地 `simplify` 对比后融合。
- `ce-strategy` / `ce-product-pulse`：补强 ideate/brainstorm 上层判断。
- `ce-release-notes`：帮助插件同步和版本理解。
- `ce-polish-beta`：review 后 merge 前 polish。
- `ce-sessions`：评估与 memory/solutions 重叠。
- `ce-riffrec-feedback-analysis`：暂缓，除非本地需要反馈分析。

**Verification**
- 每个 skill 都有 adopt/adapt/reject 结论。
- 新增 skill 更新 README、CHANGELOG、plugin metadata、组件计数和测试。

### P6 — Other Upstream / Popular Plugin Pattern Integration

其他上游只吸收功能和模式。

**Sources**
- BMAD: TOML customization、多平台 installer、investigate skill。
- superpowers: committed Codex files、sync 安全。
- claude-hud: observability/statusline 模式。
- cavekit: blueprint → parallel build → validation。
- claude-review-loop: Codex review loop。
- claude-forge: hooks/security layer。
- oh-my-claudecode / oh-my-openagent / ccg-workflow: 多模型路由、OpenCode/OpenAgent、patch approval。

**Verification**
- 输出 `docs/sync-reports/2026-05-12-plugin-discovery-triage.md`。
- 每个模式明确 Use externally / Adapt pattern / Integrate / Reject / Defer。

## Implementation Units

- [x] **Unit 0: Capture baseline inventories**

**Goal:** 建立 source/package/installed/Codex 基线。

**Requirements:** R1, R2, R5, R7

**Files:**
- Create: `docs/sync-reports/2026-05-12-runtime-surface-baseline.md`
- Create: `docs/sync-reports/2026-05-12-upstream-local-mapping.md`

**Verification:**
- Inventories cover local source, upstream main, release preview, installed Claude cache, `.claude/commands`, `.codex/skills`.

- [x] **Unit 1: Rebuild command/skill surface from upstream structure**

**Goal:** commands 清空方向、主入口 skill 化、中文补全保留。

**Requirements:** R1, R2

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-*/SKILL.md`
- Modify: `plugins/compound-engineering/commands/**`
- Modify: `plugins/compound-engineering/CLAUDE.md`
- Modify: `README.md`
- Test: `tests/release-components.test.ts`
- Test: `tests/release-preview.test.ts`

**Verification:**
- No duplicate user-facing `/ce:*` registrations in source/release/installed cache.

- [ ] **Unit 2: Flatten agents with identity preservation**

**Goal:** 复用上游 flat agents，同时保证 runtime dispatch 不断。

**Requirements:** R2, R4

**Files:**
- Create: `docs/sync-reports/2026-05-12-agent-identity-matrix.md`
- Modify: `plugins/compound-engineering/agents/**`
- Modify: `src/**`
- Modify: `AGENTS.md`
- Test: `tests/release-components.test.ts`
- Test: `tests/review-skill-contract.test.ts`

**Verification:**
- Every referenced agent resolves under new structure.

- [ ] **Unit 3: Merge upstream core workflow fixes**

**Goal:** 合并直接上游核心流程改进。

**Requirements:** R3, R4

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-brainstorm/SKILL.md`
- Modify: `plugins/compound-engineering/skills/ce-plan/SKILL.md`
- Modify: `plugins/compound-engineering/skills/ce-work/SKILL.md`
- Modify: `plugins/compound-engineering/skills/ce-review/SKILL.md`
- Modify: `plugins/compound-engineering/skills/ce-compound/SKILL.md`
- Modify: `plugins/compound-engineering/skills-custom/**`
- Test: `tests/review-skill-contract.test.ts`
- Test: `tests/pipeline-review-contract.test.ts`

**Verification:**
- Local `[P][C][G][T][V][R]` invariants remain intact.

- [x] **Unit 4: Upgrade Codex compatibility and `/sil`**

**Goal:** 复用上游 Codex 兼容设计，同时保留本地 `/sil` 安全策略。

**Requirements:** R5, R7

**Files:**
- Modify: `scripts/sync-codex-workflows.ps1`
- Modify: `.codex/skills/**`
- Create/Modify: `.codex/hooks.json`
- Modify: `docs/specs/codex-workflow-compatibility.md`
- Modify: `docs/zh-CN/CODEX-WORKFLOWS.md`
- Test: `tests/sync-codex.test.ts`
- Test: `tests/pipeline-review-contract.test.ts`

**Verification:**
- Codex can use synced workflows; unrelated user skills are preserved.

- [x] **Unit 5: Integrate upstream new skills**

**Goal:** 将直接上游新增 skills 按 adopt/adapt/reject 整合。

**Requirements:** R3, R6

**Files:**
- Modify/Create: `plugins/compound-engineering/skills/**`
- Modify: `README.md`
- Modify: `plugins/compound-engineering/.claude-plugin/plugin.json`
- Modify: `plugins/compound-engineering/CHANGELOG.md`
- Test: `tests/release-components.test.ts`

**Verification:**
- 新增能力可调用、计数正确、无重复入口。

- [ ] **Unit 6: Triage non-parent upstream patterns**

**Goal:** 其他上游只做功能/模式整合决策。

**Requirements:** R6

**Files:**
- Create: `docs/sync-reports/2026-05-12-plugin-discovery-triage.md`
- Modify: `IDEAS.md`

**Verification:**
- 每个候选有 Use externally / Adapt pattern / Integrate / Reject / Defer 结论。

## System-Wide Impact

- **Claude Code:** `/ce:*` 补全、skill invocation、agent dispatch、plugin install cache。
- **Codex:** `.codex/skills/**`、`~/.codex/skills`、future manifest/hooks。
- **Docs:** README、中文文档、sync reports、plans。
- **Tests:** release metadata、converter、workflow contract、Codex sync、agent resolution。
- **Runtime:** source 正确不等于 installed 正确，必须验证缓存和实际补全。

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| 上游结构覆盖本地增强 | overlay inventory + invariant tests |
| agents 扁平化破坏 dispatch | identity matrix + staged migration |
| Codex sync 误删用户技能 | exact allowlist + managed marker + dry-run |
| 中文补全丢失 | skill frontmatter + installed runtime verification |
| 新 skill 功能膨胀 | adopt/adapt/reject gate |
| 直接 merge 冲突过大 | upstream-first reconstruction, not blind merge |

## Sources & References

- Origin: `docs/sync-reports/2026-05-12-upstream-sync.md`
- Upstream config: `docs/sync-reports/upstream-repos.json`
- Codex docs: `docs/specs/codex-workflow-compatibility.md`
- Codex user docs: `docs/zh-CN/CODEX-WORKFLOWS.md`
- Sync command: `.claude/commands/sil.md`
- Sync script: `scripts/sync-codex-workflows.ps1`
