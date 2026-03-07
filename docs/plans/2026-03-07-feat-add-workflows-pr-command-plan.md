---
title: "feat: 添加 /workflows:pr 命令 - PR 创建与合并"
type: feat
date: 2026-03-07
risk_level: low
risk_score: 2
---

# feat: 添加 /workflows:pr 命令 - PR 创建与合并

## Overview

创建独立的 `/workflows:pr` 命令，用于在功能开发或代码审查完成后自动创建 PR 并询问是否合并到主分支。同时在 `/workflows:work` 和 `/workflows:review` 的 Handoff 中添加调用入口。

**Brainstorm 文档**：`docs/brainstorms/2026-03-07-workflow-pr-command-brainstorm.md`

## Acceptance Criteria

- [ ] `/workflows:pr` 命令可独立调用
- [ ] 自动检测主分支（main/master）
- [ ] 自动生成 PR 标题和描述
- [ ] 创建 PR 后询问是否合并
- [ ] work 和 review 的 Handoff 中可选择创建 PR
- [ ] ce:pr 别名可用
- [ ] 版本号、CHANGELOG、组件数量已更新

## Tasks

### Task 1: 创建 /workflows:pr 命令文件

**文件**: `plugins/compound-engineering/commands/workflows/pr.md`（新建）
**操作**:
- [x] 创建文件，写入完整命令内容

**代码**:
```markdown
---
name: workflows:pr
description: "独立工具: 创建 PR 并询问是否合并到主分支"
argument-hint: "[--draft] [--no-merge]"
---

# PR Creation & Merge Command

创建 Pull Request 并可选合并到主分支。可在 `/workflows:work` 或 `/workflows:review` 完成后自动触发，也可独立使用。

## Phase 1: Pre-flight Checks

### Step 1: 检测当前分支

```bash
current_branch=$(git branch --show-current)
```

如果 current_branch 为空（detached HEAD）：
→ 提示用户："当前处于 detached HEAD 状态，请先切换到功能分支。"
→ 终止流程

### Step 2: 检测主分支

```bash
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

if [ -z "$default_branch" ]; then
  default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
fi
```

### Step 3: 分支安全检查

```
如果 current_branch == default_branch：
  → 提示："当前在主分支 ($default_branch) 上，无法创建 PR。请先切换到功能分支。"
  → 终止流程
```

### Step 4: 检查未提交的更改

```bash
git status --porcelain
```

如果有未提交的更改：
→ 使用 **AskUserQuestion tool** 询问：

**Question:** "检测到未提交的更改。如何处理？"

**Options:**
1. **自动提交所有更改** - 使用自动生成的 commit message 提交
2. **仅创建 PR（忽略未提交更改）** - 只将已提交的内容纳入 PR
3. **取消** - 先手动处理更改再创建 PR

Based on selection:
- **自动提交** → 执行 `git add . && git commit -m "feat: [auto-generated message]"`
- **忽略** → 继续流程
- **取消** → 终止流程

### Step 5: 检查是否已有 PR

```bash
existing_pr=$(gh pr list --head "$current_branch" --json number,url --jq '.[0]')
```

如果已有 PR：
→ 使用 **AskUserQuestion tool** 询问：

**Question:** "当前分支已有 PR: $existing_pr_url。如何处理？"

**Options:**
1. **查看已有 PR** - 在浏览器中打开
2. **跳到合并步骤** - 直接询问是否合并已有 PR
3. **取消** - 终止流程

Based on selection:
- **查看** → `gh pr view --web`
- **合并** → 跳转到 Phase 3
- **取消** → 终止流程

## Phase 2: Create PR

### Step 1: 推送分支

```bash
# 检查远程分支是否存在
if ! git ls-remote --exit-code origin "$current_branch" >/dev/null 2>&1; then
  git push -u origin "$current_branch"
else
  git push
fi
```

### Step 2: 生成 PR 标题

```bash
# 从分支名生成标题
# feat/add-pr-command → feat: add pr command
# fix/login-bug → fix: login bug
pr_title=$(echo "$current_branch" | sed 's|/|: |; s|-| |g')

# 如果分支名不含 feat/fix 等前缀，使用第一个 commit 的标题
commit_title=$(git log "$default_branch".."$current_branch" --format="%s" --reverse | head -1)
```

选择更有意义的标题（优先使用 commit 摘要）。

### Step 3: 生成 PR 描述

```bash
# 获取所有 commit 列表
commits=$(git log "$default_branch".."$current_branch" --format="- %s" --reverse)

# 获取变更文件统计
diff_stat=$(git diff "$default_branch"..."$current_branch" --stat)
```

使用以上信息生成 PR 描述，格式：

```markdown
## Summary
[基于 commit 历史和 diff 自动生成的摘要]

## Changes
[commit 列表]

## Files Changed
[diff stat]

---

[![Compound Engineered](https://img.shields.io/badge/Compound-Engineered-6366f1)](https://github.com/EveryInc/compound-engineering-plugin) 🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Step 4: 创建 PR

```bash
gh pr create --title "$pr_title" --body "$pr_body" --base "$default_branch"
```

显示创建成功的 PR URL。

## Phase 3: Handoff（合并决策）

使用 **AskUserQuestion tool** 呈现选项：

**Question:** "PR 已创建: $pr_url。下一步？"

**Options:**
1. **立即合并到 $default_branch** - 使用 squash merge 合并并删除分支
2. **在浏览器中查看 PR** - 打开 GitHub PR 页面
3. **完成** - PR 已创建，不合并

Based on selection:
- **合并** → 执行合并流程（见下方）
- **查看** → `gh pr view --web`，然后再次询问是否合并
- **完成** → 结束流程

### 合并执行

```bash
# Squash merge：将所有 commit 压缩为一个，保持主分支整洁
gh pr merge --squash --delete-branch

# 切换回主分支并拉取最新
git checkout "$default_branch"
git pull
```

合并成功后显示：
```
PR 已合并到 $default_branch，功能分支已删除。
```
```

**验证**:
- [ ] 文件已创建在正确位置
- [ ] frontmatter 格式正确（name, description 有 "独立工具:" 前缀）
- [ ] 包含 3 个 Phase：Pre-flight → Create PR → Handoff
- [ ] Handoff 使用 AskUserQuestion + Based on selection

---

### Task 2: 创建 ce:pr 别名命令

**文件**: `plugins/compound-engineering/commands/ce/pr.md`（新建）
**操作**:
- [x] 创建别名转发文件

**代码**:
```markdown
---
name: ce:pr
description: "Alias for /workflows:pr — 创建 PR 并询问是否合并到主分支"
disable-model-invocation: true
---

/workflows:pr $ARGUMENTS
```

**验证**:
- [ ] 文件格式与其他 ce: 别名一致（如 `ce/review.md`）

---

### Task 3: 修改 work.md Handoff - 添加 PR 选项

**文件**: `plugins/compound-engineering/commands/workflows/work.md:528-567`
**操作**:
- [x] 在三个风险等级的 Handoff 中各添加一个 PR 选项

**修改内容**：

在 `Phase 5: Handoff（风险感知）` 的每个风险等级中添加 PR 选项：

**低风险 Handoff（约 533-541 行）**，在 Options 中添加：
```markdown
**Options:**
1. **运行 `/workflows:review`** - Claude 多代理代码审查
2. **创建 PR `/workflows:pr`** - 创建 Pull Request 并可选合并
3. **跳过审查，直接完成（推荐）** - 冒烟测试已通过，低风险可选
4. **记录解决方案 `/workflows:compound`** - 如有重要经验值得记录
5. **停止** - 完成
```

**中风险 Handoff（约 544-551 行）**，在 Options 中添加：
```markdown
**Options:**
1. **运行 `/workflows:review`（推荐）** - Claude 多代理代码审查
2. **创建 PR `/workflows:pr`** - 创建 Pull Request 并可选合并
3. **跳过审查，直接完成** - 如果你对代码有信心
4. **记录解决方案 `/workflows:compound`** - 如有重要经验值得记录
5. **停止** - 完成
```

**高风险 Handoff（约 554-561 行）**，在 Options 中添加：
```markdown
**Options:**
1. **运行 `/workflows:review [C]`（推荐）** - Claude + Codex 双重代码审查
2. **运行 `/workflows:review`** - 仅 Claude 代码审查
3. **创建 PR `/workflows:pr`** - 创建 Pull Request 并可选合并
4. **跳过审查** - 高风险不推荐跳过
5. **停止** - 完成
```

在 `Based on selection:` 中添加映射：
```markdown
- **`/workflows:pr`** → 调用 `/workflows:pr`
```

**验证**:
- [ ] 三个风险等级的 Handoff 中都有 PR 选项
- [ ] Based on selection 包含 `/workflows:pr` 映射
- [ ] Handoff 协议仍然合规（AskUserQuestion + 停止选项 + Based on selection）

---

### Task 4: 修改 review.md Handoff - 添加 PR 选项

**文件**: `plugins/compound-engineering/commands/workflows/review.md:505-519`
**操作**:
- [x] 在 Workflow Handoff 中添加 PR 选项

**修改内容**：

```markdown
**Question:** "代码审查流程完成。下一步？"

**Options:**
1. **记录解决方案** - 运行 `/workflows:compound` 记录本次解决的问题（推荐，如有非 trivial 修复）
2. **创建 PR `/workflows:pr`** - 创建 Pull Request 并可选合并
3. **保存上下文** - 运行 `/workflows:save` 保存项目状态
4. **完成** - 审查流程结束，无需额外操作
```

在 `Based on selection:` 中添加：
```markdown
- **`/workflows:pr`** → 调用 `/workflows:pr`
```

**验证**:
- [ ] PR 选项已添加到 Handoff
- [ ] Based on selection 包含映射

---

### Task 5: 更新 plugins/compound-engineering/CLAUDE.md 命令列表

**文件**: `plugins/compound-engineering/CLAUDE.md`
**操作**:
- [x] 在 Workflow 命令列表表格中添加 `/workflows:pr`
- [x] 在 ce: 别名列表中添加 `/ce:pr`

**修改位置**：Workflow 命令列表表格（约 `| 独立: |` 行之后）添加：

```markdown
| 独立:   | `/workflows:pr`        | PR 创建与合并   |
```

ce: 别名列表添加：
```
/ce:pr          → /workflows:pr
```

**验证**:
- [ ] 命令列表包含 `/workflows:pr`
- [ ] 别名列表包含 `/ce:pr`

---

### Task 6: 更新版本号和组件数量

**操作**:
- [x] 运行 `bump-version.ps1 -BumpType patch` 更新版本号
- [x] 更新 `marketplace.json` 和 `plugin.json` 中的 commands 数量（41 → 43）
- [x] 更新 `CLAUDE.md`（根目录）中的 commands 数量

**验证**:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

---

### Task 7: 更新 CHANGELOG.md

**文件**: `plugins/compound-engineering/CHANGELOG.md`
**操作**:
- [x] 在顶部添加新版本记录

**代码**:
```markdown
## [2.44.0] - 2026-03-07

**Summary**: Added `/workflows:pr` command for PR creation and merge workflow.

### Added
- `/workflows:pr` PR 创建与合并命令（自动检测主分支、生成 PR 标题描述、询问合并）
- `ce:pr` 别名转发命令

### Changed
- work.md: Handoff 添加 `/workflows:pr` 选项（三个风险等级均支持）
- review.md: Handoff 添加 `/workflows:pr` 选项

### Summary
- 29 agents, 43 commands, 24 skills, 1 MCP server
```

**验证**:
- [ ] 版本号格式正确
- [ ] 英文摘要 + 中文详情
- [ ] 组件数量已更新

---

### Task 8: 更新根目录 CLAUDE.md 命令列表和数量

**文件**: `CLAUDE.md`
**操作**:
- [x] 更新组件统计表中 Commands 数量（41 → 43）
- [x] 在"相关文档"或合适位置提及 `/workflows:pr`

**验证**:
- [ ] 数量一致

---

### Task 9: 最终验证

**操作**:
- [x] 运行版本检查脚本
- [x] 检查 Handoff 合规性
- [x] 确认所有新文件已创建

**验证命令**:
```bash
# 版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 检查新文件存在
ls plugins/compound-engineering/commands/workflows/pr.md
ls plugins/compound-engineering/commands/ce/pr.md

# 检查 workflow 命令 description 格式
grep "^description:" plugins/compound-engineering/commands/workflows/pr.md
```

## References

- Brainstorm: `docs/brainstorms/2026-03-07-workflow-pr-command-brainstorm.md`
- 现有独立工具命令模板: `commands/workflows/doctor.md`
- 现有 ce: 别名模板: `commands/ce/review.md`
- Handoff 协议规范: `plugins/compound-engineering/CLAUDE.md`
- 版本管理策略: `docs/zh-CN/VERSION-STRATEGY.md`
