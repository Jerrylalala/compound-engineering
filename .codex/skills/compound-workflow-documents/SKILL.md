---
name: compound-workflow-documents
description: Produce shared docs for docs/brainstorms and docs/plans while preserving compatibility with this repository's Claude workflows, especially workflows:plan and workflows:work.
---

# Compound Workflow Documents

Use this skill when creating or updating workflow documents that must work in both Codex and Claude.

## Scope

This skill governs:

- `docs/brainstorms/*.md`
- `docs/plans/*.md`
- Codex prompts that generate those files

It does **not** govern implementation execution. Claude remains the execution runtime for `workflows:work`.

## Core Rule

Share **document protocols**, not runtime behavior.

- Codex may analyze, structure, and write documents
- Claude may later read the same documents and execute from them
- Do not embed Codex-only runtime instructions into shared artifacts

## Brainstorm Protocol

Write brainstorm files to:

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

Preferred structure:

```md
---
title: "..."
date: YYYY-MM-DD
topic: topic-slug
generated_by: codex
status: draft
---

# ...

## What We're Building
## Why This Approach
## Approaches Considered
## Key Decisions
## Open Questions
## Next Step
```

Requirements:

- Focus on **what** and **why**, not implementation detail
- Record rejected alternatives when relevant
- Keep at least one clear recommended direction
- Keep open questions explicit
- Avoid Codex-only terms like `spawn_agent`, `/prompts:`, or tool names in the document body

## Plan Protocol

Write plan files to:

`docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

Required frontmatter:

```yaml
---
risk_score: 0
risk_level: low
risk_note: "..."
generated_by: codex
source_brainstorm: docs/brainstorms/...
---
```

`source_brainstorm` is optional when there is no matching brainstorm, but include it when available.

Required header:

```md
## Overview

**Goal**: ...
**Tech Stack**: ...
**Architecture**: ...
```

Required task shape:

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

Requirements:

- Include real `- [ ]` checkboxes so Claude can mark progress later
- Keep tasks atomic enough for later execution
- Prefer exact file paths
- Prefer concrete snippets over vague pseudocode
- Do not write "to be determined", `...`, or abstract placeholders inside the task code blocks

## Review Protocol

For Codex review output:

- Present findings first, ordered by severity
- Include file references when possible
- Distinguish verified issues from assumptions
- Do not suggest deleting `docs/plans/*.md` or `docs/solutions/*.md`

Review output may stay in chat unless the user explicitly asks for a file.

## Compatibility Guardrails

Before finalizing a brainstorm or plan, check:

- Is the file going into the expected shared directory?
- Would Claude understand this file without knowing anything about Codex?
- Does the plan contain frontmatter risk fields?
- Does the plan contain `## Overview`, `**Goal**`, and `**Tech Stack**`?
- Does the plan contain executable checkbox tasks?

If any answer is no, fix the document before finishing.
