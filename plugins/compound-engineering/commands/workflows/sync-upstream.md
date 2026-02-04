---
name: workflows:sync-upstream
description: "独立工具: 检测上游仓库更新，生成智能分析报告，辅助决策是否整合"
argument-hint: "[F]"
---

# Upstream Sync Detection Command

<command_purpose> 一键检测多个上游仓库最近 30 天的更新，通过角色化策略获取数据，过滤噪音，生成带 YAML frontmatter 的结构化报告供用户决策是否整合。 </command_purpose>

## Introduction

<role>上游同步分析专家，擅长跨仓库变更检测、噪音过滤和相关性判断</role>

## 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `[F]` | 强制全量扫描（v1 无实际差异，保留为未来缓存接口） | `/workflows:sync-upstream [F]` |

**示例：**
```bash
/workflows:sync-upstream          # 默认 30 天扫描
/workflows:sync-upstream [F]      # 强制全量扫描（v1 行为相同）
```

## Main Tasks

### Phase 0: 参数解析与前置条件

<sync_args> #$ARGUMENTS </sync_args>

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

2. `upstream` remote（仅对 parent 角色仓库需要）:
   ```bash
   git remote get-url upstream
   ```
   失败 → 提示: "请运行 `git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git`"
   参考: docs/zh-CN/SYNC.md

**注意**：前置条件检查失败不中断整体流程，仅对相关仓库标记 status=failed。

</prerequisites>

### Phase 1: 配置加载与数据获取

#### 1.1 读取配置

使用 Read 工具读取 `docs/sync-reports/upstream-repos.json`。

如果文件不存在：
1. 使用以下默认配置创建文件（4 个仓库）：

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

2. 使用 Write 工具将默认配置写入 `docs/sync-reports/upstream-repos.json`

#### 1.2 Phase 1 输出数据结构

每个仓库的获取结果应包含：
```
repo:     仓库标识 (owner/name)
role:     角色 (parent/reference/runtime)
status:   success | failed
error:    失败原因（仅 status=failed 时）
releases: [{tag, date, body}]
commits:  [{sha, message, date, author}]
```

#### 1.3 并行获取数据

<parallel_tasks>

计算 30 天前的日期（ISO 8601 格式）：
```bash
# Windows PowerShell
powershell -c "(Get-Date).AddDays(-30).ToString('yyyy-MM-ddTHH:mm:ssZ')"
```
将此日期存为 `$SINCE_DATE` 供后续使用。

对每个仓库，根据 strategy 使用 Bash 工具并行执行：

**git-native** (parent 角色):
```bash
# 获取最新代码
git fetch upstream main --no-tags

# 获取 commits（30 天内，upstream/main 相对 HEAD 的差异）
git log --format="%h|%ai|%an|%s" --since="30 days ago" HEAD..upstream/main
```

**github-api** (reference 角色):
```bash
# Releases（带缓存）— 注意端点不加前导 /（Windows Git Bash 路径展开问题）
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
- 根据错误分类提供修复指引：
  ```
  403 + "rate limit" → "GitHub API 速率限制，请稍后重试"
  404              → "仓库不存在或无权限: [repo]。检查仓库名和 gh auth 状态"
  401              → "认证失败。请运行 gh auth login"
  网络超时          → "网络连接失败，跳过该仓库"
  ```
- 继续处理其他仓库

**注意**: `gh api` 端点**不加**前导 `/`（Windows Git Bash 会路径展开）。

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

### Phase 3: 报告生成

#### 3.1 生成报告

使用 Write 工具创建 `docs/sync-reports/YYYY-MM-DD-upstream-sync.md`（使用当天日期）。

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

```markdown
# 上游同步检测报告

**日期**: YYYY-MM-DD
**检测范围**: 最近 30 天

## 摘要

| 仓库 | 新 Release | 新 Commits | 相关度 | 建议动作 |
|------|-----------|-----------|--------|----------|
| EveryInc/compound-engineering-plugin | vX.Y.Z | N | 高/中/低 | 需要合并/选择性参考/暂不需要 |
| bmad-code-org/BMAD-METHOD | - | N | 高/中/低 | ... |
| obra/superpowers | - | N | 高/中/低 | ... |
| anthropics/claude-code | vX.Y.Z | - | 高/中/低 | ... |

## 详细分析

### EveryInc/compound-engineering-plugin
#### Release Notes
[release body 内容]

#### 相关变更
| 变更 | 类型 | 相关性 | 理由 | 建议 |
|------|------|--------|------|------|
| [commit message] | feat/fix/refactor | 高/中/低 | [判断依据] | 建议合并/参考/忽略 |

### bmad-code-org/BMAD-METHOD
[同上格式]

### obra/superpowers
[同上格式]

### anthropics/claude-code
[同上格式]

## 整合建议优先级

1. **必须整合**：[列表]
2. **建议整合**：[列表]
3. **可选参考**：[列表]
4. **暂不需要**：[列表]
```

#### 3.2 语音通知

如果 `$HOME/.claude/hooks/speak.ps1` 文件存在：
```bash
# 检查脚本是否存在
powershell -c "Test-Path '$HOME/.claude/hooks/speak.ps1'"
```

- 发现高相关变更 → `powershell -ExecutionPolicy Bypass -File "$HOME/.claude/hooks/speak.ps1" "发现重要上游更新"`
- 所有仓库无更新 → `powershell -ExecutionPolicy Bypass -File "$HOME/.claude/hooks/speak.ps1" "上游无新更新"`

如果脚本不存在 → 跳过语音，仅文字输出。

### Phase 4: 讨论

#### 4.1 展示摘要

输出报告的摘要表格，标注高相关和中相关的变更。

#### 4.2 下一步

使用 AskUserQuestion 工具：

"报告已生成至 `docs/sync-reports/YYYY-MM-DD-upstream-sync.md`。发现 N 个相关更新。下一步？"

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
