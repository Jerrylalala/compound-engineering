---
title: "Public Repository Hardening Plan"
date: 2026-06-01
status: active
scope: public-repo-maintenance
---

# Public Repository Hardening Plan

## Goal

Make `Jerrylalala/compound-engineering` usable and maintainable as a public open-source repository, not only as a private Claude Code fork.

## Non-Negotiable Standard

1. Public users can understand what the project is and how to install it.
2. Public users have clear support, issue, PR, security, license, and contribution paths.
3. Documentation only advertises commands and packages that are currently usable.
4. Release metadata and marketplace identity point to the current public fork.
5. Validation evidence is fresh before the work is called complete.

## Execution Plan

| Priority | Task | Status | Validation |
| --- | --- | --- | --- |
| P0 | Add public repository rules to `AGENTS.md` / `CLAUDE.md` | Done | Manual review |
| P0 | Add community health files and GitHub templates | Done | File existence + public scan |
| P0 | Replace stale security contact with GitHub private advisory path | Done | Public scan |
| P0 | Fix docs strict build blockers | Done | `mkdocs build --strict` |
| P0 | Sync release metadata drift | Done | `bun run release:validate` |
| P1 | Fix public install docs so unregistered npm package is not advertised as available | Done | `npm view` + docs scan |
| P1 | Update plugin README from historical `workflows:*` to current `ce:*` entrypoints | Done | targeted tests + scan |
| P1 | Clarify `[T]` vs `[V]` semantics in `ce-work` | Done | contract tests + scan |
| P1 | Add platform support matrix | Done | `mkdocs build --strict` |
| P2 | Add npm publish readiness checklist for future `@jerry-jian/compound-plugin` release | Done | docs scan |
| P1 | Replace legacy single-version tag/release workflows with release-please PR flow | Done | workflow review + release preview smoke |
| P1 | Add CI coverage for Bun tests, release metadata, feature integrity, and docs strict build | Done | local command parity |

## Explicit Boundary

This plan does not publish `@jerry-jian/compound-plugin` to npm. Publishing requires maintainer authentication and should be a separate release task. Until then, public docs must use the published `@every-env/compound-plugin` CLI with `COMPOUND_PLUGIN_GITHUB_SOURCE=https://github.com/Jerrylalala/compound-engineering`.

## Remaining Follow-Up After This Plan

1. Publish `@jerry-jian/compound-plugin` when npm ownership and release automation are ready.
2. Decide whether historical release changelogs should keep upstream links as provenance or be rewritten for fork-specific releases only.
3. Keep `workflows:*` only in Codex compatibility and historical docs; do not advertise it as the current Claude Code user entrypoint.
