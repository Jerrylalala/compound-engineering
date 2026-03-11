---
name: receiving-code-review
description: This skill should be used when receiving code review feedback from humans or external reviewers (Codex/Gemini). It provides a structured 6-step response pattern to process feedback constructively and avoid defensive reactions.
disable-model-invocation: true
---

# Receiving Code Review

This skill provides a structured approach to receiving and processing code review feedback constructively.

## When to Use This Skill

**Trigger scenarios:**
- After `/workflows:review` completes and reviewer provides feedback
- When receiving feedback from external reviewers (Codex/Gemini via `[C]` or `[G]` flags)
- When user provides direct code review comments
- When CI/CD checks fail and require addressing feedback

**Core principle:** Treat all feedback as valuable signal, not personal criticism.

## 6-Step Response Pattern

### Step 1: Acknowledge Receipt

Confirm you've received the feedback without immediately defending or explaining.

**Template:**
```
收到反馈，我会逐条处理。
```

**What NOT to say:**
- "但是我这样做是因为..." (defensive)
- "这个不是问题，因为..." (dismissive)
- "我觉得这样更好..." (argumentative)

### Step 2: Categorize Feedback

Group feedback into actionable categories:

| Category | Description | Action |
|----------|-------------|--------|
| **Must Fix** | Bugs, security issues, spec violations | Immediate fix |
| **Should Fix** | Code quality, maintainability | Fix unless strong reason |
| **Consider** | Suggestions, alternative approaches | Evaluate trade-offs |
| **Clarify** | Unclear feedback | Ask questions |

**Output format:**
```markdown
## 反馈分类

### Must Fix
- [ ] [Issue description]

### Should Fix
- [ ] [Issue description]

### Consider
- [ ] [Suggestion description]

### Clarify
- [ ] [Question about feedback]
```

### Step 3: Ask Clarifying Questions

For unclear feedback, ask specific questions before implementing changes.

**Good questions:**
- "你是指 [specific code location] 的 [specific behavior] 吗？"
- "这个问题在 [scenario] 下会出现吗？"
- "你建议的替代方案是 [specific approach] 吗？"

**Bad questions:**
- "为什么这样不行？" (defensive)
- "有什么问题吗？" (too vague)

### Step 4: Implement Changes

Address feedback in priority order: Must Fix → Should Fix → Consider.

**For each change:**
1. State what you're fixing
2. Show the specific change (diff or code snippet)
3. Explain why this addresses the feedback

**Template:**
```markdown
### 修复：[Issue description]

**原因**: [Why this was flagged]

**修改**:
```diff
- old code
+ new code
```

**验证**: [How to verify the fix]
```

### Step 5: Document Decisions

For feedback you're NOT implementing, document why.

**Valid reasons:**
- Conflicts with spec requirements
- Performance/security trade-offs
- Out of scope for current task
- Requires architectural changes beyond current PR

**Template:**
```markdown
### 未实施：[Feedback item]

**原因**: [Specific reason]
**替代方案**: [If applicable]
**后续跟进**: [If needs separate task]
```

**Invalid reasons:**
- "我觉得现在的方式更好" (opinion without evidence)
- "这个不重要" (dismissive)
- "太复杂了" (without exploring alternatives)

### Step 6: Request Re-Review

After implementing changes, explicitly request re-review.

**Template:**
```
已完成以下修改：
- [Change 1]
- [Change 2]

未实施的反馈及原因：
- [Feedback item]: [Reason]

请重新审查。
```

## Handling Unclear Feedback

When feedback is vague or contradictory:

1. **Restate your understanding**: "我理解你的意思是 [interpretation]，对吗？"
2. **Provide options**: "我可以 [option A] 或 [option B]，你更倾向哪个？"
3. **Ask for examples**: "能否提供一个具体的例子？"

**Never:**
- Guess what the reviewer meant and implement without confirmation
- Ignore unclear feedback
- Implement multiple interpretations hoping one is right

## When to Push Back

Push back is appropriate when feedback:

1. **Contradicts spec**: "规格文档第 X 节要求 [behavior]，这个反馈会违反规格。"
2. **Introduces bugs**: "这个修改会导致 [specific failure]，测试 [test name] 会失败。"
3. **Breaks existing functionality**: "这会影响 [existing feature]，需要更大范围的重构。"

**Push back template:**
```markdown
### 关于 [feedback item] 的疑问

**反馈**: [Original feedback]
**问题**: [Specific concern]
**证据**: [Test failure / spec reference / code example]
**建议**: [Alternative approach or clarification needed]
```

**Never push back because:**
- "我不同意" (opinion)
- "这样写更简洁" (style preference without justification)
- "现在的代码能跑" (working ≠ correct)

## YAGNI Check

Before implementing suggested features or abstractions, apply YAGNI:

**Questions to ask:**
- Is this needed for the current task?
- Is there a concrete use case right now?
- Can we add this later without significant refactoring?

**If answer is "no" to first two questions:**
```markdown
### 建议延后：[Feature/abstraction]

**原因**: 当前任务不需要此功能
**何时添加**: 当出现 [specific use case] 时
**记录位置**: [Link to issue/doc for future reference]
```

## Implementation Order

Process feedback in this order:

1. **Security issues** - Immediate fix
2. **Bugs** - Fix before any other changes
3. **Spec violations** - Align with requirements
4. **Code quality** - Readability, maintainability
5. **Suggestions** - Evaluate and implement if valuable

**Rationale:** Fix critical issues first to avoid building on broken foundation.

## External Review Integration

When using `/workflows:review [C]` or `[G]`:

### Codex Review
- Codex results appear in current session
- Treat as additional reviewer perspective
- Cross-reference with Claude review findings

### Gemini Review
- Gemini results appear in current session
- May highlight different concerns than Claude
- Prioritize issues flagged by multiple reviewers

### Dual Review `[C][G]`
- Both Codex and Gemini provide feedback
- Issues found by both reviewers are highest priority
- Unique findings from each still valuable

**Processing multi-reviewer feedback:**

1. **Identify consensus issues** - All reviewers agree → Must Fix
2. **Identify unique issues** - Only one reviewer flagged → Evaluate carefully
3. **Resolve conflicts** - Reviewers disagree → Ask for clarification

## Related Skills

- `spec-compliance-review` - Use before requesting review to catch issues early
- `systematic-debugging` - Use when feedback reveals bugs
- `test-driven-development` - Use to verify fixes address feedback
- `document-review` - Use for reviewing plan/brainstorm documents

## Anti-Patterns

| ❌ Anti-Pattern | ✅ Correct Approach |
|----------------|-------------------|
| Implement all feedback immediately | Categorize and prioritize first |
| Defend current implementation | Ask clarifying questions |
| Ignore feedback you disagree with | Document decision with reasoning |
| Make changes without understanding | Clarify feedback before implementing |
| Add features "while we're here" | Apply YAGNI, stay focused on feedback |
| Assume reviewer is wrong | Assume feedback has valid concern, investigate |

## Completion Criteria

Review response is complete when:

- [ ] All feedback categorized (Must/Should/Consider/Clarify)
- [ ] Clarifying questions asked and answered
- [ ] Must Fix items implemented and verified
- [ ] Should Fix items implemented or documented why not
- [ ] Consider items evaluated with decision documented
- [ ] Changes verified with tests/validation
- [ ] Re-review requested with summary of changes
