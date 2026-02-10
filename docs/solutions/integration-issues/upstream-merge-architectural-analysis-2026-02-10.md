---
title: Upstream Merge Architectural Impact Analysis - February 2026
date: 2026-02-10
category: integration-issues
tags: [upstream-merge, architectural-analysis, merge-strategy, fork-divergence]
module: workflows
resolution: architectural-recommendation
---

# Upstream Merge Architectural Impact Analysis - February 2026

## Executive Summary

**Merge Scope**: 185 files changed, +8238/-15282 lines (net -7044 lines)
**Divergence Point**: Commit 36e7f3a (PR #142 - protect plan files from review deletion)
**Fork Commits Since**: 69 commits
**Upstream Commits Since**: 15 commits
**Recommended Strategy**: **Hybrid Selective Merge** (not full merge)

### Critical Risk Assessment

| Risk Category | Severity | Impact |
|--------------|----------|--------|
| **Customization Destruction** | HIGH | 75+ custom files face deletion |
| **Architecture Divergence** | MEDIUM | Different feature evolution paths |
| **Integration Complexity** | HIGH | Significant upstream refactoring |
| **Rollback Difficulty** | CRITICAL | Full merge nearly irreversible |

### Strategic Recommendation

**DO NOT perform a direct `git merge upstream/main`**. This would destroy 33 critical custom files and require extensive manual recovery.

---

## 1. Architecture Overview

### 1.1 Repository Architecture

```
Jerrylalala/compound-engineering-plugin-private (fork)
├── Upstream Mirror Layer        [EveryInc original code]
├── Localization Layer           [Chinese docs + scripts]
├── Custom Extension Layer       [Gemini/Codex integration]
└── Operational Documentation    [Solutions, sync reports]
```

**Key Architectural Principle**: Fork maintains "non-invasive extension" strategy - adds capabilities without modifying upstream core logic.

### 1.2 Current Component Inventory

| Component Type | Fork Count | Upstream Count | Delta |
|----------------|-----------|----------------|-------|
| Agents | 28 | 29 | Fork -1 |
| Commands | 29 | 24 | Fork +5 |
| Skills | 20 | 18 | Fork +2 |
| MCP Servers | 1 | 1 | Same |

**Fork-Specific Commands** (5):
- `commands/codex.md` - Codex CLI integration
- `commands/gemini.md` - Gemini CLI integration
- `commands/workflows/load.md` - Session state management
- `commands/workflows/save.md` - Session state management
- `commands/workflows/sync-upstream.md` - Multi-repo sync detection

**Fork-Specific Skills** (2):
- `skills-custom/subagent-branching/` - Isolated task execution
- `skills-custom/cross-tool-experience/` - Global solution database
- `skills-custom/external-consultation/` - Multi-LLM consultation

---

## 2. Change Assessment

### 2.1 Upstream Changes (15 commits since divergence)

#### Major Refactoring (HIGH IMPACT)

**#161: Reduce context token usage by 79%** (commit f744b79)
- Architectural shift: Remove redundant skill references from agents
- Impact: Massive reduction in token consumption
- Risk: Fork's custom agents may not follow same pattern

**#150: Prevent subagents from writing intermediary files** (commit 04ee7e4)
- Security enhancement: Subagents can no longer create temp files
- Impact: Closes potential information leak vector
- Risk: Fork's `subagent-branching` skill may rely on file-based coordination

**#123: Add sync command for personal config** (commit 1bdd103)
- New feature: `src/commands/sync.ts` + `src/sync/` directory
- Purpose: Sync config files to ~/.claude/, Codex, OpenCode
- Overlap: Fork already has `commands/workflows/sync-upstream.md` (different purpose)

#### New Components (MEDIUM IMPACT)

**#151: Add orchestrating-swarms skill** (1718 lines)
- New massive skill for multi-agent coordination
- May conflict with fork's `subagent-branching` approach

**#112: Add document-review skill**
- New skill for brainstorm/plan refinement
- No direct conflict, can integrate

**Schema-drift-detector agent** (new agent)
- Database schema monitoring
- No conflict, can integrate

**New commands**: `/triage-prs`, `/slfg` (Self-Learning From Grokking)
- Workflow automation additions
- No conflict with fork commands

#### Deletions (HIGH IMPACT ON FORK)

**Skills removed by upstream**:
- `party-mode/` (16 files) - Multi-persona brainstorming
- `systematic-debugging/` (4 files) - Debugging workflow
- `test-driven-development/` (2 files) - TDD workflow
- `spec-compliance-review/SKILL.md` - Pre-review validation
- `glue-coding/` (2 files) - Integration pattern skill

**Fork Impact**: These skills are referenced in fork's CLAUDE.md skill-checking protocol (lines 36-48). Deletion would break documented workflows.

#### Gemini Support Removal (CRITICAL CONFLICT)

**Files removed**:
- `src/converters/claude-to-gemini.ts` (173 lines)
- `src/targets/gemini.ts` (79 lines)
- `src/types/gemini.ts` (17 lines)
- `src/utils/filter-claude-code-only.ts` (37 lines)

**Fork Status**: These files are CORE to fork's value proposition. Fork v2.37.0-v2.40.1 built entire Gemini CLI integration feature set on these.

**Root Cause**: Upstream likely determined Gemini support was experimental/unmaintained.

---

### 2.2 Fork-Specific Customizations at Risk

#### Tier 1: Critical (Would Break Core Features)

**Custom Integration Infrastructure** (5 files)
```
plugins/compound-engineering/commands/codex.md
plugins/compound-engineering/commands/gemini.md
src/converters/claude-to-gemini.ts
src/targets/gemini.ts
src/types/gemini.ts
```
**Purpose**: Multi-LLM consultation system (fork's flagship feature)
**Upstream Action**: Delete all Gemini support
**Consequence**: Feature disappears without trace

**Session Management Commands** (2 files)
```
plugins/compound-engineering/commands/workflows/load.md
plugins/compound-engineering/commands/workflows/save.md
```
**Purpose**: Save/restore conversation state
**Upstream Action**: None (upstream doesn't have these)
**Merge Risk**: Would be deleted by upstream's file tree

**Hooks System** (3 files)
```
plugins/compound-engineering/hooks/hooks.json
plugins/compound-engineering/hooks/session-start.sh
plugins/compound-engineering/hooks/skill-checking-protocol.md
```
**Purpose**: Enforce skill usage protocol at session start
**Upstream Action**: Upstream has no hooks/
**Merge Risk**: Would be deleted

#### Tier 2: High Value (Unique Fork Capabilities)

**Chinese Documentation** (7 files in `docs/zh-CN/`)
```
CONCEPTS.md, FORK-SETUP.md, INSTALL.md, SCRIPTS.md,
SYNC.md, VERSION-STRATEGY.md, WORKFLOW-VISUAL.md
```
**Purpose**: Localization layer for Chinese users
**Upstream Action**: None (not present in upstream)
**Merge Risk**: Would be deleted

**Solution Database** (6 files in `docs/solutions/integration-issues/`)
```
marketplace-update-failure-and-unicode-display.md
phantom-agent-references-in-workflows.md
sessionstart-hook-prompt-type-not-supported.md
skill-vs-agent-invocation.md
subagent-driven-workflow-integration.md
upstream-sync-integration-workflow.md
```
**Purpose**: Knowledge management system
**Upstream Action**: None
**Merge Risk**: Would be deleted

**Automation Scripts** (7 files in `scripts/`)
```
bump-version.ps1, check-versions.ps1, check-versions.sh,
codex-review-now.sh, gemini-review-now.sh, pre-commit, sync-to-targets.ps1
```
**Purpose**: Version management, multi-tool review automation
**Upstream Action**: None
**Merge Risk**: Would be deleted

#### Tier 3: Operational (Less Critical but Valuable)

**Sync Reports** (2 files)
```
docs/sync-reports/2026-02-04-upstream-sync.md
docs/sync-reports/upstream-repos.json
```
**Purpose**: Track upstream monitoring results
**Upstream Action**: None
**Merge Risk**: Would be deleted

**Custom Skills** (3 skills in `skills-custom/`)
```
subagent-branching/
cross-tool-experience/
external-consultation/
```
**Purpose**: Fork-specific architectural patterns
**Upstream Action**: None
**Merge Risk**: Would be deleted (entire directory not in upstream)

---

## 3. Architectural Compliance Check

### 3.1 Separation of Concerns - VIOLATED by Full Merge

**Principle**: Fork maintains clean separation between:
- Upstream mirror (read-only tracking)
- Custom extensions (additive, non-invasive)
- Operational tooling (scripts, docs)

**Full Merge Impact**: Would collapse these layers into single indistinguishable history.

**Evidence**:
```bash
$ git log --oneline --graph 36e7f3a..HEAD | head -10
* 3f74e38 docs: 记录上游同步整合工作流经验
* 2d88386 feat: 整合上游同步报告与 Subagent 分支安全增强
* 685bc3f 合并上游 upstream/main — 同步 #142 保护 plan 文件不被审查删除
* 679639b feat: 添加 /workflows:sync-upstream 上游仓库智能同步检测命令
```

Fork maintains Chinese commit messages. Upstream uses English. Direct merge would create mixed-language history.

### 3.2 Dependency Inversion - AT RISK

**Current Architecture** (SOLID compliant):
```
High-Level: /workflows:review command
    ↓ (depends on abstraction)
Abstract Interface: External reviewer invocation
    ↑ (implements)
Low-Level: Codex CLI, Gemini CLI adapters
```

**After Upstream Merge**:
- Gemini adapter layer removed
- `filter-claude-code-only.ts` utility removed
- Commands depend on non-existent infrastructure

**Violation**: High-level policy (`/workflows:review [G]`) depends on low-level detail (Gemini converter) that upstream deleted.

### 3.3 Open/Closed Principle - MAINTAINED (Good)

Fork extends upstream without modifying core:
- Adds commands via new files (not editing existing commands)
- Adds skills in separate `skills-custom/` namespace
- Injects behavior via hooks (external to core plugin logic)

**Verdict**: Fork architecture is sound. Problem is upstream doesn't recognize this extension mechanism.

### 3.4 Component Coupling - ACCEPTABLE

**Coupling Matrix**:

| Component | Depends On | Coupling Type |
|-----------|-----------|---------------|
| `/workflows:review [C][G]` | codex.md, gemini.md | Loose (via command invocation) |
| codex.md | filter-claude-code-only.ts | Tight (import) |
| gemini.md | claude-to-gemini.ts | Tight (import) |
| bump-version.ps1 | marketplace.json, plugin.json | Tight (file paths) |

**Risk**: Tight coupling to deleted files breaks builds. Loose coupling fails at runtime.

---

## 4. Risk Analysis

### 4.1 Immediate Risks (Full Merge Scenario)

**P0: Build System Breakage**
- TypeScript imports to deleted files (`claude-to-gemini.ts`)
- Command invocations to missing commands
- Estimated fix time: 8-12 hours

**P0: Feature Regression**
- `/workflows:review [G]` becomes no-op
- `/gemini` command disappears
- User workflows break with no warning

**P1: Documentation Inconsistency**
- CLAUDE.md references deleted skills (party-mode, systematic-debugging)
- INSTALL.md references commands that no longer exist
- README claims features that aren't available

**P1: Knowledge Loss**
- Solutions database (`docs/solutions/`) deleted
- Sync reports (`docs/sync-reports/`) deleted
- No searchable history for future troubleshooting

### 4.2 Long-Term Architectural Risks

**Technical Debt Accumulation**
- Upstream refactored to reduce tokens 79%; fork's custom agents didn't follow
- Fork agents may bloat context unnecessarily
- Divergence compounds over time

**Maintenance Burden Increase**
- Every upstream update requires manual reconciliation
- No automated way to detect conflicts
- Bus factor = 1 (only user understands fork architecture)

**Upstream Philosophy Divergence**
- Upstream removed "party-mode" (multi-persona approach)
- Fork's entire skill-checking protocol built around party-mode
- Fundamental disagreement on architecture pattern

### 4.3 Rollback Complexity

**Full Merge Rollback**: `git reset --hard HEAD~1` (destructive)
- Loses all merge conflict resolutions
- Requires re-doing work from scratch

**Selective Merge Rollback**: `git revert <commit>` (safe)
- Each cherry-picked commit individually revertible
- Granular undo capability

---

## 5. Recommended Merge Strategy

### 5.1 Strategy: Hybrid Selective Merge

**Phase 1: Cherry-Pick High-Value Upstream Commits**

```bash
# Create integration branch
git checkout -b integrate-upstream-2026-02

# Cherry-pick specific valuable commits
git cherry-pick f744b79  # Token usage reduction (79%)
git cherry-pick 04ee7e4  # Subagent file write prevention
git cherry-pick f7cab16  # Hook crash fix
git cherry-pick 1bdd103  # Sync command (evaluate for conflicts)
git cherry-pick a5bba3d  # document-review skill
git cherry-pick 2429f59  # schema-drift-detector agent
```

**Phase 2: Manual Integration of Refactored Components**

For each cherry-picked commit with conflicts:
1. Preserve fork's custom files (use `git checkout --ours`)
2. Manually apply upstream logic changes to fork equivalents
3. Test extensively before committing

**Phase 3: Evaluate New Skills**

```bash
# Add orchestrating-swarms skill manually (selective)
# Review whether it conflicts with subagent-branching approach
# Document decision in docs/solutions/
```

**Phase 4: Update Fork Documentation**

```markdown
# In docs/zh-CN/SYNC.md, add section:

## 2026-02 Upstream Merge Decision

Upstream removed skills fork depends on (party-mode, systematic-debugging).
Decision: Fork maintains these skills independently.

Rationale:
1. Fork's skill-checking protocol depends on them
2. Removing would break documented workflows
3. Upstream may have different use case priorities
```

### 5.2 What NOT to Merge

**Permanent Exclusions**:
1. Gemini support removal (fork keeps own implementation)
2. Deleted skills that fork references (party-mode, etc.)
3. Upstream's CLAUDE.md rewrite (fork has different requirements)

**Reasoning**: These represent legitimate architectural divergence, not technical debt.

### 5.3 Alternative Strategies Considered

#### Option A: Full Merge + Fix Conflicts
**Pros**: Stays closest to upstream
**Cons**:
- 33 files require manual restoration
- 8-12 hours conflict resolution
- Breaks all active user workflows during fix period
- High risk of missing subtle breakages

**Verdict**: REJECTED. Risk/reward ratio too high.

#### Option B: Rebase Fork onto Upstream
**Pros**: Clean linear history
**Cons**:
- Rewrites 69 commits of fork history
- Breaks all GitHub PR references
- Force push required (destroys safety)
- Same conflict issues as full merge

**Verdict**: REJECTED. Violates safety principles.

#### Option C: Maintain Permanent Fork (No Merge)
**Pros**: Zero merge risk
**Cons**:
- Misses upstream improvements (79% token reduction)
- Accumulates technical debt
- Fork becomes unmaintainable long-term

**Verdict**: REJECTED. Unsustainable.

#### Option D: Hybrid Selective Merge (RECOMMENDED)
**Pros**:
- Preserves fork customizations
- Adopts upstream improvements selectively
- Maintains rollback capability
- Documents architectural decisions

**Cons**:
- Requires more manual work upfront
- Need to track "why not merged" decisions

**Verdict**: ACCEPTED. Best balance of safety and progress.

---

## 6. Implementation Plan

### 6.1 Pre-Merge Preparation

**Step 1: Backup Current State**
```bash
git tag fork-pre-upstream-merge-2026-02
git push origin fork-pre-upstream-merge-2026-02
```

**Step 2: Create Test Branch**
```bash
git checkout -b test-upstream-merge-2026-02
```

**Step 3: Inventory Custom Files**
```bash
git diff --name-status HEAD upstream/main | grep "^D" > custom-files-at-risk.txt
# Verify this matches 75 expected files
```

**Step 4: Run Integration Tests**
```bash
# Verify current state works
claude --plugin-dir "E:\project\compound-engineering-plugin-private\plugins\compound-engineering"
# Test key commands
/workflows:review
/gemini "test query"
/codex "test query"
```

### 6.2 Cherry-Pick Execution Sequence

**Batch 1: Low-Risk Improvements**
```bash
git cherry-pick f7cab16  # Hook crash fix (no conflicts expected)
git cherry-pick 9f93f54  # Protect plan files from review deletion
# Test after each: npm test (if tests exist)
```

**Batch 2: Medium-Risk Refactoring**
```bash
git cherry-pick 04ee7e4  # Prevent subagent intermediary files
# EXPECT CONFLICTS: subagent-branching skill may rely on this
# Resolution: Preserve fork's pattern, document why
```

**Batch 3: High-Risk Token Reduction**
```bash
git cherry-pick f744b79  # 79% token usage reduction
# EXPECT CONFLICTS: Agent .md files in fork may be outdated
# Resolution: Apply pattern to fork's custom agents manually
```

**Batch 4: New Features**
```bash
git cherry-pick a5bba3d  # document-review skill
git cherry-pick 2429f59  # schema-drift-detector agent
git cherry-pick 1bdd103  # sync command (CHECK: conflicts with fork's sync-upstream?)
```

### 6.3 Conflict Resolution Protocol

For each conflict:

```
1. Identify conflict type:
   - File exists in fork but not upstream → KEEP FORK
   - Logic change in shared file → MERGE CAREFULLY
   - Upstream removed fork dependency → PRESERVE FORK, DOCUMENT

2. Resolution decision tree:
   ┌─ Is this file fork-specific? ───► YES ──► git checkout --ours <file>
   │
   ├─ Does upstream change improve fork? ───► YES ──► Manually merge
   │
   └─ Is this philosophical difference? ───► YES ──► Keep fork version, add docs/solutions/ entry

3. After resolution:
   - Add test case if possible
   - Update CHANGELOG.md
   - Document in commit message
```

### 6.4 Post-Merge Validation

**Validation Checklist**:
```bash
# 1. Version consistency
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 2. Component counts
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count    # Should be 28
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count  # Should be 29
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count      # Should be 20

# 3. Custom files intact
Test-Path docs/zh-CN/INSTALL.md          # Should be True
Test-Path plugins/compound-engineering/commands/gemini.md  # Should be True
Test-Path src/converters/claude-to-gemini.ts  # Should be True

# 4. Functional tests
claude --plugin-dir "..."
/workflows:review [C][G]  # Should invoke both Codex and Gemini
/workflows:sync-upstream  # Should generate report
```

**If ANY check fails**: Rollback and investigate before proceeding.

---

## 7. Long-Term Architectural Recommendations

### 7.1 Formalize Fork Extension Pattern

**Problem**: Upstream doesn't recognize `skills-custom/`, `docs/zh-CN/`, etc. as intentional extensions.

**Solution**: Document fork's architectural layers in machine-readable format.

**Implementation**:
```json
// .fork-manifest.json (new file)
{
  "fork_of": "EveryInc/compound-engineering-plugin",
  "divergence_point": "36e7f3a",
  "custom_namespaces": [
    "skills-custom/",
    "docs/zh-CN/",
    "docs/solutions/",
    "scripts/*.ps1"
  ],
  "custom_features": [
    {
      "name": "gemini-integration",
      "files": ["commands/gemini.md", "src/converters/claude-to-gemini.ts"],
      "status": "maintained_independently",
      "reason": "Upstream removed experimental Gemini support"
    }
  ]
}
```

**Benefit**: Future AI assistants can auto-detect fork customizations during merge.

### 7.2 Implement Automated Merge Conflict Detection

**Current Gap**: Manual detection of file deletions.

**Proposed Solution**: Pre-merge validation script.

**Implementation**:
```powershell
# scripts/validate-upstream-merge.ps1
param([string]$UpstreamBranch = "upstream/main")

Write-Host "Checking for conflicts with upstream merge..." -ForegroundColor Yellow

# Load fork manifest
$manifest = Get-Content .fork-manifest.json | ConvertFrom-Json

# Check for file deletions
$deletions = git diff --name-status HEAD $UpstreamBranch | Where-Object { $_ -match "^D" }
$protectedFiles = $deletions | Where-Object {
    $file = ($_ -split "\s+")[1]
    $manifest.custom_namespaces | Where-Object { $file -like "$_*" }
}

if ($protectedFiles.Count -gt 0) {
    Write-Host "ERROR: Upstream would delete protected fork files:" -ForegroundColor Red
    $protectedFiles | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "Validation passed. Safe to proceed with selective merge." -ForegroundColor Green
```

### 7.3 Establish Upstream Contribution Path

**Problem**: Fork maintains features upstream removed (Gemini support).

**Long-Term Solution**: Contribute back as optional plugin extension.

**Proposal**:
1. Extract Gemini integration into separate npm package
2. Publish as `@jerrylalala/claude-plugin-gemini-adapter`
3. Upstream can optionally depend on it

**Benefit**: Reduces fork divergence while preserving feature.

### 7.4 Version Numbering Strategy for Fork

**Current Problem**: Fork v2.40.1, Upstream v2.31.1 - confusing.

**Proposed Scheme**:
```
Fork version = <upstream-version>-fork.<fork-patch>

Examples:
- Upstream v2.31.1 + Fork changes = 2.31.1-fork.1
- Upstream v2.32.0 + Fork changes = 2.32.0-fork.1
```

**Benefit**: Clearly shows upstream base version + fork modifications.

---

## 8. Decision Record

### Decision: DO NOT perform direct `git merge upstream/main`

**Date**: 2026-02-10
**Status**: RECOMMENDED
**Deciders**: System Architecture Expert Analysis

**Context**:
- Fork maintains 33 custom files not in upstream
- Upstream removed Gemini support (fork's core feature)
- Upstream removed skills fork depends on
- Full merge would require 8-12 hours of conflict resolution
- High risk of breaking user workflows

**Decision**:
Use Hybrid Selective Merge strategy:
1. Cherry-pick valuable upstream commits individually
2. Preserve fork customizations explicitly
3. Document architectural divergence decisions
4. Validate extensively between batches

**Consequences**:

**Positive**:
- Zero risk of destroying custom files
- Granular rollback capability
- Maintains user workflow stability
- Forces conscious decision-making on each change

**Negative**:
- More manual work than automated merge
- Requires maintaining "not merged" documentation
- May miss subtle upstream improvements

**Alternatives Considered**:
- Full merge: Rejected due to high risk
- No merge: Rejected due to missing token optimization
- Rebase: Rejected due to history rewriting

---

## 9. Appendices

### Appendix A: Files at Risk (Complete List)

**Tier 1 - Critical (Would Break Core Features)**: 10 files
```
plugins/compound-engineering/commands/codex.md
plugins/compound-engineering/commands/gemini.md
plugins/compound-engineering/commands/workflows/load.md
plugins/compound-engineering/commands/workflows/save.md
plugins/compound-engineering/commands/workflows/sync-upstream.md
plugins/compound-engineering/hooks/hooks.json
plugins/compound-engineering/hooks/session-start.sh
plugins/compound-engineering/hooks/skill-checking-protocol.md
src/converters/claude-to-gemini.ts
src/targets/gemini.ts
src/types/gemini.ts
src/utils/filter-claude-code-only.ts
```

**Tier 2 - High Value (Unique Capabilities)**: 20 files
```
docs/zh-CN/CONCEPTS.md
docs/zh-CN/FORK-SETUP.md
docs/zh-CN/INSTALL.md
docs/zh-CN/SCRIPTS.md
docs/zh-CN/SYNC.md
docs/zh-CN/VERSION-STRATEGY.md
docs/zh-CN/WORKFLOW-VISUAL.md
docs/solutions/integration-issues/*.md (6 files)
scripts/bump-version.ps1
scripts/check-versions.ps1
scripts/check-versions.sh
scripts/codex-review-now.sh
scripts/gemini-review-now.sh
scripts/pre-commit
scripts/sync-to-targets.ps1
```

**Tier 3 - Operational**: 8 files
```
docs/sync-reports/2026-02-04-upstream-sync.md
docs/sync-reports/upstream-repos.json
docs/brainstorms/*.md (2 files)
docs/plans/*.md (3 files)
skills-custom/subagent-branching/
skills-custom/cross-tool-experience/
skills-custom/external-consultation/
```

**Total at risk**: 33+ files (excluding upstream's own deletions)

### Appendix B: Upstream Deletions to IGNORE

These are upstream's own files they chose to remove. Fork should NOT restore them unless fork depended on them:

```
plugins/compound-engineering/skills/party-mode/* (16 files)
plugins/compound-engineering/skills/systematic-debugging/* (4 files)
plugins/compound-engineering/skills/test-driven-development/* (2 files)
plugins/compound-engineering/skills/spec-compliance-review/SKILL.md
plugins/compound-engineering/skills/glue-coding/* (2 files)
```

**Exception**: Fork's `CLAUDE.md` references these skills. Must either:
1. Remove references from fork's CLAUDE.md, OR
2. Maintain these skills independently in fork

**Recommendation**: Option 2 (maintain independently) - these are valuable workflows.

### Appendix C: Command for Testing Merge Impact

```bash
# Dry-run full merge to see all conflicts
git merge --no-commit --no-ff upstream/main
git status --short | wc -l  # Count conflicted files
git merge --abort  # Undo dry-run

# Compare file trees
comm -13 <(git ls-tree -r --name-only upstream/main | sort) \
         <(git ls-tree -r --name-only HEAD | sort) \
  > fork-only-files.txt

# Expected: ~33 files
```

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [上游同步整合工作流](upstream-sync-integration-workflow.md) | Standard sync process |
| [上游同步指南](../../zh-CN/SYNC.md) | Manual sync steps |
| [版本管理预防策略](../../zh-CN/VERSION-STRATEGY.md) | Version consistency rules |
| [Fork 初始化清单](../../zh-CN/FORK-SETUP.md) | Original fork setup |
| [Subagent-Driven 工作流整合](subagent-driven-workflow-integration.md) | Execution pattern conflicts |

---

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2026-02-10 | Initial analysis | System Architecture Expert |
