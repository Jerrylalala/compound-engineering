---
title: Public Repository Readiness
date: 2026-06-01
topic: public-repo-readiness
generated_by: codex
status: active
---

# Public Repository Readiness Brainstorm

## What We're Building

Turn `Jerrylalala/compound-engineering` from a personal/private workflow fork into a public open-source repository that external users can understand, install, trust, and contribute to.

This is not a rewrite of the plugin. The first pass should fix public-facing trust and stability gaps, then leave larger positioning and architecture improvements for follow-up plans.

## Problem Frame

The repository has useful workflow assets, converters, docs, and release infrastructure, but it still shows private/Claude Code-first assumptions in several places:

- Missing community health files make contribution and support paths unclear.
- Security reporting still points at an upstream maintainer email.
- Documentation and metadata drift make public claims hard to trust.
- Claude-only language appears in first-contact documentation even though the repository now matters as multi-tool workflow infrastructure.
- Existing validation commands disagree: lightweight integrity checks can pass while release metadata or full tests fail.

If left alone, new users can install the wrong thing, follow stale docs, report issues in the wrong place, or assume the project is less maintained than it is.

## Requirements

### P1 — Must Have

- R1. Public users must have clear contribution, support, issue, PR, security, privacy, and license entry points.
- R2. Security reporting must point to the current project, not upstream maintainers.
- R3. Public docs must build under the same strictness expected in CI.
- R4. Release metadata drift must be detected and fixed through the repository's release metadata path, not one-off manual edits.
- R5. Public-facing docs must not present deprecated `workflows:*` names as current user entrypoints.
- R6. Any public-ready claim must cite fresh validation evidence or explicitly name the remaining failing checks.

### P2 — Should Have

- R7. Rewrite the top-level README around public users: what this is, who it is for, supported targets, quick install, stability matrix, and contribution paths.
- R8. Add CI coverage for `bun test`, `bun run release:validate`, `mkdocs build --strict`, and feature integrity on PRs.
- R9. Document target support status for Claude Code, Codex, Gemini, OpenCode, Copilot, Cursor, Windsurf, Kiro, Qwen, Droid, Pi, and OpenClaw.
- R10. Move Claude-only features into clearly marked legacy/Claude-only sections.

### P3 — Could Have

- R11. Add a public roadmap and labels for good first issues, docs, converter targets, and compatibility bugs.
- R12. Add badges for tests, docs, release, package version, and license after CI is reliable.
- R13. Add examples for Windows PowerShell and POSIX shells for the most common install paths.

### P4 — Later / Parking Lot

- R14. Split public docs into user guide, maintainer guide, and historical records.
- R15. Decide whether the package name should stay `@jerry-jian/compound-plugin` or move toward a clearer public package namespace.
- R16. Decide whether to keep Claude marketplace as the primary distribution story or treat it as one target among many.

## Reuse / Build Boundary

### Existing capabilities to reuse

- Existing release metadata scripts: `scripts/release/validate.ts`, `scripts/release/sync-metadata.ts`.
- Existing docs build path: `mkdocs.yml` and `requirements-docs.txt`.
- Existing feature drift check: `scripts/check-feature-integrity.sh`.
- Existing repo instruction authority: `AGENTS.md`.
- Existing Codex compatibility contract and sync script: `docs/specs/codex-workflow-compatibility.md`, `scripts/sync-codex-workflows.ps1`.

### Glue code we expect to write

- Community markdown/YAML templates.
- Small docs-link/nav fixes so MkDocs strict mode can pass.
- Metadata sync via existing release script.
- CI wiring in a follow-up plan, not necessarily in this first pass.

### Net-new behavior

- Clear public repository maintenance rules.
- Public contributor and support workflow.
- Public issue and PR intake forms.

### Explicit non-goals

- Do not remove Claude Code support in this pass.
- Do not rewrite all user-facing documentation in one PR.
- Do not hand-author release-owned version bumps outside the metadata automation path.
- Do not delete `docs/plans/`, `docs/brainstorms/`, or `docs/solutions/` as "cleanup".

## Why This Approach

The highest leverage first step is not adding new features. It is making the repository externally legible and verifiable. Once a public user can understand the project and CI can prove the basics, deeper README restructuring and target support documentation become much safer.

## Approaches Considered

### Option A — Minimal public hygiene first

Add community files, fix security/support entrypoints, fix docs strict build, fix release metadata drift, and document remaining failures.

Pros:
- Small, high-confidence change set.
- Immediately improves public trust.
- Uses existing scripts and docs infrastructure.

Cons:
- Does not fully solve README positioning.
- Leaves some Claude-first copy for follow-up.

### Option B — Full public relaunch

Rewrite README, docs navigation, CI, release, support, and target matrix in one large pass.

Pros:
- Produces a cleaner public launch story faster.
- Reduces duplicate or stale docs in one sweep.

Cons:
- Higher regression risk.
- Easy to mix historical records, public docs, and converter behavior.
- Harder to verify in one turn.

### Option C — Rules only

Only update `AGENTS.md` / `CLAUDE.md` with public maintenance rules.

Pros:
- Lowest risk.
- Sets direction for future work.

Cons:
- Does not help external users today.
- Leaves known broken checks and missing community files in place.

Recommended: Option A now, then follow with focused plans for README positioning and CI hardening.

## Key Decisions

- Public repository readiness is a product requirement, not just documentation polish.
- `AGENTS.md` remains the canonical rule source; `CLAUDE.md` is a compatibility shim.
- Community health files are P1 because they affect how strangers interact with the project.
- Strict docs build and release metadata validation are P1 because they determine whether public claims are trustworthy.
- README repositioning is important but should be a separate P2 pass to avoid over-expanding this change.

## Scope Boundaries

In scope for the first implementation pass:

- Community health files.
- Security/support reporting correction.
- Docs strict build fixes.
- Release metadata drift fix using existing automation.
- Brainstorm artifact.

Out of scope for the first implementation pass:

- Full README rewrite.
- Full target support matrix.
- Full CI redesign.
- Removing or deprecating plugin features.
- Publishing or tagging a release.

## Historical Context

- Earlier repo audit established that the current canonical workflow is `ce:*` skill-first and `workflows:*` is historical/deprecated alias territory.
- Codex compatibility should remain minimal: `workflows-brainstorm`, `workflows-plan`, and `workflows-review`, with shared documents as the bridge.
- Previous docs/config audit already identified stale command names and repo URL drift as user-facing failure modes.
- Release validation is more reliable than ad hoc version checks for plugin/marketplace metadata drift.

## Party Mode Summary

### Round 1 — Divergence

👤 User Advocate: New users need a direct path: what this is, how to install, where to report bugs, and what is supported. Missing community files and stale security contact block trust before the plugin is even tried.

🧭 Technical Lead: The validation story must be consistent. Passing a lightweight check while `release:validate`, `bun test`, or docs strict build fails creates false confidence. Public readiness needs a baseline, not vibes.

🧨 Devil's Advocate: The project still sells Claude Code-specific features heavily. If the maintainer no longer primarily uses Claude Code, public docs must not anchor the project to a tool that is no longer the maintainer's main workflow.

### Round 2 — Challenge And Convergence

👤 User Advocate: Do not start with a huge README rewrite. First make the project safe to approach: contribution, support, issue/PR templates, security route, and docs build.

🧭 Technical Lead: Use existing release and docs automation rather than writing new systems. The repository already has enough infrastructure; the first job is wiring and consistency.

🧨 Devil's Advocate: Avoid pretending the whole thing is stable after community files are added. Leave explicit residual risk for failing tests and any remaining Claude-first documentation.

## Areas Of Agreement

- Public trust files are missing or stale and should be fixed first.
- Documentation strictness matters for a public docs site.
- Release metadata drift should be fixed through automation.
- README needs a follow-up rewrite, but not in the same first pass.

## Areas Of Disagreement

- Whether to reframe the whole project immediately or after P1 hygiene.
- Whether Claude Code should remain the first install path or become one target among many.
- Whether all target support should be documented now or after validation is improved.

## Coverage Matrix

| Dimension | Answer |
|---|---|
| Problem | Public users cannot reliably understand, install, trust, or contribute yet. |
| Users | External users, contributors, future maintainers, and the current maintainer returning later. |
| Outcome | Public entrypoints exist, strict docs build passes, metadata validation passes, and remaining failures are explicit. |
| Scope | First pass fixes P1 public hygiene and validation drift. |
| Constraints | Do not remove Claude compatibility; do not hand-bump release versions; preserve historical docs. |
| Existing Patterns | `AGENTS.md`, release scripts, MkDocs, feature integrity script, Codex sync contract. |
| Historical Lessons | Separate canonical, compatibility, and historical surfaces; do not treat `workflows:*` as current. |
| Alternatives | Minimal hygiene, full relaunch, rules only. |
| Risks | Over-large docs rewrite, release drift, failing tests hidden by partial checks. |
| Open Questions | Final maintainer security contact, public package naming, target support status matrix. |

## Candidate Priorities

| Priority | Candidate | Why now |
|---|---|---|
| P1 | Community health files | External users need a trusted intake path. |
| P1 | Security/support correction | Current security contact is upstream-oriented. |
| P1 | Docs strict build | Public docs must be deployable. |
| P1 | Release metadata drift | Release validation currently fails. |
| P2 | README public repositioning | Important but larger and should be planned separately. |
| P2 | CI hardening | Needed for long-term trust after current failures are understood. |

## Open Questions

- What exact private security contact should be published if GitHub private advisories are unavailable?
- Should the package continue to publish as `@jerry-jian/compound-plugin`, or should a clearer package/distribution story be created?
- Which target providers should be marked stable vs experimental after current tests are stabilized?

## Next Step

Proceed with Option A:

1. Add public community files and templates.
2. Fix `SECURITY.md`.
3. Fix MkDocs strict warnings.
4. Run release metadata sync and validate.
5. Run targeted validation and report remaining failures.
