---
name: brainstorming
description: This skill should be used before implementing features, building components, or making changes. It guides exploring user intent, approaches, and design decisions before planning. Triggers on "let's brainstorm", "help me think through", "what should we build", "explore approaches", ambiguous feature requests, or when the user's request has multiple valid interpretations that need clarification.
---

# Brainstorming

This skill provides detailed process knowledge for effective brainstorming sessions that clarify **WHAT** to build before diving into **HOW** to build it.

## When to Use This Skill

Brainstorming is valuable when:
- Requirements are unclear or ambiguous
- Multiple approaches could solve the problem
- Trade-offs need to be explored with the user
- The user hasn't fully articulated what they want
- The feature scope needs refinement

Brainstorming can be skipped when:
- Requirements are explicit and detailed
- The user knows exactly what they want
- The task is a straightforward bug fix or well-defined change

## Core Process

### Phase 0: Assess Requirement Clarity

Before diving into questions, assess whether brainstorming is needed.

**Signals that requirements are clear:**
- User provided specific acceptance criteria
- User referenced existing patterns to follow
- User described exact behavior expected
- Scope is constrained and well-defined

**Signals that brainstorming is needed:**
- User used vague terms ("make it better", "add something like")
- Multiple reasonable interpretations exist
- Trade-offs haven't been discussed
- User seems unsure about the approach

If requirements are clear, suggest: "Your requirements seem clear. Consider proceeding directly to planning or implementation."

### Phase 1: Understand the Idea

Ask questions **one at a time** to understand the user's intent. Avoid overwhelming with multiple questions.

## Questioning Techniques

Effective brainstorming relies on asking the right questions in the right way.

### 1. Multiple Choice Priority

When natural options exist, use AskUserQuestion to provide multiple choice.

**Good:**
```
Should the notification be:
(a) email only
(b) in-app only
(c) both email and in-app
```

**Avoid:**
```
How should users be notified?
```

**Why:** Multiple choice reduces cognitive load and surfaces options the user might not have considered.

### 2. Broad to Narrow

Start with purpose and users, gradually narrow to constraints and edge cases.

**Question Sequence:**
1. **Purpose:** What problem does this solve?
2. **Users:** Who will use this? What's their context?
3. **Constraints:** Any technical limitations? Timeline?
4. **Edge Cases:** What shouldn't happen? Error states?

**Why:** Starting narrow (e.g., "What color should the button be?") misses the bigger picture.

### 3. Explicit Assumption Validation

Don't hide assumptions—state them and let the user confirm or correct.

**Good:**
```
I'm assuming users will be logged in when they access this feature. Is that correct?
```

**Avoid:**
```
[Silently assuming authentication and building on that assumption]
```

**Why:** Hidden assumptions lead to misaligned designs that need rework.

### 4. Early Success Criteria

Ask "what counts as done" in the first round of questions.

**Good:**
```
How will you know this feature is working well? What's the success metric?
```

**Why:** Success criteria prevent scope creep and guide all subsequent decisions.

**Key Topics to Explore:**

| Topic | Example Questions |
|-------|-------------------|
| Purpose | What problem does this solve? What's the motivation? |
| Users | Who uses this? What's their context? |
| Constraints | Any technical limitations? Timeline? Dependencies? |
| Success | How will you measure success? What's the happy path? |
| Edge Cases | What shouldn't happen? Any error states to consider? |
| Existing Patterns | Are there similar features in the codebase to follow? |

**Exit Condition:** Continue until the idea is clear OR user says "proceed" or "let's move on"

### Phase 2: Explore Approaches

After understanding the idea, propose 2-3 concrete approaches.

**Structure for Each Approach:**

```markdown
### Approach A: [Name]

[2-3 sentence description]

**Pros:**
- [Benefit 1]
- [Benefit 2]

**Cons:**
- [Drawback 1]
- [Drawback 2]

**Best when:** [Circumstances where this approach shines]
```

**Guidelines:**
- Lead with a recommendation and explain why
- Be honest about trade-offs
- Consider YAGNI—simpler is usually better
- Reference codebase patterns when relevant

### Phase 3: Capture the Design

Summarize key decisions in a structured format.

**Design Doc Structure:**

```markdown
---
date: YYYY-MM-DD
topic: <kebab-case-topic>
---

# <Topic Title>

## What We're Building
[Concise description—1-2 paragraphs max]

## Why This Approach
[Brief explanation of approaches considered and why this one was chosen]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Any unresolved questions for the planning phase]

## Next Steps
→ `/workflows:plan` for implementation details
```

**Output Location:** `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

### Phase 4: Handoff

Present clear options for what to do next:

1. **Proceed to planning** → Run `/workflows:plan`
2. **Refine further** → Continue exploring the design
3. **Done for now** → User will return later

## YAGNI Principles

During brainstorming, actively resist complexity:

- **Don't design for hypothetical future requirements**
- **Choose the simplest approach that solves the stated problem**
- **Prefer boring, proven patterns over clever solutions**
- **Ask "Do we really need this?" when complexity emerges**
- **Defer decisions that don't need to be made now**

## Incremental Validation

Keep sections short—200-300 words maximum. After each section of output, pause to validate understanding:

- "Does this match what you had in mind?"
- "Any adjustments before we continue?"
- "Is this the direction you want to go?"

This prevents wasted effort on misaligned designs.

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach | Why It Matters |
|--------------|-----------------|----------------|
| Asking 5 questions at once | Ask one at a time, wait for answer | Overwhelming users leads to incomplete answers |
| Jumping to implementation details | Stay focused on WHAT, not HOW | Implementation is for planning phase, not brainstorming |
| Ignoring existing codebase patterns | Research repo first, then ask questions | Consistency with existing patterns reduces friction |
| Not validating assumptions | State assumptions explicitly and confirm | Hidden assumptions cause misaligned designs |
| Converging too early | Keep options open until user says "proceed" | Premature convergence misses better alternatives |
| Skipping success criteria | Ask "what counts as done" in first round | Without success criteria, scope creeps endlessly |
| Proposing overly complex solutions | Start simple, add complexity only if needed | YAGNI—complexity should be justified, not default |
| Creating lengthy design documents | Keep it concise—details go in the plan | Brainstorm captures decisions, not implementation |

## Integration with Planning

Brainstorming answers **WHAT** to build:
- Requirements and acceptance criteria
- Chosen approach and rationale
- Key decisions and trade-offs

Planning answers **HOW** to build it:
- Implementation steps and file changes
- Technical details and code patterns
- Testing strategy and verification

When brainstorm output exists, `/workflows:plan` should detect it and use it as input, skipping its own idea refinement phase.
