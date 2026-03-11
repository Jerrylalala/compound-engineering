---
status: pending
priority: p1
issue_id: "002"
tags: [documentation, skill-compliance, frontmatter]
dependencies: []
---

# 修复 finishing-a-feature 技能的 Description 格式

## Problem Statement

`finishing-a-feature` 技能的 YAML frontmatter 中的 `description` 字段使用了第二人称（"Guides the user"），违反了 Skill Compliance Checklist 中的第三人称规范。

**规范要求：**
- 必须使用第三人称："This skill should be used when..."
- 禁止使用第二人称："Use this skill when..." 或 "Guides the user..."

**影响范围：**
- 违反插件开发规范
- 与其他技能的描述风格不一致
- 可能影响 AI 对技能使用场景的理解

## Findings

**来源：** kieran-rails-reviewer 和 pattern-recognition-specialist 审查

**位置：** `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md` 第 3 行

**当前内容：**
```yaml
description: Guides the user through completing a feature by verifying tests, presenting merge/PR options, and cleaning up worktrees
```

**问题分析：**
- 使用了 "Guides the user"（第二人称视角）
- 应改为 "This skill should be used when..."（第三人称客观描述）
- 缺少明确的触发场景说明（"Use when..."）

**验证方法：**
```bash
# 检查所有技能的 description 格式
grep -E '^description:' plugins/compound-engineering/skills/*/SKILL.md | grep -v 'This skill'
```

## Proposed Solutions

### Option 1: 改为标准第三人称格式（推荐）

**Approach:** 使用 "This skill should be used when..." 开头，明确说明使用场景。

**修改为：**
```yaml
description: This skill should be used when completing a feature to verify tests, present merge/PR options, and clean up worktrees
```

**Pros:**
- 完全符合 Skill Compliance Checklist
- 与其他技能描述风格一致
- 明确表达技能用途

**Cons:**
- 无

**Effort:** 2 分钟

**Risk:** Low

---

### Option 2: 使用被动语态 + 场景描述

**Approach:** 使用被动语态描述技能功能，同时添加 "Use when..." 部分。

**修改为：**
```yaml
description: This skill should be used when a feature is complete and needs verification, merge/PR creation, and worktree cleanup
```

**Pros:**
- 符合第三人称规范
- 更强调使用场景而非操作步骤
- 提升 AI 可发现性

**Cons:**
- 描述稍长

**Effort:** 3 分钟

**Risk:** Low

---

### Option 3: 添加触发关键词 + 重写描述

**Approach:** 在描述中明确添加触发关键词，帮助 AI 判断使用场景。

**修改为：**
```yaml
description: This skill should be used when finishing or completing a feature. It verifies tests pass, presents merge/PR options, and handles worktree cleanup
```

**Pros:**
- 包含触发关键词（"finishing", "completing"）
- 符合第三人称规范
- 提升 AI 自动调用准确性

**Cons:**
- 描述较长

**Effort:** 5 分钟

**Risk:** Low

## Recommended Action

**待 triage 时填写**

## Technical Details

**受影响文件：**
- `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md:3`

**YAML frontmatter 位置：**
```yaml
---
name: finishing-a-feature
description: [需要修改的行]
disable-model-invocation: true
---
```

**相关规范：**
- Skill Compliance Checklist（`plugins/compound-engineering/CLAUDE.md`）
- YAML Frontmatter 规则：description 必须使用第三人称

**参考示例（其他技能的正确格式）：**
```bash
# 查看其他技能的 description 格式
grep -A1 '^description:' plugins/compound-engineering/skills/systematic-debugging/SKILL.md
grep -A1 '^description:' plugins/compound-engineering/skills/test-driven-development/SKILL.md
```

## Resources

- **Skill Compliance Checklist:** `plugins/compound-engineering/CLAUDE.md` 第 248-275 行
- **Skill Creator Spec:** 插件开发规范文档
- **相关 Issue:** #001（修复引用链接，可一并处理）

## Acceptance Criteria

- [ ] description 使用第三人称格式（"This skill should be used when..."）
- [ ] 包含明确的使用场景说明
- [ ] 运行验证命令无报错：`grep -E '^description:' skills/finishing-a-feature/SKILL.md | grep -v 'This skill'` 返回空
- [ ] 与其他技能的描述风格一致
- [ ] 更新 CHANGELOG.md 记录此修复

## Work Log

### 2026-03-11 - Initial Discovery

**By:** Claude Code (pattern-recognition-specialist + kieran-rails-reviewer)

**Actions:**
- 审查 `finishing-a-feature` 技能的 YAML frontmatter
- 识别 description 格式不符合规范
- 对比其他技能的正确格式
- 创建此 todo 文档

**Learnings:**
- Skill Compliance Checklist 中的 description 规则容易被忽略
- 需要在技能创建时使用模板确保格式正确
- 可以通过自动化脚本检测格式问题

## Notes

- 此问题可能在其他技能中也存在，建议完成后进行全局检查
- 考虑创建技能模板或 linter 自动检测格式问题
- 与 #001 可以在同一个 commit 中修复
