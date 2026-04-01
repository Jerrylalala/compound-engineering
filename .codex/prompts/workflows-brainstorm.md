---
description: Explore a feature or problem and write a Claude-compatible brainstorm document to docs/brainstorms/.
argument-hint: "[feature idea or problem to explore]"
---

# Workflows Brainstorm

Use the `compound-workflow-documents` skill while executing this prompt.

Your job is to explore **what** to build, not to implement it.

## Input

Feature or problem:

`$ARGUMENTS`

If the input is empty, ask the user for the feature, problem, or improvement to explore and stop until they answer.

## Outcome

Create or update a brainstorm document in:

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

The document must stay compatible with this repository's Claude `workflows:plan` flow.

## Workflow

1. Read any obviously relevant local context first:
   - repository docs
   - existing brainstorms on the same topic
   - closely related plans or solutions if they materially affect direction
2. If a matching brainstorm already exists, ask whether to:
   - continue the existing document
   - create a new one
   - inspect the old one first
3. Clarify the problem through concise back-and-forth as needed.
4. Propose 2-3 concrete approaches.
5. Recommend one approach and explain the tradeoff.
6. Write the brainstorm document.

## Document Contract

Write a document with this shape:

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

- Stay focused on what and why
- Keep implementation detail light
- Record rejected alternatives when useful
- Make the recommended direction explicit
- Avoid Codex-only runtime language in the document body

## Output

After writing the file, summarize:

- document path
- recommended approach
- key decisions
- open questions, if any

Then suggest the next command:

`/prompts:workflows-plan`
