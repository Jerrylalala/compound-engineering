# Upstream Merge Recommendation - February 2026

**Date**: 2026-02-10
**Analysis**: E:\project\compound-engineering-plugin-private\docs\solutions\integration-issues\upstream-merge-architectural-analysis-2026-02-10.md

---

## Executive Decision

**DO NOT use `git merge upstream/main`**

Recommended approach: **Hybrid Selective Merge** (cherry-pick valuable commits only)

---

## Quick Facts

| Metric | Value |
|--------|-------|
| Files changed in merge | 185 files |
| Lines changed | +8238/-15282 (net -7044) |
| **Custom files at deletion risk** | **33 files** |
| Upstream commits to evaluate | 15 commits |
| Fork commits since divergence | 69 commits |

---

## Why Full Merge is Dangerous

### Critical Files That Would Be Deleted

**Your Custom Features** (10 files):
- `commands/codex.md`, `commands/gemini.md` - Multi-LLM consultation
- `commands/workflows/load.md`, `save.md`, `sync-upstream.md` - Session management
- `hooks/*` - Skill enforcement system
- `src/converters/claude-to-gemini.ts` - Gemini integration core

**Your Documentation** (7 files):
- All `docs/zh-CN/*` - Chinese documentation

**Your Automation** (7 files):
- All `scripts/*.ps1` - Version management, review automation

**Your Knowledge Base** (6 files):
- All `docs/solutions/integration-issues/*` - Solution documentation

**Your Custom Skills** (3 directories):
- All `skills-custom/*` - Fork-specific skills

---

## Upstream Changes You SHOULD Adopt

### High Priority (Cherry-Pick These)

1. **Token Usage Reduction (79%)** - Commit f744b79
   - Removes redundant skill references from agents
   - Major performance improvement
   - Requires adapting fork's custom agents

2. **Subagent Security Fix** - Commit 04ee7e4
   - Prevents intermediary file writing
   - Security enhancement
   - May conflict with fork's `subagent-branching` skill

3. **Hook Crash Fix** - Commit f7cab16
   - Fixes crash when hook entries have no matcher
   - Low conflict risk

4. **Plan File Protection** - Commit 9f93f54
   - Already merged in commit 685bc3f
   - No action needed

### Medium Priority (Evaluate Carefully)

5. **New `document-review` skill** - Commit a5bba3d
   - Refines brainstorms/plans
   - No conflicts expected

6. **New `schema-drift-detector` agent** - Commit 2429f59
   - Database schema monitoring
   - No conflicts expected

7. **New sync command** - Commit 1bdd103
   - Syncs config to ~/.claude/, Codex, OpenCode
   - May conflict with fork's `sync-upstream` command (different purpose)

8. **New `/slfg` command** - Commit e4ff6a8
   - "Self-Learning From Grokking" workflow
   - No conflicts expected

### Low Priority (Optional)

9. **New `orchestrating-swarms` skill** - Commit e4ff6a8 (1718 lines)
   - Multi-agent coordination
   - May conflict with fork's `subagent-branching` approach
   - Evaluate if philosophies align

---

## Upstream Changes You SHOULD IGNORE

### Deletions Fork Depends On

**Upstream removed these skills**, but fork's `CLAUDE.md` references them:
- `party-mode/` (16 files) - Multi-persona brainstorming
- `systematic-debugging/` (4 files) - Debugging workflow
- `test-driven-development/` (2 files) - TDD workflow
- `spec-compliance-review/SKILL.md` - Pre-review validation
- `glue-coding/` (2 files) - Integration patterns

**Decision**: Fork should maintain these independently. Removing them breaks documented workflows.

### Feature Removals

**Upstream removed Gemini support**:
- `src/converters/claude-to-gemini.ts`
- `src/targets/gemini.ts`
- `src/types/gemini.ts`

**Decision**: Fork keeps Gemini support. This is fork's flagship feature (v2.37.0-v2.40.1).

---

## Recommended Action Plan

### Phase 1: Backup (5 minutes)

```bash
git tag fork-pre-upstream-merge-2026-02
git push origin fork-pre-upstream-merge-2026-02
git checkout -b integrate-upstream-2026-02
```

### Phase 2: Cherry-Pick Low-Risk Commits (30 minutes)

```bash
git cherry-pick f7cab16  # Hook crash fix
git cherry-pick a5bba3d  # document-review skill
git cherry-pick 2429f59  # schema-drift-detector agent

# Test after each
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

### Phase 3: Cherry-Pick High-Value Refactoring (2-4 hours)

```bash
git cherry-pick 04ee7e4  # Subagent security fix
# EXPECT CONFLICTS - resolve carefully

git cherry-pick f744b79  # 79% token reduction
# EXPECT CONFLICTS - apply pattern to fork's agents
```

**Conflict Resolution**:
- If file is fork-specific → `git checkout --ours <file>`
- If upstream improves shared logic → Merge manually
- Test extensively after each resolution

### Phase 4: Manual Integration (2-3 hours)

1. Review `orchestrating-swarms` skill content
2. Decide if it replaces or complements `subagent-branching`
3. Document decision in `docs/solutions/`

### Phase 5: Validation (30 minutes)

```bash
# Version consistency
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# Component counts
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count    # Should be 28+
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count  # Should be 29
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count      # Should be 20+

# Custom files intact
Test-Path docs/zh-CN/INSTALL.md
Test-Path plugins/compound-engineering/commands/gemini.md
Test-Path src/converters/claude-to-gemini.ts

# Functional tests
claude --plugin-dir "E:\project\compound-engineering-plugin-private\plugins\compound-engineering"
/workflows:review [C][G]
/workflows:sync-upstream
```

If ANY validation fails: Rollback with `git reset --hard fork-pre-upstream-merge-2026-02`

### Phase 6: Documentation (30 minutes)

Update these files:
- `CHANGELOG.md` - Document integrated changes
- `docs/zh-CN/SYNC.md` - Add section explaining this merge decision
- `.claude-plugin/marketplace.json` - Bump version if needed
- `plugins/compound-engineering/.claude-plugin/plugin.json` - Sync version

---

## Rollback Strategy

**If things go wrong**:

```bash
# Option 1: Undo last cherry-pick
git cherry-pick --abort

# Option 2: Reset entire branch
git reset --hard fork-pre-upstream-merge-2026-02

# Option 3: Revert specific commit
git revert <commit-hash>
```

**Safety Net**: All cherry-picks are individually revertible. Full merge is not.

---

## Long-Term Strategy

### Prevent Future Conflicts

1. **Create `.fork-manifest.json`** - Document custom namespaces
2. **Automate conflict detection** - Run `scripts/validate-upstream-merge.ps1` before merging
3. **Document divergence decisions** - Maintain `docs/solutions/` for "why not merged"

### Reduce Divergence

1. **Consider extracting Gemini support** - Publish as separate npm package `@jerrylalala/claude-plugin-gemini-adapter`
2. **Adopt fork versioning scheme** - Use `2.31.1-fork.1` format (shows upstream base + fork patches)
3. **Contribute valuable patterns upstream** - Submit PR for hooks system, session management

### Monitor Upstream

Continue using `/workflows:sync-upstream` weekly to detect changes early. Smaller, frequent merges are safer than large infrequent ones.

---

## Key Architectural Findings

### What Fork Does Right

1. **Clean separation of concerns** - Custom files in distinct namespaces
2. **Non-invasive extension** - Adds capabilities without modifying upstream core
3. **SOLID compliance** - Uses dependency inversion, hooks for behavior injection

### What Needs Improvement

1. **Upstream doesn't recognize fork's extension pattern** - No `.gitattributes` or manifest
2. **Token usage not aligned with upstream** - Fork's agents not refactored like upstream's
3. **Philosophical divergence** - Fork keeps skills upstream removed (party-mode, etc.)

### Critical Learning

**Upstream removed Gemini support and several skills that fork depends on.**

This isn't technical debt - it's legitimate architectural divergence. Fork serves different user needs than upstream. Forcing alignment would destroy fork's value proposition.

**Decision**: Maintain fork as "opinionated distribution" rather than "pure mirror."

---

## Questions & Answers

**Q: Can I ever do a full `git merge upstream/main` safely?**

A: Only if upstream adds explicit support for fork extension patterns (e.g., respects `skills-custom/`, hooks manifest). Current upstream architecture doesn't support this.

**Q: How often should I sync?**

A: Weekly checks with `/workflows:sync-upstream`. Monthly selective merges. This merge covered 15 commits - reasonable batch size.

**Q: What if I already ran `git merge upstream/main`?**

A: Don't commit yet! Run:
```bash
git merge --abort
git checkout main
```

If already committed:
```bash
git reset --hard origin/main  # WARNING: Loses uncommitted work
```

**Q: Should I remove skills upstream deleted?**

A: No. Fork's `CLAUDE.md` documents workflows using `party-mode`, `systematic-debugging`, `test-driven-development`. Removing them breaks user expectations. Maintain them independently.

---

## Final Checklist

Before merging any upstream changes:

- [ ] Created backup tag `fork-pre-upstream-merge-2026-02`
- [ ] Created integration branch `integrate-upstream-2026-02`
- [ ] Listed custom files at risk (33 files documented)
- [ ] Identified valuable upstream commits (9 commits listed)
- [ ] Prepared rollback plan (documented above)
- [ ] Allocated sufficient time (6-10 hours total)
- [ ] Have current tests passing (validation commands ready)
- [ ] Documented architectural decisions (this file)

---

**Full Analysis**: `E:\project\compound-engineering-plugin-private\docs\solutions\integration-issues\upstream-merge-architectural-analysis-2026-02-10.md`

**Start Command**:
```bash
git checkout -b integrate-upstream-2026-02
git cherry-pick f7cab16
```
