# Requirements Capture

This content is loaded when Phase 3 begins — after the collaborative dialogue (Phases 0-2) has produced durable decisions worth preserving.

---

This document should behave like a lightweight PRD without PRD ceremony. Include what planning needs to execute well, and skip sections that add no value for the scope.

The requirements document is for product definition and scope control. Do **not** include implementation details such as libraries, schemas, endpoints, file layouts, or code structure unless the brainstorm is inherently technical and those details are themselves the subject of the decision.

**Required content for non-trivial work:**
- Problem frame
- Concrete requirements or intended behavior with stable IDs
- Scope boundaries
- Success criteria

**Include when materially useful:**
- Key decisions and rationale
- Dependencies or assumptions
- Outstanding questions
- Alternatives considered
- High-level technical direction only when the work is inherently technical and the direction is part of the product/architecture decision

**Document structure:** Use this template and omit clearly inapplicable optional sections:

```markdown
---
date: YYYY-MM-DD
topic: <kebab-case-topic>
---

# <Topic Title>

## Problem Frame
[Who is affected, what is changing, and why it matters]

## Requirements

### P1 — Must Have
- R1. [Core requirement without which the brainstorm does not solve the problem]
- R2. [Core behavior or scope promise that planning must preserve]

### P2 — Should Have
- R3. [Important requirement included by default, but adjustable if scope pressure appears]

### P3 — Could Have
- R4. [Low-cost enhancement that improves usefulness but does not block the core path]

### P4 — Later / Parking Lot
- R5. [Valuable follow-up explicitly deferred from the current scope]

## Reuse / Build Boundary
- Existing capabilities to reuse: [libraries, tools, CLIs, APIs, services, or project patterns]
- Glue code we expect to write: [orchestration, configuration, adaptation, and input/output connection]
- Net-new behavior: [custom behavior that must be built because no mature capability fits]
- Explicit non-goals: [things we will not reimplement]

## Success Criteria
- [How we will know this solved the right problem]

## Scope Boundaries
- [Deliberate non-goal or exclusion]

## Key Decisions
- [Decision]: [Rationale]

## Dependencies / Assumptions
- [Only include if material]

## Outstanding Questions

### Resolve Before Planning
- [Affects R1][User decision] [Question that must be answered before planning can proceed]

### Deferred to Planning
- [Affects R2][Technical] [Question that should be answered during planning or codebase exploration]
- [Affects R2][Needs research] [Question that likely requires research during planning]

## Next Steps
[If `Resolve Before Planning` is empty: `-> /ce:plan` for structured implementation planning]
[If `Resolve Before Planning` is not empty: `-> Resume /ce:brainstorm` to resolve blocking questions before planning]
```

**Visual communication** — Include a visual aid when the requirements would be significantly easier to understand with one. Read `references/visual-communication.md` for the decision criteria, format selection, and placement rules.

For **Standard** and **Deep** brainstorms, a requirements document is usually warranted.

For **Lightweight** brainstorms, keep the document compact. Skip document creation when the user only needs brief alignment and no durable decisions need to be preserved.

For very small requirements docs with only 1-3 simple requirements, plain bullet requirements are acceptable. For **Standard** and **Deep** requirements docs, use stable IDs like `R1`, `R2`, `R3` so planning and later review can refer to them unambiguously.

For **Standard** and **Deep** requirements docs, group requirements by priority first: `P1 — Must Have`, `P2 — Should Have`, `P3 — Could Have`, and `P4 — Later / Parking Lot`. Keep stable requirement IDs (`R1`, `R2`, `R3`) inside those priority groups; P-levels express delivery priority, while R-levels provide durable references for planning and review. Omit empty priority groups only when they would add noise.

Priority definitions:
- `P1 — Must Have`: without this, the brainstorm does not solve the core problem or planning cannot proceed coherently.
- `P2 — Should Have`: important for completeness, reliability, or user experience; included by default but adjustable under scope pressure.
- `P3 — Could Have`: useful low-cost enhancement that should not block the main path.
- `P4 — Later / Parking Lot`: valuable idea explicitly deferred to prevent scope creep.

Always include `Reuse / Build Boundary` for software work. State what mature capability should be reused, what glue code is expected, what net-new behavior remains, and what the team should not reimplement. For non-software work, omit this section unless an analogous reuse boundary is useful.

When requirements span multiple distinct concerns, group them under bold topic headers within the Requirements section. The trigger for grouping is distinct logical areas, not item count — even four requirements benefit from headers if they cover three different topics. Group by logical theme (e.g., "Packaging", "Migration and Compatibility", "Contributor Workflow"), not by the order they were discussed. Requirements keep their original stable IDs — numbering does not restart per group. A requirement belongs to whichever group it fits best; do not duplicate it across groups. Skip grouping only when all requirements are about the same thing.

When the work is simple, combine sections rather than padding them. A short requirements document is better than a bloated one.

Before finalizing, check:
- What would `ce:plan` still have to invent if this brainstorm ended now?
- Do any requirements depend on something claimed to be out of scope?
- Are any unresolved items actually product decisions rather than planning questions?
- Did implementation details leak in when they shouldn't have?
- Do any requirements claim that infrastructure is absent without that claim having been verified against the codebase? If so, verify now or label as an unverified assumption.
- Are P1/P2/P3/P4 priority assignments clear enough that `ce:plan` knows what must ship first and what is explicitly deferred?
- Does `Reuse / Build Boundary` identify mature capabilities to reuse and keep custom work limited to glue code where possible?
- Would a visual aid (flow diagram, comparison table, relationship diagram) help a reader grasp the requirements faster than prose alone?

If planning would need to invent product behavior, scope boundaries, or success criteria, the brainstorm is not complete yet.

Ensure `docs/brainstorms/` directory exists before writing.

If a document contains outstanding questions:
- Use `Resolve Before Planning` only for questions that truly block planning
- If `Resolve Before Planning` is non-empty, keep working those questions during the brainstorm by default
- If the user explicitly wants to proceed anyway, convert each remaining item into an explicit decision, assumption, or `Deferred to Planning` question before proceeding
- Do not force resolution of technical questions during brainstorming just to remove uncertainty
- Put technical questions, or questions that require validation or research, under `Deferred to Planning` when they are better answered there
- Use tags like `[Needs research]` when the planner should likely investigate the question rather than answer it from repo context alone
- Carry deferred questions forward explicitly rather than treating them as a failure to finish the requirements doc
