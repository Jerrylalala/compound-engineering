---
name: sil
description: Sync Codex integration layer after changing shared workflows, protocol, or install chain
---

# /sil

Use this command when work in this repository changes any Claude-facing workflow behavior that must remain reflected in the Codex integration layer.

## When To Use

Run `/sil` after any of these:

- changed `plugins/compound-engineering/commands/workflows/brainstorm.md`
- changed `plugins/compound-engineering/commands/workflows/plan.md`
- changed `plugins/compound-engineering/commands/workflows/review.md`
- changed shared document contract for `docs/brainstorms/` or `docs/plans/`
- changed Codex install behavior in `src/converters/claude-to-codex.ts`, `src/targets/codex.ts`, or related types
- changed user-facing Codex workflow docs or README install guidance

Do not use `/sil` for unrelated changes that do not affect the Codex mirror.

## Goal

Keep the Codex-side workflow layer aligned without mutating Claude execution workflows into runtime-agnostic abstractions.

Codex-owned layer:

- `.codex/prompts/workflows-brainstorm.md`
- `.codex/prompts/workflows-plan.md`
- `.codex/prompts/workflows-review.md`
- `.codex/skills/compound-workflow-documents/SKILL.md`

Shared contract and usage docs:

- `docs/specs/codex-workflow-compatibility.md`
- `docs/zh-CN/CODEX-WORKFLOWS.md`
- `README.md`

Install-chain files when needed:

- `src/types/codex.ts`
- `src/converters/claude-to-codex.ts`
- `src/targets/codex.ts`

## Procedure

1. Read the current diff and identify whether the change affects:
   - brainstorm behavior
   - plan document structure
   - review output expectations
   - Codex installation or discovery
2. Update the matching `.codex` prompt or skill files.
3. If the shared document contract changed, update `docs/specs/codex-workflow-compatibility.md` first.
4. If local or installed usage changed, update `docs/zh-CN/CODEX-WORKFLOWS.md` and `README.md`.
5. If install behavior changed, verify with a fresh `install --to codex` run against a temporary target.
6. Report exactly what was synced and what was intentionally left unchanged.

## Guardrails

- Do not rewrite Claude `workflows:work` to fit Codex.
- Do not change Claude source workflows unless the user explicitly asked for Claude-side behavior changes.
- Keep shared artifact protocol stable unless there is a strong reason to change it.
- Prefer updating compatibility docs before updating prompts.

## Expected Result

After `/sil`, this repository should satisfy both:

1. Claude-only usage still works unchanged.
2. Codex-owned `brainstorm / plan / review` remains aligned with the current repository behavior.
