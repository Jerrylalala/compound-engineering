---
title: "feat: 添加 /workflows:sync-upstream 上游仓库智能同步检测命令"
type: feat
date: 2026-02-04
brainstorm: docs/brainstorms/2026-02-04-upstream-sync-detection-brainstorm.md
deepened: 2026-02-04
---

# feat: 添加 /workflows:sync-upstream 上游仓库智能同步检测命令

## Enhancement Summary

**Deepened on:** 2026-02-04
**Research agents used:** 6（GitHub API 最佳实践、经验库、架构审查、Agent-Native 审查、简洁性审查、命令模式研究）

### Key Improvements (vs original plan)
1. **v1 简化**：移除 `.last-sync.json` 缓存机制，固定 30 天窗口，降低 58% 复杂度
2. **参数约定统一**：`--full` 改为 `[F]` 括号标志，与现有 `[C][G]` 一致
3. **GitHub API 加固**：Windows Git Bash 路径陷阱、`per_page=100`、错误分类、`--cache 1h`
4. **报告加 YAML frontmatter**：支持 `/workflows:plan` 自动发现和程序化消费
5. **PowerShell 编码防护**：JSON 文件写入必须使用 UTF-8 安全方法
6. **噪音过滤简化**：仅用排除规则，未命中排除的一律保留

### v2 Roadmap (不在本次实施范围)
- `.last-sync.json` 增量缓存（真正需要时再加）
- `--auto` 非交互模式（用于自动化管道）
- 过滤规则配置化（移入 `upstream-repos.json`）
- `--days N` / `--since DATE` 参数

---

## Overview

创建 `/workflows:sync-upstream` 命令，一键检测多个上游仓库最近 30 天的更新，通过角色化策略获取数据，过滤噪音，生成带 YAML frontmatter 的结构化报告供用户决策是否整合。

## Problem Statement / Motivation

当前上游同步完全依赖手动操作（`git fetch upstream` + 目视检查），存在以下问题：
- 容易遗漏重要更新（尤其是 BMAD、superpowers 等非 git remote 仓库）
- 无法系统性判断哪些变更与本仓库相关
- 缺少结构化的决策记录

## Proposed Solution

基于 brainstorm 阶段三方（Claude + Codex + Gemini）共识，**经 6 个审查 agent 简化后**：

- **角色化策略**：不同仓库用不同检测手段（git-native / github-api / releases）
- **可扩展配置**：`upstream-repos.json` 支持动态添加仓库（用户明确要求）
- **两步分析**：Releases 优先展示 → 过滤后 Commits 补充
- **结构化报告**：带 YAML frontmatter，支持 `/workflows:plan` 自动发现

## Technical Considerations

### 前置条件
- `gh` CLI 已安装且已登录（`gh auth status`）
- `upstream` git remote 已配置（仅对 `parent` 角色仓库）
- 网络可访问 GitHub

### GitHub API 要点（研究成果）

| 要点 | 做法 |
|------|------|
| 分页 | 始终 `per_page=100`，用 `--paginate` 自动翻页 |
| 日期过滤 | 用服务端 `-f since=` 参数，不在客户端过滤 |
| 缓存 | releases 用 `--cache 1h`（变动不频繁） |
| Windows 路径 | `gh api` 端点**不加**前导 `/`（Git Bash 会路径展开） |
| 速率限制 | 个人 token 5000/h，4 个仓库约 17 请求，安全 |
| 顺序执行 | API 仓库间串行 + `sleep 1`，避免 secondary rate limit |

### 错误分类

```
403 + "rate limit" → "GitHub API 速率限制，请稍后重试"
404              → "仓库不存在或无权限: [repo]。检查仓库名和 gh auth 状态"
401              → "认证失败。请运行 gh auth login"
网络超时          → "网络连接失败，跳过该仓库"
```

### 边界情况处理
- **首次运行无 `upstream-repos.json`**：使用硬编码默认 4 个仓库，同时创建配置文件
- **部分仓库获取失败**：继续处理其余仓库，报告中标注失败原因和修复指引
- **无新更新**：输出「所有仓库已是最新」
- **`[F]` 标志**：v1 中无实际作用（始终 30 天），保留为未来缓存机制的接口
- **同日重复运行**：覆盖同名报告（符合预期——最新结果最重要）
- **`upstream` remote 不存在**：报告错误并给出 `git remote add upstream <url>` 修复命令

### PowerShell 编码防护（经验库教训）

> **铁律**：JSON 文件写入不得使用 `Set-Content`，必须使用 Write 工具或 `[System.IO.File]::WriteAllText()`

原因：Windows PowerShell 默认编码非 UTF-8，会损坏中文字符。本命令只使用 Claude Code 的 Write 工具写文件，不触发此问题。

## Acceptance Criteria

- [ ] `/workflows:sync-upstream` 命令可正常触发
- [ ] 正确读取 `upstream-repos.json` 配置（或使用默认值创建）
- [ ] **首次运行**无配置文件时自动创建并执行 30 天扫描
- [ ] 并行获取 4 个仓库的更新数据
- [ ] 噪音过滤有效（chore/bump/dependabot 被排除）
- [ ] 生成带 YAML frontmatter 的报告到 `docs/sync-reports/`
- [ ] 进入交互式讨论阶段
- [ ] 部分仓库失败时不中断整体流程，报告中标注错误
- [ ] 版本号更新至 2.40.0
- [ ] CHANGELOG.md 已更新
- [ ] `docs/zh-CN/SYNC.md` 交叉引用新命令

---

## 实施计划

### Task 1: 创建 `docs/sync-reports/` 目录和配置文件

**文件**: `docs/sync-reports/upstream-repos.json`（新建）
**操作**:
- [ ] 创建 `docs/sync-reports/` 目录
- [ ] 创建 `upstream-repos.json`，包含 schema version 和 4 个默认仓库

**代码**:
```json
{
  "version": 1,
  "repos": [
    {
      "repo": "EveryInc/compound-engineering-plugin",
      "role": "parent",
      "strategy": "git-native",
      "remote": "upstream",
      "description": "主上游，需要直接 merge"
    },
    {
      "repo": "bmad-code-org/BMAD-METHOD",
      "role": "reference",
      "strategy": "github-api",
      "description": "方法论参考，学习 Prompt/Skill 设计"
    },
    {
      "repo": "obra/superpowers",
      "role": "reference",
      "strategy": "github-api",
      "description": "技能参考，按需手动迁移"
    },
    {
      "repo": "anthropics/claude-code",
      "role": "runtime",
      "strategy": "releases",
      "description": "运行时环境，关注新功能/API 变化"
    }
  ]
}
```

### Research Insights
- **架构审查**：添加 `"version": 1` 字段，为未来 schema 演进提供迁移路径
- **`remote` 字段**：仅对 `strategy: "git-native"` 有意义，其他策略忽略此字段

**验证**:
- [ ] 运行 `powershell -c "Get-Content docs/sync-reports/upstream-repos.json | ConvertFrom-Json"` 确认 JSON 合法

---

### Task 2: 创建命令文件 — 框架和参数解析（Phase 0）

**文件**: `plugins/compound-engineering/commands/workflows/sync-upstream.md`（新建）
**操作**:
- [ ] 创建命令文件，包含 YAML frontmatter
- [ ] 写 Phase 0：参数解析（使用 `<argument_parsing>` XML 标签模式）
- [ ] 写前置条件检查（`gh` CLI、`upstream` remote）

**代码**:

frontmatter:
```yaml
---
name: workflows:sync-upstream
description: "独立工具: 检测上游仓库更新，生成智能分析报告，辅助决策是否整合"
argument-hint: "[F]"
---
```

Phase 0 使用现有命令的 `<argument_parsing>` 模式：
```markdown
<sync_args> #$ARGUMENTS </sync_args>

### Phase 0: 参数解析与前置条件

<argument_parsing>

检测 [F] 标志：
  如果包含 [F] 或 [f]：
    → FULL_SCAN = true（v1 无实际差异，保留为缓存接口）
    → 从参数中移除 [F]
  否则：
    → FULL_SCAN = false

</argument_parsing>

<prerequisites>

**前置条件验证（逐项检查，失败不中断）：**

1. `gh` CLI:
   ```bash
   gh auth status
   ```
   失败 → 提示: "请运行 `gh auth login` 登录 GitHub CLI"

2. `upstream` remote（仅对 parent 角色仓库）:
   ```bash
   git remote get-url upstream
   ```
   失败 → 提示: "请运行 `git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git`"
   参考: docs/zh-CN/SYNC.md

</prerequisites>
```

### Research Insights
- **命令模式研究**：`<argument_parsing>` 和 `<prerequisites>` XML 标签是 `workflows:review` 的标准模式
- **架构审查**：用 `[F]` 替代 `--full`，与 `[C][G]` 括号标志惯例一致
- **描述格式**：用「独立工具:」替代「Step N:」，因为此命令不在线性工作流中

**验证**:
- [ ] 文件存在于 `plugins/compound-engineering/commands/workflows/sync-upstream.md`
- [ ] frontmatter 的 `name` 以 `workflows:` 开头

---

### Task 3: 写 Phase 1 — 配置加载和数据获取

**文件**: `plugins/compound-engineering/commands/workflows/sync-upstream.md`（续写）
**操作**:
- [ ] Phase 1.1：读取 `upstream-repos.json`（不存在则用默认值 + 创建文件）
- [ ] Phase 1.2：定义 Phase 1 输出数据结构
- [ ] Phase 1.3：并行获取数据，按 strategy 分派

**代码**:

```markdown
### Phase 1: 配置加载与数据获取

#### 1.1 读取配置

使用 Read 工具读取 `docs/sync-reports/upstream-repos.json`。

如果文件不存在：
1. 使用以下默认配置（4 个仓库）
2. 使用 Write 工具创建 `docs/sync-reports/upstream-repos.json`

#### 1.2 Phase 1 输出数据结构

每个仓库的获取结果应包含：
```
repo:     仓库标识 (owner/name)
status:   success | failed
error:    失败原因（仅 status=failed 时）
releases: [{tag, date, body}]
commits:  [{sha, message, date, author}]
```

#### 1.3 并行获取数据

<parallel_tasks>

对每个仓库，根据 strategy 使用 Bash 工具并行执行：

**git-native** (parent 角色):
```bash
git fetch upstream main --no-tags
git log --format="%h|%ai|%an|%s" --since="30 days ago" HEAD..upstream/main
```

**github-api** (reference 角色):
```bash
# Releases（带缓存）
gh api --cache 1h repos/{owner}/{repo}/releases -F per_page=100 --jq ".[] | select(.published_at > \"$SINCE_DATE\") | {tag: .tag_name, date: .published_at, body: .body}"

# Commits（服务端日期过滤）
gh api repos/{owner}/{repo}/commits -f since=$SINCE_DATE -F per_page=100 --jq ".[] | {sha: .sha[:7], date: .commit.author.date, message: (.commit.message | split(\"\n\") | .[0])}"
```

**releases** (runtime 角色):
```bash
gh api --cache 1h repos/{owner}/{repo}/releases -F per_page=100 --jq ".[] | select(.published_at > \"$SINCE_DATE\") | {tag: .tag_name, date: .published_at, name: .name, body: .body}"
```

</parallel_tasks>

**错误处理**: 每个仓库的获取独立。如果某个仓库失败：
- 记录 status=failed 和 error 原因
- 根据错误分类提供修复指引（见 Technical Considerations 错误分类表）
- 继续处理其他仓库

**注意**: gh api 端点不加前导 `/`（Windows Git Bash 路径展开问题）
```

### Research Insights
- **GitHub API 研究**：`-f since=` 是服务端过滤，比客户端 jq 过滤高效
- **GitHub API 研究**：releases 用 `--cache 1h` 减少重复请求
- **GitHub API 研究**：Windows Git Bash 的 `gh api /repos/...` 会被路径展开，**去掉前导 `/`**
- **架构审查**：定义 Phase 间数据结构（1.2 节），消除 AI 解释歧义
- **简洁性审查**：不用 `--paginate`（30 天内 commits 通常 <100），如超限用户可再调

**验证**:
- [ ] 三种 strategy 都有完整命令
- [ ] 有并行执行的 `<parallel_tasks>` 标签
- [ ] 有错误处理和 Windows 注意事项

---

### Task 4: 写 Phase 2 — 噪音过滤和分析

**文件**: `plugins/compound-engineering/commands/workflows/sync-upstream.md`（续写）
**操作**:
- [ ] Phase 2.1：噪音过滤（仅排除规则，简洁性审查建议）
- [ ] Phase 2.2：两步分析（Releases 优先 → Commits 补充）
- [ ] Phase 2.3：相关性判断（附理由列，Agent-Native 审查建议）

**代码**:

```markdown
### Phase 2: 噪音过滤与分析

#### 2.1 噪音过滤

对获取到的 commits 应用排除规则（未命中排除的一律保留）：

**排除**（正则匹配 commit message 首行）:
- `^chore(\(.*\))?:` — 日常维护
- `^bump` / `^Bump` — 版本号升级
- `dependabot` — 自动依赖更新
- `^Merge pull request` — 纯合并
- `^Merge branch` — 分支合并

其他所有 commits 保留（包括非 conventional commits 格式的消息）。

#### 2.2 两步分析

**Step 1: Releases**（信噪比最高）
对每个仓库，如果有新 Release：
- 提取 release body（changelog/notes）
- 分析与本仓库的关联
- 按类型分类：新功能 / Bug 修复 / 重构 / 文档

**Step 2: 过滤后 Commits**（补充信息）
对所有仓库（无论是否有 Release），展示过滤后的 commits：
- 重点标注触及 skills/, agents/, commands/ 目录的变更
- 按 scope 分组展示

#### 2.3 相关性判断

对每个变更评估相关性，**必须附理由**：

| 相关度 | 标准 | 示例 | 理由示例 |
|--------|------|------|----------|
| **高** | 修复本仓库也有的功能 | upstream 修了 review.md bug | 本仓库 fork 了同一文件 |
| **高** | 新增缺失的核心功能 | upstream 新增 workflow 命令 | 补充本仓库功能缺口 |
| **中** | 新增可选功能或改进 | BMAD 添加 prompt 模板 | 可参考其设计思路 |
| **低** | 与本仓库无关 | 特定语言 agent | 本仓库无此需求 |
```

### Research Insights
- **简洁性审查**：移除「保留规则」列表，仅用排除规则——未命中即保留，更简洁更健壮
- **简洁性审查**：移除「第三层按需 Diff」——用户想深入时自然对话即可，无需工程化
- **Agent-Native 审查**：相关性判断必须附 `理由` 列，让人和 agent 都能验证判断依据

**验证**:
- [ ] 排除规则完整且仅有排除（无冗余保留规则）
- [ ] 两步分析逻辑清晰
- [ ] 相关性判断表有 `理由` 列

---

### Task 5: 写 Phase 3 — 报告生成 + Phase 4 讨论 + 收尾

**文件**: `plugins/compound-engineering/commands/workflows/sync-upstream.md`（续写）
**操作**:
- [ ] Phase 3.1：生成带 YAML frontmatter 的报告
- [ ] Phase 3.2：语音通知（条件触发）
- [ ] Phase 4：展示摘要 + 讨论下一步
- [ ] Related Commands 部分

**代码**:

```markdown
### Phase 3: 报告生成

#### 3.1 生成报告

使用 Write 工具创建 `docs/sync-reports/YYYY-MM-DD-upstream-sync.md`。

**报告必须包含 YAML frontmatter**（支持 /workflows:plan 自动发现）:

```yaml
---
type: sync-report
date: YYYY-MM-DD
scan_mode: full
repos_checked: 4
repos_with_updates: N
items:
  - repo: "EveryInc/compound-engineering-plugin"
    relevance: high
    action: pending
    new_releases: 1
    new_commits: 12
  - repo: "bmad-code-org/BMAD-METHOD"
    relevance: medium
    action: pending
    new_releases: 0
    new_commits: 28
---
```

报告正文结构：
1. **摘要表格**：仓库 / 新 Release / 新 Commits / 相关度 / 建议
2. **详细分析**：每个仓库的变更列表（按相关度排序）
3. **整合建议**：高相关 → 建议整合 / 中相关 → 可选参考 / 低相关 → 暂不需要

#### 3.2 语音通知

如果 `$HOME/.claude/hooks/speak.ps1` 文件存在：
- 发现高相关变更 → `powershell -ExecutionPolicy Bypass -File "$HOME/.claude/hooks/speak.ps1" "发现重要上游更新"`
- 所有仓库无更新 → `powershell -ExecutionPolicy Bypass -File "$HOME/.claude/hooks/speak.ps1" "上游无新更新"`

如果脚本不存在 → 跳过语音，仅文字输出。

### Phase 4: 讨论

#### 4.1 展示摘要

输出报告的摘要表格，标注高相关和中相关的变更。

#### 4.2 下一步

使用 AskUserQuestion 工具：

"报告已生成。发现 N 个相关更新。下一步？"

选项：
1. **逐项讨论** — 对高相关变更逐个评估是否整合
2. **创建整合计划** — 对高相关项直接运行 /workflows:plan
3. **执行上游合并** — 对 parent 角色仓库执行 git merge
4. **稍后处理** — 报告已保存，随时回顾

## Related Commands

| 命令 | 关系 |
|------|------|
| `/workflows:load` | 加载项目上下文（可在 sync 前运行） |
| `/workflows:plan` | 自动检测 docs/sync-reports/ 中的报告，创建整合计划 |
| `/workflows:work` | 执行整合工作 |
```

### Research Insights
- **Agent-Native 审查（关键）**：报告 YAML frontmatter 是最高价值改进——让 `/workflows:plan` 能程序化消费报告
- **架构审查**：语音通知加平台检查——脚本不存在时跳过，避免跨平台失败
- **简洁性审查**：合并原 Task 5（报告）和 Task 6（讨论）为一个 Task，交互讨论简化为 4 个选项
- **简洁性审查**：Phase 4 不再逐项 AskUserQuestion——先问总体方向，用户选「逐项讨论」再展开

**验证**:
- [ ] 报告有 YAML frontmatter
- [ ] 语音通知有文件存在性检查
- [ ] Phase 4 有清晰的选项

---

### Task 6: 版本升级 + CHANGELOG + 文档更新 + 提交

**文件**: 多个文件
**操作**:
- [ ] 运行 `bump-version.ps1 -BumpType minor`（2.39.0 → 2.40.0）
- [ ] 更新两个 JSON 文件的 description（28 commands → 29 commands）
- [ ] 在 `plugins/compound-engineering/CHANGELOG.md` 添加 v2.40.0 条目
- [ ] 更新 `CLAUDE.md` 组件统计（28 → 29 commands）
- [ ] 更新 `docs/zh-CN/WORKFLOW-VISUAL.md` 添加 sync-upstream
- [ ] 更新 `docs/zh-CN/INSTALL.md` 添加新命令说明
- [ ] 更新 `docs/zh-CN/SYNC.md` 交叉引用新命令
- [ ] 运行版本检查确认
- [ ] Git commit

**CHANGELOG 条目**:
```markdown
## v2.40.0 (2026-02-04)

### 新增
- 添加 `/workflows:sync-upstream` 命令 — 上游仓库智能同步检测
  - 角色化策略：parent(git-native) / reference(github-api) / runtime(releases)
  - 可扩展配置：`upstream-repos.json` 支持动态添加仓库
  - 结构化报告：带 YAML frontmatter，支持 /workflows:plan 自动发现
  - 交互式讨论：评估后可直接创建整合计划或执行合并
```

**SYNC.md 追加内容**:
```markdown
## 自动化检测（推荐）

使用 `/workflows:sync-upstream` 命令可自动检测上游更新：
- 自动获取 4 个上游仓库最近 30 天的变更
- 智能过滤噪音，分析相关性
- 生成结构化报告供决策

手动合并步骤仍使用上述流程。
```

**验证**:
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 通过
- [ ] `powershell -c "(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count"` 输出 29
- [ ] `CLAUDE.md` 显示 29 commands
- [ ] `SYNC.md` 包含 sync-upstream 引用
- [ ] `WORKFLOW-VISUAL.md` 包含 sync-upstream
- [ ] `INSTALL.md` 包含新命令

---

## Dependencies & Risks

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| GitHub API 速率限制 | 低 | 4 仓库约 17 请求，远低于 5000/h 限额 |
| 大仓库 commit 多时 token 消耗 | 中 | 噪音过滤 + Releases 优先展示 |
| Windows Git Bash 路径展开 | 高 | `gh api` 端点不加前导 `/` |
| PowerShell 编码破坏 UTF-8 | 高 | 仅用 Claude Code Write 工具写文件 |
| `upstream` remote 不存在 | 低 | 检测后给出 `git remote add` 修复命令 |

---

## References & Research

### Internal References
- Brainstorm 文档: `docs/brainstorms/2026-02-04-upstream-sync-detection-brainstorm.md`
- 现有同步指南: `docs/zh-CN/SYNC.md`
- 命令模式参考: `plugins/compound-engineering/commands/workflows/review.md`
- 版本管理: `docs/zh-CN/VERSION-STRATEGY.md`
- 经验库: `docs/solutions/integration-issues/`

### External References (from research)
- [GitHub REST API Rate Limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)
- [gh api manual](https://cli.github.com/manual/gh_api) — `--cache`, `--paginate`, `--jq`
- [gh api Windows path expansion bug](https://github.com/cli/cli/issues/6415) — 不加前导 `/`
- [gh --paginate + --slurp 不兼容](https://github.com/cli/cli/issues/10459)

### Deepening Research Agents
| Agent | 关键贡献 |
|-------|----------|
| GitHub API 最佳实践 | `per_page=100`、`--cache 1h`、Windows 路径陷阱、错误分类 |
| 经验库 | PowerShell UTF-8 编码、幻影 agent 引用、版本 4 位同步 |
| 架构审查 | schema version、Phase 间数据结构、`[F]` 括号惯例、缓存 .gitignore |
| Agent-Native 审查 | YAML frontmatter、理由列、非交互模式(v2)、过滤规则配置化(v2) |
| 简洁性审查 | 移除缓存(v1)、合并任务、排除规则简化、两步替代三层 |
| 命令模式研究 | `<argument_parsing>`/`<parallel_tasks>` XML 标签、pseudocode 格式 |

### 三方 AI 咨询 (Brainstorm 阶段)
- Codex (GPT-5.2): 增量缓存设计（移至 v2 Roadmap）
- Gemini: 角色化混合策略（已采纳）
- 详见 brainstorm 文档
