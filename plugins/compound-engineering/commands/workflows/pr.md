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
