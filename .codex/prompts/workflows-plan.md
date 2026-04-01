---
description: Turn a feature idea or brainstorm into a Claude-compatible implementation plan in docs/plans/.
argument-hint: "[feature description, brainstorm topic, or plan target]"
---

# Workflows Plan

Use the `compound-workflow-documents` skill while executing this prompt.

Your job is to write a plan that Codex can reason about now and Claude can later execute through `workflows:work`.

## Input

Planning target:

`$ARGUMENTS`

If the input is empty, ask the user what they want to plan and stop until they answer.

## Outcome

Create a plan file in:

`docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

The plan must remain compatible with this repository's Claude `workflows:work`.

## Required Research Flow

1. Look for a recent matching brainstorm in `docs/brainstorms/`.
2. If a relevant brainstorm exists:
   - treat it as the origin document
   - carry forward key decisions, constraints, scope boundaries, and open questions
   - reference it explicitly in the plan
3. Do lightweight local research for:
   - similar code patterns
   - relevant docs or solutions
   - file paths that the plan should reference
4. Ask brief clarification questions only when needed.

## Risk Assessment

Score these five dimensions from 0-2:

- 安全/隐私
- 可逆性
- 影响范围
- 变更规模
- 外部依赖

Map the total:

- 0-3 → `low`
- 4-6 → `medium`
- 7-10 → `high`

Write these fields into frontmatter:

```yaml
---
risk_score: 3
risk_level: low
risk_note: "主要风险来源"
generated_by: codex
source_brainstorm: docs/brainstorms/...
---
```

Omit `source_brainstorm` only when there is genuinely no relevant brainstorm.

## Plan Contract

The plan must begin with:

```md
## Overview

**Goal**: ...
**Tech Stack**: ...
**Architecture**: ...
```

Then include executable tasks using this exact pattern:

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

## Task Requirements

- Make tasks atomic enough for later execution
- Use real file paths whenever they can be known
- Include concrete code sketches rather than abstract pseudocode
- Include explicit verification commands
- Use real `- [ ]` checkboxes because Claude will later mark them complete

## Additional Sections

Add only the sections that help execution. Prefer practical content over ceremony.

Good candidates:

- Requirements
- Constraints
- References
- Acceptance Criteria
- Open Questions

## Output

After writing the file, report:

- plan path
- risk score and risk level
- whether a brainstorm was used
- the next recommended step

When suggesting the next step, prefer:

- low risk: Claude `workflows:work`
- medium/high risk: Codex review first or Claude review after implementation
