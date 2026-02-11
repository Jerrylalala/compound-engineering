---
title: "feat: Integrate Claude Code 2.1.30-2.1.36 Runtime Updates"
type: feat
date: 2026-02-11
brainstorm: docs/brainstorms/2026-02-11-claude-code-runtime-updates-brainstorm.md
---

# Integrate Claude Code Runtime Updates into Plugin v2.42.0

## Overview

Based on five-party brainstorm analysis (3 Claude experts + Codex + Gemini), integrate 3 low-risk, high-value Claude Code runtime updates into the plugin.

## Acceptance Criteria

- [ ] 6 research/review agents have `memory: project` or `memory: user` frontmatter
- [ ] document-review skill supports PDF pages parameter
- [ ] workflows:review and workflows:work commands include fast mode guidance
- [ ] Version bumped to 2.42.0
- [ ] CHANGELOG.md updated
- [ ] All version checks pass

---

## Task 1: Add `memory: project` to learnings-researcher agent

**File**: `plugins/compound-engineering/agents/research/learnings-researcher.md:1-5`
**Operation**:
- [ ] Add `memory: project` to YAML frontmatter (after `model` field)

**Code**:
```yaml
---
name: learnings-researcher
description: "Searches docs/solutions/ for relevant past solutions by frontmatter metadata. Use before implementing features or fixing problems to surface institutional knowledge and prevent repeated mistakes."
model: haiku
memory: project
---
```

**Verify**: File has 4 frontmatter fields (name, description, model, memory)

---

## Task 2: Add `memory: project` to best-practices-researcher agent

**File**: `plugins/compound-engineering/agents/research/best-practices-researcher.md:1-5`
**Operation**:
- [ ] Add `memory: project` to YAML frontmatter

**Code**:
```yaml
---
name: best-practices-researcher
description: "Researches and synthesizes external best practices, documentation, and examples for any technology or framework. Use when you need industry standards, community conventions, or implementation guidance."
model: inherit
memory: project
---
```

**Verify**: File has 4 frontmatter fields

---

## Task 3: Add `memory: project` to git-history-analyzer agent

**File**: `plugins/compound-engineering/agents/research/git-history-analyzer.md:1-5`
**Operation**:
- [ ] Add `memory: project` to YAML frontmatter

**Code**:
```yaml
---
name: git-history-analyzer
description: "Performs archaeological analysis of git history to trace code evolution, identify contributors, and understand why code patterns exist. Use when you need historical context for code changes."
model: inherit
memory: project
---
```

**Verify**: File has 4 frontmatter fields

---

## Task 4: Add `memory: project` to architecture-strategist agent

**File**: `plugins/compound-engineering/agents/review/architecture-strategist.md:1-5`
**Operation**:
- [ ] Add `memory: project` to YAML frontmatter

**Code**:
```yaml
---
name: architecture-strategist
description: "Analyzes code changes from an architectural perspective for pattern compliance and design integrity. Use when reviewing PRs, adding services, or evaluating structural refactors."
model: inherit
memory: project
---
```

**Verify**: File has 4 frontmatter fields

---

## Task 5: Add `memory: project` to repo-research-analyst agent

**File**: `plugins/compound-engineering/agents/research/repo-research-analyst.md:1-5`
**Operation**:
- [ ] Add `memory: project` to YAML frontmatter

**Code**:
```yaml
---
name: repo-research-analyst
description: "Conducts thorough research on repository structure, documentation, conventions, and implementation patterns. Use when onboarding to a new codebase or understanding project conventions."
model: inherit
memory: project
---
```

**Verify**: File has 4 frontmatter fields

---

## Task 6: Add `memory: user` to framework-docs-researcher agent

**File**: `plugins/compound-engineering/agents/research/framework-docs-researcher.md:1-5`
**Operation**:
- [ ] Add `memory: user` (cross-project framework knowledge)

**Code**:
```yaml
---
name: framework-docs-researcher
description: "Gathers comprehensive documentation and best practices for frameworks, libraries, or dependencies. Use when you need official docs, version-specific constraints, or implementation patterns."
model: inherit
memory: user
---
```

**Verify**: File has 4 frontmatter fields. Note: `user` scope because framework knowledge is cross-project.

---

## Task 7: Update document-review skill with PDF pages support

**File**: `plugins/compound-engineering/skills/document-review/SKILL.md:10-14`
**Operation**:
- [ ] Extend Step 1 to handle PDF documents with pages parameter

**Code** (replace Step 1 content, lines 10-14):
```markdown
## Step 1: Get the Document

**If a document path is provided:** Read it, then proceed to Step 2.

**If a PDF is provided:** Use the `pages` parameter to read specific page ranges (max 20 pages per request):
- Small PDFs (< 20 pages): `Read(file_path="doc.pdf", pages="1-20")`
- Large PDFs: `Read(file_path="doc.pdf", pages="1-10")`, then ask if more pages are needed
- User-specified range: `Read(file_path="doc.pdf", pages="<user-specified>")`

**If no document is specified:** Ask which document to review, or look for the most recent brainstorm/plan in `docs/brainstorms/` or `docs/plans/`.
```

**Verify**: Step 1 now mentions PDF and pages parameter

---

## Task 8: Add fast mode tip to workflows:review command

**File**: `plugins/compound-engineering/commands/workflows/review.md:37`
**Operation**:
- [ ] Add performance tip after the examples section (before Prerequisites)

**Code** (insert after line 37, before `## Prerequisites`):
```markdown

> **Performance Tip**: For large PRs or multi-tool reviews ([C][G]), consider enabling `/fast` before running the review. Fast mode uses the same Opus 4.6 model with faster output, reducing review time by ~40%.

```

**Verify**: New performance tip visible between examples and prerequisites

---

## Task 9: Add fast mode tip to workflows:work command

**File**: `plugins/compound-engineering/commands/workflows/work.md:13`
**Operation**:
- [ ] Add performance tip after the introduction paragraph

**Code** (insert after line 13, before `## Input Document`):
```markdown

> **Performance Tip**: For plans with many tasks (Subagent-Driven mode), consider enabling `/fast` before execution. Fast mode uses the same Opus 4.6 model with faster output.

```

**Verify**: New performance tip visible in work command

---

## Task 10: Bump version to 2.42.0

**Files**:
- `.claude-plugin/marketplace.json` → version: "2.42.0"
- `plugins/compound-engineering/.claude-plugin/plugin.json` → version: "2.42.0"

**Operation**:
- [ ] Run `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType minor`
- [ ] Or manually update both files

**Verify**: `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` — ALL CHECKS PASSED

---

## Task 11: Update CHANGELOG.md

**File**: `plugins/compound-engineering/CHANGELOG.md`
**Operation**:
- [ ] Add v2.42.0 entry at the top

**Code**:
```markdown
## [2.42.0] - 2026-02-11

### Added
- **Memory frontmatter** — 为 6 个研究型/架构型 agents 添加 `memory: project/user`，启用跨会话知识积累
- **PDF pages 支持** — document-review skill 现在支持大型 PDF 分页读取
- **Fast mode 引导** — workflows:review 和 workflows:work 命令添加性能优化提示

### Summary
- 29 agents (6 with memory), 31 commands, 23 skills, 1 MCP server
```

**Verify**: CHANGELOG 顶部是 v2.42.0 条目

---

## Task 12: Commit and verify

**Operation**:
- [ ] `git add` all modified files
- [ ] Commit with message: `feat: 整合 Claude Code 2.1.30-2.1.36 运行时更新（v2.42.0）`
- [ ] Run `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1`

**Verify**: Version check passes, git log shows new commit

---

## References

- **Brainstorm**: `docs/brainstorms/2026-02-11-claude-code-runtime-updates-brainstorm.md`
- **Memory frontmatter official docs**: [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)
- **Agent Teams docs**: [code.claude.com/docs/en/agent-teams](https://code.claude.com/docs/en/agent-teams)
- **Codex consultation**: Verified `memory: project | user | local` syntax (not `false` or `long-term`)
