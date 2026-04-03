# Executable Plan Protocol

This document defines the execution-state contract for plan files in `docs/plans/`.

The goal is simple:

- `/workflows:plan` produces a plan that can be executed by `/workflows:work`
- `/workflows:work` updates progress without ambiguity
- `/workflows:review` never corrupts execution state

## Scope

Applies to:

- `docs/plans/*.md`
- `plugins/compound-engineering/commands/workflows/plan.md`
- `plugins/compound-engineering/commands/workflows/work.md`
- `plugins/compound-engineering/commands/workflows/review.md`
- Codex `workflows-plan` skill

## Protocol Version

Use this frontmatter field in executable plans:

```yaml
plan_protocol: executable_checkboxes_v1
```

This field is additive and backward compatible. Existing consumers that do not read it must continue to work.

## State Rules

### 1. Live checkboxes

Only the following checkboxes are considered execution state:

- Checkboxes inside a `### Task N:` block
- Checkboxes under that task's `**操作**`
- Checkboxes under that task's `**验证**`

These are the only checkboxes that `/workflows:work` should treat as unfinished work.

### 2. Non-state content

The following must not be treated as execution state:

- Checkboxes inside code fences
- Template examples
- Instructional checklists in workflow definitions
- Narrative notes
- Acceptance criteria written outside task blocks

In generated plan files, non-executable items should use plain bullets (`-`) instead of task checkboxes whenever possible.

### 3. Completion semantics

- `- [ ]` means the step is not yet completed
- `- [x]` means the step has been completed and verified

Completed checkboxes are append-only state. They must not be reverted to unchecked as part of review.

### 4. Rework semantics

If review or later implementation reveals follow-up work:

- do not change a completed item from `- [x]` back to `- [ ]`
- append a new follow-up task
- or create a new plan if the change is large enough

This preserves historical truth and avoids progress corruption.

## Authoring Rules

Executable plans must include:

- frontmatter with `risk_score`, `risk_level`, `risk_note`
- `plan_protocol: executable_checkboxes_v1`
- `## Overview`
- `**Goal**`
- `**Tech Stack**`
- one or more `### Task N:` sections
- at least one live checkbox under `**操作**` or `**验证**`

## Work Reconciliation Rules

Before `/workflows:work` pauses or exits, it must reconcile the active plan:

- mark completed task checkboxes from `- [ ]` to `- [x]`
- ensure verification checkboxes are updated when verification has actually been run
- ignore example or template checkboxes outside task blocks

If code is complete but the plan state is stale, the plan must be corrected before claiming completion.
