---
name: sil
description: Sync the minimal Codex workflow layer after changing brainstorm, plan, or review behavior
---

# /sil

Use this command when work in this repository changes any Claude-facing workflow behavior that must remain reflected in the Codex integration layer.

## When To Use

Run `/sil` after any of these:

- changed `plugins/compound-engineering/commands/workflows/brainstorm.md`
- changed `plugins/compound-engineering/commands/workflows/plan.md`
- changed `plugins/compound-engineering/commands/workflows/review.md`
- changed shared document contract for `docs/brainstorms/` or `docs/plans/`
- changed the minimal Codex workflow sync script
- changed user-facing Codex workflow docs or README guidance

Do not use `/sil` for unrelated changes that do not affect the Codex mirror.

## Goal

Keep the Codex-side workflow layer aligned without mutating Claude execution workflows into runtime-agnostic abstractions.

For this private fork, `/sil` means **minimal Codex sync only**. It does not mean reinstalling the full converted plugin into Codex.

Codex-owned layer:

- `.codex/skills/workflows-brainstorm/SKILL.md`
- `.codex/skills/workflows-plan/SKILL.md`
- `.codex/skills/workflows-review/SKILL.md`

Shared contract and usage docs:

- `docs/specs/codex-workflow-compatibility.md`
- `docs/zh-CN/CODEX-WORKFLOWS.md`
- `README.md`

Sync mechanism:

- `scripts/sync-codex-workflows.ps1`

## Procedure

1. Read the current diff and identify whether the change affects:
   - brainstorm behavior
   - plan document structure
   - review output expectations
   - Codex installation or discovery
2. Update the matching `.codex` skill files.
3. If the shared document contract changed, update `docs/specs/codex-workflow-compatibility.md` first.
4. If local or installed usage changed, update `docs/zh-CN/CODEX-WORKFLOWS.md` and `README.md`.
5. Run exactly:
   `powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1`
6. Verify only these three skills remain as top-level workflow entrypoints in `~/.codex/skills/`:
   - `workflows-brainstorm`
   - `workflows-plan`
   - `workflows-review`
7. Report exactly what was synced and what was intentionally left unchanged.

## Hard Guardrail

Never use any of the following as the sync path for this repository's Codex workflows:

- `bun run src/index.ts install ./plugins/compound-engineering --to codex`
- `bunx @every-env/compound-plugin install compound-engineering --to codex`
- any other full-plugin Codex install command

Reason: those commands install the entire converted plugin and reintroduce stale or extra workflow entrypoints.

## Guardrails

- Do not rewrite Claude `workflows:work` to fit Codex.
- Do not change Claude source workflows unless the user explicitly asked for Claude-side behavior changes.
- Keep shared artifact protocol stable unless there is a strong reason to change it.
- Prefer updating compatibility docs before updating skills.

## Expected Result

After `/sil`, this repository should satisfy both:

1. Claude-only usage still works unchanged.
2. Codex-owned `brainstorm / plan / review` remains aligned with the current repository behavior.
3. The sync process only updates the three Codex workflow skills instead of reinstalling the full plugin into Codex.
