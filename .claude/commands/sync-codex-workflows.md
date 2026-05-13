---
name: sync-codex-workflows
description: Sync only the three Codex workflow skills for this private fork
---

# /sync-codex-workflows

Use this command when you need to update Codex after changing the repository's Codex workflow skills.

## Purpose

This repository only wants these three workflow skills synced into Codex:

- `workflows-brainstorm`
- `workflows-plan`
- `workflows-review`

Do not install the full converted plugin into Codex for day-to-day sync.

## Execute

Run exactly:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1
```

## Verify

After syncing, check that `~/.codex/skills/` contains the updated workflow entrypoints for this repository:

- `workflows-brainstorm`
- `workflows-plan`
- `workflows-review`

Other user-installed global Codex skills may still exist. The sync script removes known stale workflow duplicates, not arbitrary user skills.

## Hard Guardrail

Never replace this command with:

```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex
```

That command installs the full converted plugin and will pollute `~/.codex` with extra workflow entries.
