---
description: Review code changes or a branch with a findings-first report that fits this repository's workflow style.
argument-hint: "[PR number, GitHub URL, branch name, file path, or current branch]"
---

# Workflows Review

Use the `compound-workflow-documents` skill while executing this prompt.

Your default mode is code review.

## Input

Review target:

`$ARGUMENTS`

If the input is empty, review the current branch or current workspace diff.

## Review Rules

- Findings first
- Order by severity
- Focus on bugs, regressions, risky assumptions, missing tests, and operational risk
- Use file references when possible
- Clearly label assumptions
- If there are no findings, state that explicitly and mention residual risk

## Protected Artifacts

Do not recommend deleting, gitignoring, or treating these as junk:

- `docs/plans/*.md`
- `docs/solutions/*.md`

## Target Handling

If the target is:

- a PR number or GitHub URL: review that PR
- a branch name: inspect that branch diff against the default branch
- a markdown plan file: perform a plan-quality review instead of a code review
- empty: review current branch or uncommitted changes

## Review Depth

Check for:

- correctness
- data integrity
- security
- performance
- architectural fit
- test coverage gaps
- mismatch with the repository's documented workflow expectations

## Output Format

Use this shape:

```md
Findings

1. [severity] Summary with file reference
2. ...

Open Questions

- ...

Residual Risks

- ...

Change Summary

[brief only]
```

If the target is a plan file, focus on:

- unclear scope
- missing constraints
- non-atomic tasks
- vague file paths
- missing verification steps
- weak risk assessment
- anything that would make Claude `workflows:work` execute poorly later
