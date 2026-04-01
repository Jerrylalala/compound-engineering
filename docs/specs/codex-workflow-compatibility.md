# Codex Workflow Compatibility

## Purpose

This repository now supports a dual-runtime workflow split:

- Codex handles `brainstorm`, `plan`, and `review`
- Claude continues to handle execution-heavy flows such as `work`

The bridge between the two runtimes is **shared document protocol**, not shared command implementation.

For this private fork, the Codex-side entrypoints are the three repo-scoped skills:

- `workflows-brainstorm`
- `workflows-plan`
- `workflows-review`

## Non-Goals

- Do not rewrite Claude workflow commands to be runtime-agnostic
- Do not force Codex to emulate Claude-only tools such as `AskUserQuestion`, `TodoWrite`, or Claude-specific `Task(...)` conventions
- Do not move execution ownership of `workflows:work` into Codex

## Shared Artifact Directories

Codex writes artifacts that Claude can later consume:

- `docs/brainstorms/`
- `docs/plans/`

## Brainstorm Compatibility Contract

Codex brainstorm output should be written to:

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

Recommended frontmatter:

```yaml
---
title: "..."
date: YYYY-MM-DD
topic: topic-slug
generated_by: codex
status: draft
---
```

Recommended sections:

- `## What We're Building`
- `## Why This Approach`
- `## Approaches Considered`
- `## Key Decisions`
- `## Open Questions`
- `## Next Step`

Claude's `workflows:plan` does not require exact section names, but it does expect the document to preserve decisions, constraints, scope, and unresolved questions.

## Plan Compatibility Contract

Codex plan output should be written to:

`docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

Required frontmatter:

```yaml
---
risk_score: 3
risk_level: low
risk_note: "主要风险来源"
generated_by: codex
source_brainstorm: docs/brainstorms/...
---
```

`source_brainstorm` is optional but recommended.

Required opening header:

```md
## Overview

**Goal**: ...
**Tech Stack**: ...
**Architecture**: ...
```

Required task structure:

````md
### Task 1: ...

**文件**: `path/to/file`
**操作**:
- [ ] ...
- [ ] ...

**代码**:
```language
...
```

**验证**:
- [ ] 运行 `...`
```
````

## Why These Fields Matter

Claude `workflows:work` currently depends on:

1. Plan files living under `docs/plans/*.md`
2. Unfinished checkbox items `- [ ]`
3. Frontmatter risk fields:
   - `risk_score`
   - `risk_level`
4. `## Overview`
5. `**Goal**`
6. `**Tech Stack**`

Everything else is secondary.

## Review Compatibility Contract

Codex review output does not need to be persisted by default.

It should still follow repository review norms:

- findings first
- severity ordering
- file references when possible
- explicit separation between verified issues and assumptions
- no deletion recommendations for:
  - `docs/plans/*.md`
  - `docs/solutions/*.md`

## Runtime Split

### Codex Owns

- idea exploration
- plan drafting
- plan review
- code review

### Claude Owns

- execution via `workflows:work`
- Claude-native tool orchestration
- execution-time TODO management
- execution-time handoff flow

## Maintenance Rule

Keep Claude source workflows in:

`plugins/compound-engineering/commands/workflows/`

Treat them as the authoritative execution implementation.

Keep Codex entry points in:

- `.codex/skills/`

If behavior changes, update the compatibility contract first, then update Codex prompts.
