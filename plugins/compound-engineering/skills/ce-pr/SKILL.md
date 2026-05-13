---
name: ce:pr
description: "创建 PR 并询问是否合并到主分支"
argument-hint: "[--draft=草稿PR] [--no-merge=仅创建不合并]"
---

# PR Creation & Merge Command

创建 Pull Request 并可选合并到主分支。可在 `/ce:work` 或 `/ce:review` 完成后自动触发，也可独立使用。

## 参数解析

开始时解析用户参数：

- `--draft`：创建 draft PR
- `--no-merge`：创建或定位 PR 后直接结束，不进入合并询问

移除已识别参数后，其余内容可作为 PR 标题/描述的额外上下文。

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
git symbolic-ref refs/remotes/origin/HEAD
```

如果输出形如 `refs/remotes/origin/main`，去掉 `refs/remotes/origin/` 前缀作为 `default_branch`。

如果命令失败或输出为空，执行：

```bash
git rev-parse --verify origin/main
```

如果命令成功，使用 `main` 作为 `default_branch`；如果失败，使用 `master`。

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
- **自动提交** → 读取 `git status --porcelain`，按相关变更列出具体文件，使用 `git add <file...>` 暂存确认后的文件，再执行 `git commit -m "feat: [auto-generated message]"`
- **忽略** → 继续流程
- **取消** → 终止流程

### Step 5: 检查是否已有 PR

```bash
existing_pr=$(gh pr list --head "$current_branch" --json number,url --jq '.[0]')
```

如果已有 PR：
→ 如果 `--no-merge` 参数存在，显示已有 PR URL 后结束流程。
→ 否则使用 **AskUserQuestion tool** 询问：

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

### Step 1: 检查远端分支

```bash
git ls-remote --exit-code origin "$current_branch"
```

如果命令失败，执行：

```bash
git push -u origin "$current_branch"
```

如果命令成功，执行：

```bash
git push
```

### Step 2: 生成 PR 标题

```bash
pr_title=$(echo "$current_branch" | sed 's|/|: |; s|-| |g')
commit_title=$(git log "$default_branch".."$current_branch" --format="%s" --reverse | head -1)
```

选择更有意义的标题（优先使用 commit 摘要）。

### Step 3: 生成 PR 描述

```bash
commits=$(git log "$default_branch".."$current_branch" --format="- %s" --reverse)
diff_stat=$(git diff "$default_branch"..."$current_branch" --stat)
```

### Step 4: 创建 PR

```bash
gh pr create --title "$pr_title" --body "$pr_body" --base "$default_branch"
```

如果 `--draft` 参数存在，执行：

```bash
gh pr create --draft --title "$pr_title" --body "$pr_body" --base "$default_branch"
```

如果 `--no-merge` 参数存在，显示 PR URL 后结束流程。

## Phase 3: Handoff（合并决策）

使用 **AskUserQuestion tool** 呈现选项：

**Question:** "PR 已创建: $pr_url。下一步？"

**Options:**
1. **立即合并到 $default_branch** - 使用 regular merge 合并并删除分支
2. **在浏览器中查看 PR** - 打开 GitHub PR 页面
3. **完成** - PR 已创建，不合并

Based on selection:
- **合并** → 执行 `gh pr merge --merge --delete-branch`，成功后执行 `git checkout "$default_branch"`，再执行 `git pull`
- **查看** → `gh pr view --web`，然后再次询问是否合并
- **完成** → 结束流程
