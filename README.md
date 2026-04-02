# Compound Marketplace

[![Build Status](https://github.com/EveryInc/compound-engineering-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/EveryInc/compound-engineering-plugin/actions/workflows/ci.yml)
[![npm](https://img.shields.io/npm/v/@every-env/compound-plugin)](https://www.npmjs.com/package/@every-env/compound-plugin)

A Claude Code plugin marketplace featuring the **Compound Engineering Plugin** — tools that make each unit of engineering work easier than the last.

## Claude Code Install

```bash
/plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin
/plugin install compound-engineering
```

## OpenCode + Codex + Gemini (experimental) Install

This repo includes a Bun/TypeScript CLI that converts Claude Code plugins to OpenCode, Codex, and Gemini.

```bash
# convert the compound-engineering plugin into OpenCode format
bunx @every-env/compound-plugin install compound-engineering --to opencode

# convert to Codex format
bunx @every-env/compound-plugin install compound-engineering --to codex

# convert to Gemini format
bunx @every-env/compound-plugin install compound-engineering --to gemini
```

Local dev:

```bash
bun run src/index.ts install ./plugins/compound-engineering --to opencode
bun run src/index.ts install ./plugins/compound-engineering --to codex
bun run src/index.ts install ./plugins/compound-engineering --to gemini
```

Install from private fork (temporary env var):

```bash
# Linux/macOS
COMPOUND_PLUGIN_GITHUB_SOURCE=https://github.com/Jerrylalala/compound-engineering-plugin-private \
  bunx @every-env/compound-plugin install compound-engineering --to gemini

# Windows PowerShell
$env:COMPOUND_PLUGIN_GITHUB_SOURCE="https://github.com/Jerrylalala/compound-engineering-plugin-private"
bunx @every-env/compound-plugin install compound-engineering --to gemini
```

**Output locations:**
- OpenCode: `~/.config/opencode/` (opencode.json + agents/, skills/, plugins/)
- Codex: `~/.codex/prompts/` and `~/.codex/skills/` (skill descriptions truncated to 1024 chars)
- Gemini: `.gemini/GEMINI.md` in project root (from CLAUDE.md + command summaries)

## Repo-Scoped Codex Workflows

This private fork also includes repo-scoped Codex workflow skills under `.codex/skills/`.

Current Codex-owned workflows:

- `$workflows-brainstorm`
- `$workflows-plan`
- `$workflows-review`

Preferred Codex entrypoint is **skills**, because custom prompts are deprecated and may not be exposed as slash commands in every Codex CLI build.

These workflow skills are designed to write shared artifacts that remain compatible with the Claude workflows in this repository:

- brainstorms go to `docs/brainstorms/`
- plans go to `docs/plans/`
- Claude can later continue execution with `/workflows:work`

Compatibility details live in `docs/specs/codex-workflow-compatibility.md`.
Quick usage notes live in `docs/zh-CN/CODEX-WORKFLOWS.md`.

For this private fork, future Claude-side development should run the project command `/sil` after changes that affect:

- `brainstorm`
- `plan`
- `review`
- shared document protocol
- Codex minimal skill sync behavior

Do not use `install --to codex` as the day-to-day sync path for this private fork's Codex workflows. That installs the full converted plugin.

Use the dedicated minimal sync script instead:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1
```

If an AI agent or Claude Code is doing the sync for you, that instruction still means the same thing:

- use `scripts/sync-codex-workflows.ps1`
- do **not** use any full-plugin `install --to codex` command

> Note: `COMPOUND_PLUGIN_GITHUB_SOURCE` only affects this CLI tool. Use temporary env vars, not permanent ones.

## Workflow

```
Plan → Work → Review → Compound → Repeat
```

| Command | Purpose |
|---------|---------|
| `/workflows:plan` | Turn feature ideas into detailed implementation plans |
| `/workflows:work` | Execute plans with worktrees and task tracking |
| `/workflows:review` | Multi-agent code review before merging |
| `/workflows:compound` | Document learnings to make future work easier |

Each cycle compounds: plans inform future plans, reviews catch more issues, patterns get documented.

## Philosophy

**Each unit of engineering work should make subsequent units easier—not harder.**

Traditional development accumulates technical debt. Every feature adds complexity. The codebase becomes harder to work with over time.

Compound engineering inverts this. 80% is in planning and review, 20% is in execution:
- Plan thoroughly before writing code
- Review to catch issues and capture learnings
- Codify knowledge so it's reusable
- Keep quality high so future changes are easy

## Learn More

- [Full component reference](plugins/compound-engineering/README.md) - all agents, commands, skills
- [Compound engineering: how Every codes with agents](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents)
- [The story behind compounding engineering](https://every.to/source-code/my-ai-had-already-fixed-the-code-before-i-saw-it)
