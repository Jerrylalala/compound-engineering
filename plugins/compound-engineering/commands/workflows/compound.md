---
name: workflows:compound
description: "Step 5: 记录已解决的问题，积累团队知识"
argument-hint: "[optional: brief context about the fix]"
---

# /compound

Coordinate multiple subagents working in parallel to document a recently solved problem.

## Purpose

Captures problem solutions while context is fresh, creating structured documentation in `docs/solutions/` with YAML frontmatter for searchability and future reference. Uses parallel subagents for maximum efficiency.

**Why "compound"?** Each documented solution compounds your team's knowledge. The first time you solve a problem takes research. Document it, and the next occurrence takes minutes. Knowledge compounds.

## Usage

```bash
/workflows:compound                    # Document the most recent fix
/workflows:compound [brief context]    # Provide additional context hint
```

## Execution Strategy: Parallel Subagents

This command launches multiple specialized subagents IN PARALLEL to maximize efficiency:

### 0. **Location Classifier** (First, Required)

> **规则来源**：遵循 `~/.claude/CLAUDE.md` 中的「经验分类规则（SSOT）」，此处不重复定义。

**执行步骤：**

1. 分析问题特征，使用全局 CLAUDE.md 的判定决策树：
   - Q1: 涉及 Claude Code/API？ → 全局 + 项目备份
   - Q2: 通用开发工具问题？ → 仅全局
   - Q3: 可复用的设计模式/规范？ → 仅全局
   - Q4: 只与当前项目相关？ → 仅项目

2. 确定写入位置和文件路径

3. 返回结构化结果

**返回值（JSON）：**
```json
{
  "scope": "global" | "project",
  "primary_location": "~/.claude/solutions/..." | "docs/solutions/...",
  "backup_location": "docs/solutions/...",  // 仅当 scope=global 时存在
  "category": "integration-issues",          // 问题分类
  "reasoning": "问题涉及 Claude Code 插件..."  // 判定理由
}
```

**示例：**
- 「Marketplace 缓存问题」→ `{ scope: "global", primary: "~/.claude/solutions/marketplace-cache.md", backup: "docs/solutions/integration-issues/..." }`
- 「项目 N+1 查询」→ `{ scope: "project", primary: "docs/solutions/performance-issues/..." }`

### 1. **Context Analyzer** (Parallel)
   - Extracts conversation history
   - Identifies problem type, component, symptoms
   - Validates against solution schema
   - Returns: YAML frontmatter skeleton

### 2. **Solution Extractor** (Parallel)
   - Analyzes all investigation steps
   - Identifies root cause
   - Extracts working solution with code examples
   - Returns: Solution content block

### 3. **Related Docs Finder** (Parallel)
   - Searches `docs/solutions/` for related documentation
   - Identifies cross-references and links
   - Finds related GitHub issues
   - Returns: Links and relationships

### 4. **Prevention Strategist** (Parallel)
   - Develops prevention strategies
   - Creates best practices guidance
   - Generates test cases if applicable
   - Returns: Prevention/testing content

### 5. **Category Classifier** (Parallel)
   - Determines optimal `docs/solutions/` category
   - Validates category against schema
   - Suggests filename based on slug
   - Returns: Final path and filename

### 6. **Documentation Writer** (Parallel)
   - Assembles complete markdown file
   - Validates YAML frontmatter
   - Formats content for readability
   - Creates the file in correct location

### 7. **Optional: Specialized Agent Invocation** (Post-Documentation)
   Based on problem type detected, automatically invoke applicable agents:
   - **performance_issue** → `performance-oracle`
   - **security_issue** → `security-sentinel`
   - **database_issue** → `data-integrity-guardian`
   - Any code-heavy issue → `kieran-rails-reviewer` + `code-simplicity-reviewer`

## What It Captures

- **Problem symptom**: Exact error messages, observable behavior
- **Investigation steps tried**: What didn't work and why
- **Root cause analysis**: Technical explanation
- **Working solution**: Step-by-step fix with code examples
- **Prevention strategies**: How to avoid in future
- **Cross-references**: Links to related issues and docs

## Preconditions

<preconditions enforcement="advisory">
  <check condition="problem_solved">
    Problem has been solved (not in-progress)
  </check>
  <check condition="solution_verified">
    Solution has been verified working
  </check>
  <check condition="non_trivial">
    Non-trivial problem (not simple typo or obvious error)
  </check>
</preconditions>

## What It Creates

> **位置判断规则**：参见 `~/.claude/CLAUDE.md` 的「经验分类规则（SSOT）」

**文档位置：**
- 全局经验 → `~/.claude/solutions/[filename].md` + 项目备份
- 项目经验 → `docs/solutions/[category]/[filename].md`

**项目内分类：**

- File: `docs/solutions/[category]/[filename].md`

**Categories auto-detected from problem:**

- build-errors/
- test-failures/
- runtime-errors/
- performance-issues/
- database-issues/
- security-issues/
- ui-bugs/
- integration-issues/
- logic-errors/

## Success Output

```
✓ Parallel documentation generation complete

Primary Subagent Results:
  ✓ Context Analyzer: Identified performance_issue in brief_system
  ✓ Solution Extractor: Extracted 3 code fixes
  ✓ Related Docs Finder: Found 2 related issues
  ✓ Prevention Strategist: Generated test cases
  ✓ Category Classifier: docs/solutions/performance-issues/
  ✓ Documentation Writer: Created complete markdown

Specialized Agent Reviews (Auto-Triggered):
  ✓ performance-oracle: Validated query optimization approach
  ✓ kieran-rails-reviewer: Code examples meet Rails standards
  ✓ code-simplicity-reviewer: Solution is appropriately minimal
  ✓ every-style-editor: Documentation style verified

File created:
- docs/solutions/performance-issues/n-plus-one-brief-generation.md

This documentation will be searchable for future reference when similar
issues occur in the Email Processing or Brief System modules.

What's next?
1. Continue workflow (recommended)
2. Link related documentation
3. Update CHANGELOG.md (if this was a feature/fix)
4. Update CLAUDE.md Key Learnings (if important lesson)
5. View documentation
6. Other
```

## The Compounding Philosophy

This creates a compounding knowledge system:

1. First time you solve "N+1 query in brief generation" → Research (30 min)
2. Document the solution → docs/solutions/performance-issues/n-plus-one-briefs.md (5 min)
3. Next time similar issue occurs → Quick lookup (2 min)
4. Knowledge compounds → Team gets smarter

The feedback loop:

```
Build → Test → Find Issue → Research → Improve → Document → Validate → Deploy
    ↑                                                                      ↓
    └──────────────────────────────────────────────────────────────────────┘
```

**Each unit of engineering work should make subsequent units of work easier—not harder.**

## Auto-Invoke

<auto_invoke> <trigger_phrases> - "that worked" - "it's fixed" - "working now" - "problem solved" </trigger_phrases>

<manual_override> Use /workflows:compound [context] to document immediately without waiting for auto-detection. </manual_override> </auto_invoke>

## Routes To

`compound-docs` skill

## Applicable Specialized Agents

Based on problem type, these agents can enhance documentation:

### Code Quality & Review
- **kieran-rails-reviewer**: Reviews code examples for Rails best practices
- **code-simplicity-reviewer**: Ensures solution code is minimal and clear
- **pattern-recognition-specialist**: Identifies anti-patterns or repeating issues

### Specific Domain Experts
- **performance-oracle**: Analyzes performance_issue category solutions
- **security-sentinel**: Reviews security_issue solutions for vulnerabilities
- **data-integrity-guardian**: Reviews database_issue migrations and queries

### Enhancement & Documentation
- **best-practices-researcher**: Enriches solution with industry best practices
- **every-style-editor**: Reviews documentation style and clarity
- **framework-docs-researcher**: Links to Rails/gem documentation references

### When to Invoke
- **Auto-triggered** (optional): Agents can run post-documentation for enhancement
- **Manual trigger**: User can invoke agents after /workflows:compound completes for deeper review

## Related Commands

- `/research [topic]` - Deep investigation (searches docs/solutions/ for patterns)
- `/workflows:plan` - Planning workflow (references documented solutions)

