# Upstream Merge Visual Summary - February 2026

**Quick Reference**: This document provides visual diagrams for understanding the upstream merge situation.

---

## Current Fork Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Fork Architecture Layers                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Layer 4: Custom Extensions (Fork-Specific Features)                 │
│  ┌───────────────────────────────────────────────────────────┐      │
│  │ /gemini, /codex commands                                   │      │
│  │ /workflows:load, /workflows:save                           │      │
│  │ /workflows:sync-upstream                                   │      │
│  │ skills-custom/ directory                                   │      │
│  │ hooks/ system                                              │      │
│  └───────────────────────────────────────────────────────────┘      │
│          ↑ Depends on (can access)                                   │
│                                                                       │
│  Layer 3: Localization (Chinese Users)                               │
│  ┌───────────────────────────────────────────────────────────┐      │
│  │ docs/zh-CN/ (7 files)                                      │      │
│  │ README.zh-CN.md                                            │      │
│  │ CLAUDE.md (fork-specific instructions)                     │      │
│  └───────────────────────────────────────────────────────────┘      │
│          ↑ Depends on (documents)                                    │
│                                                                       │
│  Layer 2: Operational Tools (Development)                            │
│  ┌───────────────────────────────────────────────────────────┐      │
│  │ scripts/*.ps1 (version management)                         │      │
│  │ docs/solutions/ (knowledge base)                           │      │
│  │ docs/sync-reports/ (upstream tracking)                     │      │
│  └───────────────────────────────────────────────────────────┘      │
│          ↑ Depends on (operates on)                                  │
│                                                                       │
│  Layer 1: Upstream Mirror (EveryInc Code)                            │
│  ┌───────────────────────────────────────────────────────────┐      │
│  │ plugins/compound-engineering/agents/ (28 agents)           │      │
│  │ plugins/compound-engineering/commands/ (24 base commands)  │      │
│  │ plugins/compound-engineering/skills/ (18 base skills)      │      │
│  │ src/ (core TypeScript implementation)                      │      │
│  └───────────────────────────────────────────────────────────┘      │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Full Merge vs Selective Merge Comparison

### Scenario A: Full Merge (NOT RECOMMENDED)

```
Before Merge:                    After git merge upstream/main:
┌──────────────┐                ┌──────────────┐
│ Fork (main)  │                │ Fork (main)  │
│              │                │              │
│ 69 commits   │   FULL MERGE   │ 84 commits   │
│ Custom files │  ──────────►   │ MANY FILES   │
│ intact       │                │ DELETED!     │
└──────────────┘                └──────────────┘
       +                               │
┌──────────────┐                       │
│ Upstream     │                       │
│              │                       │
│ 15 commits   │                       │
│ ahead        │                       │
└──────────────┘                       │
                                       ▼
                               ┌──────────────┐
                               │ Result:      │
                               │ ✗ 35 custom  │
                               │   files gone │
                               │ ✗ Gemini     │
                               │   broken     │
                               │ ✗ 8-12 hours │
                               │   recovery   │
                               └──────────────┘
```

### Scenario B: Selective Merge (RECOMMENDED)

```
Before Merge:                    After selective cherry-pick:
┌──────────────┐                ┌──────────────┐
│ Fork (main)  │                │ Fork (main)  │
│              │                │              │
│ 69 commits   │  CHERRY-PICK   │ 74 commits   │
│ Custom files │  (9 commits)   │ Custom files │
│ intact       │  ──────────►   │ PRESERVED    │
└──────────────┘                └──────────────┘
       +                               │
┌──────────────┐                       │
│ Upstream     │                       │
│              │                       │
│ 15 commits   │                       │
│ (pick 9)     │                       │
└──────────────┘                       │
                                       ▼
                               ┌──────────────┐
                               │ Result:      │
                               │ ✓ All custom │
                               │   files safe │
                               │ ✓ 79% token  │
                               │   reduction  │
                               │ ✓ Granular   │
                               │   rollback   │
                               └──────────────┘
```

---

## Upstream Commits Decision Tree

```
Upstream Commit
       │
       ▼
   Is it a refactoring/improvement?
       │
       ├─ YES ──► Does it conflict with fork features?
       │          │
       │          ├─ NO ──► ✓ Cherry-pick directly
       │          │
       │          └─ YES ──► Can we adapt fork to match?
       │                    │
       │                    ├─ YES ──► ✓ Cherry-pick + adapt fork
       │                    │
       │                    └─ NO ──► ✗ Skip, document reason
       │
       └─ NO ──► Is it a new feature?
                  │
                  ├─ YES ──► Does fork need this feature?
                  │          │
                  │          ├─ YES ──► ✓ Cherry-pick
                  │          │
                  │          └─ NO ──► ✗ Skip
                  │
                  └─ NO ──► Is it a deletion?
                             │
                             └─ YES ──► Does fork depend on deleted code?
                                        │
                                        ├─ YES ──► ✗ Skip deletion, keep code
                                        │
                                        └─ NO ──► ✓ Cherry-pick deletion
```

---

## Risk Matrix

```
                High Impact on Fork
                        ▲
                        │
                        │
    P0: CRITICAL        │         P1: HIGH RISK
    ┌───────────────────┼───────────────────┐
    │ • Gemini removal  │ • Token reduction │
    │ • Command deletes │   (needs adapt)   │
    │ • Hook crashes    │ • CLAUDE.md       │
    │                   │   conflicts       │
High├───────────────────┼───────────────────┤
Risk│                   │                   │
    │                   │                   │
    │   P2: MEDIUM      │   P3: LOW RISK    │
    │ ┌─────────────────┼─────────────────┐ │
    │ │ • New skills    │ • New agents    │ │
    │ │ • New commands  │ • Doc updates   │ │
    │ │   (evaluate)    │ • Bug fixes     │ │
Low └─┴─────────────────┼─────────────────┴─┘
Risk                    │
                        └─────────────────────►
                        Low Impact on Fork
```

**Action Guidelines**:
- P0: Must handle immediately with extreme care
- P1: Cherry-pick with extensive testing
- P2: Evaluate case-by-case
- P3: Cherry-pick freely

---

## Cherry-Pick Workflow

```
Start: integrate-upstream-2026-02 branch
   │
   ▼
┌──────────────────────────────────────────┐
│ 1. git cherry-pick <commit-hash>         │
└──────────────────────────────────────────┘
   │
   ├─ Success ──────────────────────────────┐
   │                                         │
   └─ Conflict ──► Resolve ──► Test ────────┤
                      │                      │
                      │                      │
                  Conflict                   │
                  Resolution                 │
                  Protocol:                  │
                      │                      │
                      ├─ Fork-specific file? │
                      │  → git checkout      │
                      │     --ours           │
                      │                      │
                      ├─ Shared logic?       │
                      │  → Merge manually    │
                      │                      │
                      └─ Philosophical       │
                         difference?         │
                         → Keep fork,        │
                            document         │
                                             │
                                             ▼
┌──────────────────────────────────────────┐
│ 2. Validation Suite                      │
│    • powershell check-versions.ps1       │
│    • Test key commands                   │
│    • Verify custom files intact          │
└──────────────────────────────────────────┘
   │
   ├─ Pass ─────────────────────────────────┐
   │                                         │
   └─ Fail ──► git cherry-pick --abort      │
               └──► Debug                    │
                                             │
                                             ▼
┌──────────────────────────────────────────┐
│ 3. git commit (automatic)                 │
└──────────────────────────────────────────┘
   │
   ▼
Next commit in batch?
   │
   ├─ YES ──► Loop back to step 1
   │
   └─ NO ───► Push to origin
              └──► Merge PR
```

---

## File Deletion Risk Map

```
Fork Repository (Files at Risk: 35)
│
├─ plugins/compound-engineering/
│  ├─ commands/
│  │  ├─ ✗ codex.md                      [Tier 1: Critical]
│  │  ├─ ✗ gemini.md                     [Tier 1: Critical]
│  │  └─ workflows/
│  │     ├─ ✗ load.md                    [Tier 1: Critical]
│  │     ├─ ✗ save.md                    [Tier 1: Critical]
│  │     └─ ✗ sync-upstream.md           [Tier 1: Critical]
│  │
│  └─ hooks/                              [Tier 1: Critical]
│     ├─ ✗ hooks.json
│     ├─ ✗ session-start.sh
│     └─ ✗ skill-checking-protocol.md
│
├─ src/
│  ├─ converters/
│  │  └─ ✗ claude-to-gemini.ts           [Tier 1: Critical]
│  ├─ targets/
│  │  └─ ✗ gemini.ts                     [Tier 1: Critical]
│  ├─ types/
│  │  └─ ✗ gemini.ts                     [Tier 1: Critical]
│  └─ utils/
│     └─ ✗ filter-claude-code-only.ts    [Tier 1: Critical]
│
├─ docs/
│  ├─ zh-CN/                              [Tier 2: High Value]
│  │  └─ ✗ 7 Chinese doc files
│  │
│  ├─ solutions/                          [Tier 2: High Value]
│  │  └─ integration-issues/
│  │     └─ ✗ 6 solution docs
│  │
│  └─ sync-reports/                       [Tier 3: Operational]
│     └─ ✗ 2 sync report files
│
├─ scripts/                               [Tier 2: High Value]
│  └─ ✗ 7 automation scripts
│
├─ skills-custom/                         [Tier 3: Operational]
│  └─ ✗ 3 custom skill directories
│
└─ Root files
   ├─ ✗ README.zh-CN.md                   [Tier 2: High Value]
   └─ (CLAUDE.md - modified, not deleted)

Legend:
  ✗ = Would be deleted by full merge
  [Tier 1: Critical] = Breaks core features
  [Tier 2: High Value] = Loses unique capabilities
  [Tier 3: Operational] = Reduces productivity
```

---

## Upstream Changes to Adopt

### Must Adopt (High Priority)

```
┌────────────────────────────────────────────────────────────┐
│ f744b79: Reduce context token usage by 79%                 │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Impact: Major performance improvement                   │ │
│ │ Conflict Risk: HIGH - must adapt fork's custom agents   │ │
│ │ Rollback: Easy (single commit revert)                   │ │
│ └────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ 04ee7e4: Prevent subagent intermediary files               │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Impact: Security enhancement                            │ │
│ │ Conflict Risk: MEDIUM - may affect subagent-branching   │ │
│ │ Rollback: Easy (single commit revert)                   │ │
│ └────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ f7cab16: Fix hook crash (no matcher)                       │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Impact: Stability improvement                           │ │
│ │ Conflict Risk: LOW - hook system is fork-maintained     │ │
│ │ Rollback: Easy (single commit revert)                   │ │
│ └────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

### Should Evaluate (Medium Priority)

```
┌────────────────────────────────────────────────────────────┐
│ a5bba3d: document-review skill                             │
│ e4ff6a8: orchestrating-swarms skill (1718 lines)           │
│ 2429f59: schema-drift-detector agent                       │
│ 1bdd103: sync command (check conflicts)                    │
└────────────────────────────────────────────────────────────┘
```

### Should Ignore (Deletions)

```
┌────────────────────────────────────────────────────────────┐
│ Upstream Deleted (Fork Should Keep):                       │
│ • party-mode/ skill                                        │
│ • systematic-debugging/ skill                              │
│ • test-driven-development/ skill                           │
│ • spec-compliance-review/SKILL.md                          │
│ • glue-coding/ skill                                       │
│ • Gemini support (all files)                               │
│                                                            │
│ Reason: Fork's documented workflows depend on these        │
└────────────────────────────────────────────────────────────┘
```

---

## Version Evolution Timeline

```
Upstream (EveryInc):
v2.28.0 ─── v2.29.0 ─── v2.30.0 ─── v2.31.0 ─── v2.31.1 (current)
   │           │           │           │           │
   │           │           │           │           └─ Minor fixes
   │           │           │           └─ sync command, token reduction
   │           │           └─ orchestrating-swarms skill
   │           └─ schema-drift-detector agent
   └─ Common ancestor (36e7f3a, PR #142)


Fork (Jerrylalala):
v2.37.0 ─── v2.38.0 ─── v2.39.0 ─── v2.40.0 ─── v2.40.1 (current)
   │           │           │           │           │
   │           │           │           │           └─ Sync workflow docs
   │           │           │           └─ Subagent branching
   │           │           └─ Brainstorm CG integration
   │           └─ Gemini/Codex commands
   └─ Gemini CLI integration

┌────────────────────────────────────────────────────────────┐
│ Proposed Post-Merge:                                       │
│ v2.31.1-fork.1                                             │
│ • Adopts upstream v2.31.1 base                             │
│ • Preserves all fork features                              │
│ • Clear version shows upstream lineage                     │
└────────────────────────────────────────────────────────────┘
```

---

## Safety Checklist

### Before Starting

```
[ ] git tag fork-pre-upstream-merge-2026-02
[ ] git push origin fork-pre-upstream-merge-2026-02
[ ] git checkout -b integrate-upstream-2026-02
[ ] powershell scripts/validate-upstream-merge.ps1
[ ] Read UPSTREAM-MERGE-RECOMMENDATION.md completely
```

### During Cherry-Pick

```
[ ] One commit at a time
[ ] Test after each commit
[ ] Document conflict resolutions
[ ] Never use git checkout --theirs for fork files
```

### After Integration

```
[ ] powershell scripts/check-versions.ps1
[ ] Component counts match expected
[ ] Custom files intact (Test-Path checks)
[ ] Key commands functional (/workflows:review [C][G])
[ ] Update CHANGELOG.md
[ ] Update version to 2.31.1-fork.1
```

---

## Quick Command Reference

```bash
# Validation
powershell -ExecutionPolicy Bypass -File scripts/validate-upstream-merge.ps1

# Backup
git tag fork-pre-upstream-merge-2026-02
git push origin fork-pre-upstream-merge-2026-02

# Start integration
git checkout -b integrate-upstream-2026-02

# Cherry-pick (example)
git cherry-pick f7cab16

# If conflicts occur
git status
git diff
git checkout --ours <fork-file>     # Keep fork version
git checkout --theirs <shared-file> # Accept upstream (careful!)
git add .
git cherry-pick --continue

# If need to abort
git cherry-pick --abort

# Test commands
claude --plugin-dir "E:\project\compound-engineering-plugin-private\plugins\compound-engineering"
/workflows:review [C][G]
/workflows:sync-upstream

# Component verification
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count

# File integrity check
Test-Path docs/zh-CN/INSTALL.md
Test-Path plugins/compound-engineering/commands/gemini.md
Test-Path src/converters/claude-to-gemini.ts

# Rollback (if needed)
git reset --hard fork-pre-upstream-merge-2026-02
```

---

## Related Documents

| Document | Purpose | Path |
|----------|---------|------|
| Full Analysis | Detailed architectural analysis | `docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md` |
| Recommendation | Actionable step-by-step guide | `UPSTREAM-MERGE-RECOMMENDATION.md` |
| Validation Script | Automated conflict detection | `scripts/validate-upstream-merge.ps1` |
| Sync Guide | Standard upstream sync process | `docs/zh-CN/SYNC.md` |

---

**Generated**: 2026-02-10
**Next Review**: After integration completes
