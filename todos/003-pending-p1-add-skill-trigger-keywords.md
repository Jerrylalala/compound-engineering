---
status: pending
priority: p1
issue_id: "003"
tags: [documentation, skill-compliance, discoverability]
dependencies: ["002"]
---

# 为 finishing-a-feature 技能添加触发关键词

## Problem Statement

`finishing-a-feature` 技能的 description 缺少明确的触发关键词和 "Use when..." 部分，导致 AI 难以判断何时应该使用此技能。这降低了技能的可发现性，可能导致用户在完成功能时无法获得自动化的流程指导。

**影响范围：**
- AI 无法准确判断使用场景
- 降低技能的自动调用率
- 用户需要手动查找和调用技能
- 违反技能设计最佳实践

## Findings

**来源：** kieran-rails-reviewer 和 pattern-recognition-specialist 审查

**位置：** `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md` 第 3 行

**当前问题：**
1. Description 中没有 "Use when..." 或 "This skill should be used when..." 明确说明
2. 缺少触发关键词（如 "finishing", "completing", "done", "merge", "PR"）
3. AI 难以从用户输入中识别应该调用此技能

**对比其他技能：**
```bash
# 查看其他技能如何描述使用场景
grep -A2 '^description:' plugins/compound-engineering/skills/systematic-debugging/SKILL.md
grep -A2 '^description:' plugins/compound-engineering/skills/test-driven-development/SKILL.md
```

**用户可能的输入示例（应触发此技能）：**
- "功能开发完成了，接下来怎么办？"
- "我想合并这个分支"
- "准备创建 PR"
- "测试都通过了，如何收尾？"
- "完成了功能，需要清理 worktree"

## Proposed Solutions

### Option 1: 在 description 中添加触发关键词（推荐）

**Approach:** 重写 description，明确包含触发场景和关键词。

**修改为：**
```yaml
description: This skill should be used when finishing or completing a feature. Use when tests pass and you need to merge, create a PR, or clean up worktrees. Triggered by keywords like "done", "complete", "merge", "PR", "finish"
```

**Pros:**
- 明确说明使用场景
- 包含多个触发关键词
- 提升 AI 自动调用准确性
- 用户体验更好

**Cons:**
- Description 较长（但仍在合理范围内）

**Effort:** 5 分钟

**Risk:** Low

---

### Option 2: 在技能文档中添加 "When to Use" 部分

**Approach:** 保持 description 简洁，在技能文档正文中添加详细的使用场景说明。

**在 SKILL.md 中添加：**
```markdown
## When to Use This Skill

Use this skill when:
- Feature development is complete and tests pass
- Ready to merge changes to main branch
- Need to create a Pull Request for review
- Working in a worktree and need cleanup
- Unsure about merge vs PR workflow

**Trigger keywords:** finishing, completing, done, merge, PR, pull request, cleanup, worktree
```

**Pros:**
- Description 保持简洁
- 详细说明在文档中更易维护
- 可以添加更多上下文和示例

**Cons:**
- AI 可能不会读取文档正文（主要依赖 description）
- 触发准确性可能不如 Option 1

**Effort:** 10 分钟

**Risk:** Medium

---

### Option 3: 同时优化 description 和文档（最佳实践）

**Approach:** 结合 Option 1 和 Option 2，在 description 中添加核心触发词，在文档中添加详细说明。

**Description 修改：**
```yaml
description: This skill should be used when finishing or completing a feature to verify tests, present merge/PR options, and clean up worktrees
```

**文档中添加：**
```markdown
## When to Use This Skill

This skill is automatically triggered when you mention:
- "Feature is done/complete/finished"
- "Ready to merge"
- "Create a PR/pull request"
- "Clean up worktree"
- "What's next after development?"

Use this skill to ensure proper completion workflow including test verification, merge strategy selection, and cleanup.
```

**Pros:**
- 最佳用户体验
- AI 和人类都能清晰理解使用场景
- 符合技能设计最佳实践
- 提升可发现性和可维护性

**Cons:**
- 工作量稍大

**Effort:** 15 分钟

**Risk:** Low

## Recommended Action

**待 triage 时填写**

## Technical Details

**受影响文件：**
- `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md:3`（description）
- `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md:8-10`（可添加 "When to Use" 部分）

**依赖关系：**
- 依赖 #002（修复 description 格式）
- 应在 #002 完成后进行，避免重复修改同一行

**触发关键词建议：**
- 核心词：finishing, completing, done, complete, finish
- 操作词：merge, PR, pull request, push
- 清理词：cleanup, worktree, remove
- 询问词：what's next, how to finish, ready to merge

**参考其他技能的触发词设计：**
```bash
# 查看其他技能如何设计触发场景
grep -B2 -A5 'When to Use' plugins/compound-engineering/skills/*/SKILL.md
```

## Resources

- **Skill Compliance Checklist:** `plugins/compound-engineering/CLAUDE.md` 第 248-275 行
- **技能检查协议:** `plugins/compound-engineering/CLAUDE.md` 第 1-50 行
- **相关 Issue:** #002（修复 description 格式，必须先完成）

## Acceptance Criteria

- [ ] Description 包含明确的使用场景说明
- [ ] 包含至少 3-5 个触发关键词
- [ ] 文档中添加 "When to Use This Skill" 部分（如选择 Option 2 或 3）
- [ ] 手动测试：使用触发关键词询问 AI，验证技能被正确调用
- [ ] 与其他技能的触发词设计风格一致
- [ ] 更新 CHANGELOG.md 记录此改进

## Work Log

### 2026-03-11 - Initial Discovery

**By:** Claude Code (pattern-recognition-specialist + kieran-rails-reviewer)

**Actions:**
- 审查 `finishing-a-feature` 技能的可发现性
- 识别缺少触发关键词和使用场景说明
- 分析用户可能的输入场景
- 对比其他技能的触发词设计
- 创建此 todo 文档

**Learnings:**
- 技能的可发现性依赖于清晰的触发词设计
- Description 是 AI 判断使用场景的主要依据
- 文档中的详细说明可以帮助用户理解何时使用技能
- 触发词应覆盖用户的自然语言表达方式

## Notes

- 此问题依赖 #002 的完成（避免重复修改同一行）
- 建议在 triage 时与 #001、#002 一起评估，可能可以在同一个 PR 中完成
- 完成后可以创建技能可发现性检查清单，应用到其他技能
- 考虑在插件文档中添加"如何设计触发词"的最佳实践指南
