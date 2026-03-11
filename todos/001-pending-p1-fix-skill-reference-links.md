---
status: pending
priority: p1
issue_id: "001"
tags: [documentation, skill-compliance, links]
dependencies: []
---

# 修复 finishing-a-feature 技能中的错误引用链接

## Problem Statement

`finishing-a-feature` 技能的关联技能部分包含 3 个错误的引用链接，指向不存在的文件或错误的路径。这违反了 Skill Compliance Checklist 中的引用链接规范，导致用户点击后遇到 404 错误，影响插件的专业性和可用性。

**影响范围：**
- 用户体验受损（点击链接失败）
- 违反插件开发规范（Skill Compliance Checklist）
- 降低文档可信度

## Findings

**来源：** kieran-rails-reviewer 和 pattern-recognition-specialist 审查

**位置：** `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md` 第 107-109 行

**具体问题：**

1. **第 107 行** - `worktree.md` 链接错误
   ```markdown
   - [`references/skills/worktree.md`](../../skills/worktree/SKILL.md)
   ```
   - 实际技能名称应为 `git-worktree`，而非 `worktree`
   - 正确路径应为 `../../skills/git-worktree/SKILL.md`

2. **第 108 行** - `review-pr.md` 技能不存在
   ```markdown
   - [`references/skills/review-pr.md`](../../skills/review-pr/SKILL.md)
   ```
   - 该技能在 skills 目录中不存在
   - 可能应该引用 `receiving-code-review` 技能

3. **第 109 行** - `workflows-work.md` 路径错误
   ```markdown
   - [`references/commands/workflows-work.md`](../../commands/workflows-work/COMMAND.md)
   ```
   - 正确路径应为 `../../commands/workflows/work.md`（workflows 是子目录）

**验证方法：**
```bash
# 检查技能目录
ls plugins/compound-engineering/skills/ | grep -E "(worktree|review-pr)"

# 检查 commands 目录结构
ls plugins/compound-engineering/commands/workflows/
```

## Proposed Solutions

### Option 1: 修复所有链接为正确路径

**Approach:** 逐一修正每个链接，确保指向实际存在的文件。

**具体修改：**
- 第 107 行：`worktree` → `git-worktree`
- 第 108 行：`review-pr` → `receiving-code-review`（或删除此行）
- 第 109 行：`workflows-work/COMMAND.md` → `workflows/work.md`

**Pros:**
- 完全符合 Skill Compliance Checklist
- 用户可以正常访问所有引用
- 维护文档完整性

**Cons:**
- 需要验证每个目标文件确实存在
- 如果 `receiving-code-review` 不是正确的替代，需要进一步调查

**Effort:** 15-20 分钟

**Risk:** Low

---

### Option 2: 删除不存在的引用，仅修复可修复的

**Approach:** 修复明确错误的链接（worktree、workflows-work），删除不存在的 review-pr 引用。

**具体修改：**
- 第 107 行：修复为 `git-worktree`
- 第 108 行：删除整行
- 第 109 行：修复为 `workflows/work.md`

**Pros:**
- 快速解决问题
- 避免引入不确定的替代链接
- 符合 YAGNI 原则

**Cons:**
- 减少了关联技能的数量
- 可能丢失有价值的引用信息

**Effort:** 10 分钟

**Risk:** Low

---

### Option 3: 添加验证脚本 + 修复当前问题

**Approach:** 修复当前问题的同时，创建自动化脚本检测所有技能的引用链接有效性。

**具体修改：**
- 修复 3 个链接（同 Option 1）
- 创建 `scripts/check-skill-links.sh` 验证脚本
- 添加到 pre-commit hook

**Pros:**
- 一次性解决当前和未来问题
- 提升整体代码质量
- 防止类似问题再次出现

**Cons:**
- 工作量较大
- 可能发现更多需要修复的链接

**Effort:** 30-40 分钟

**Risk:** Low

## Recommended Action

**待 triage 时填写**

## Technical Details

**受影响文件：**
- `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md:107-109`

**需要验证的目标文件：**
- `plugins/compound-engineering/skills/git-worktree/SKILL.md`（应存在）
- `plugins/compound-engineering/skills/receiving-code-review/SKILL.md`（需确认）
- `plugins/compound-engineering/commands/workflows/work.md`（应存在）

**相关规范：**
- Skill Compliance Checklist（`plugins/compound-engineering/CLAUDE.md`）
- Reference Links 规则：所有 references/assets/scripts 必须使用 markdown 链接

## Resources

- **Skill Compliance Checklist:** `plugins/compound-engineering/CLAUDE.md` 第 248-275 行
- **相关技能目录:** `plugins/compound-engineering/skills/`
- **相关命令目录:** `plugins/compound-engineering/commands/workflows/`

## Acceptance Criteria

- [ ] 所有引用链接指向实际存在的文件
- [ ] 链接格式符合 Skill Compliance Checklist
- [ ] 手动点击每个链接验证可访问
- [ ] 运行 `grep -E '\`(references|assets|scripts)/[^\`]+\`' skills/finishing-a-feature/SKILL.md` 返回空（无裸反引号引用）
- [ ] 更新 CHANGELOG.md 记录此修复

## Work Log

### 2026-03-11 - Initial Discovery

**By:** Claude Code (pattern-recognition-specialist + kieran-rails-reviewer)

**Actions:**
- 审查 `finishing-a-feature` 技能文档
- 识别 3 个错误的引用链接
- 验证目标文件不存在或路径错误
- 创建此 todo 文档

**Learnings:**
- 技能引用链接容易在重构时失效
- 需要自动化验证机制防止类似问题
- Skill Compliance Checklist 规则需要在开发时严格遵守

## Notes

- 此问题可能在其他技能中也存在，建议完成后进行全局检查
- 考虑将链接验证加入 CI/CD 流程
