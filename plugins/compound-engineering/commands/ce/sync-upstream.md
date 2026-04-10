---
name: ce:sync-upstream
description: "[F] 检测上游仓库更新，生成智能分析报告，辅助决策是否整合"
argument-hint: "[F=强制全量扫描]"
---

# Upstream Sync Detection Command

一键检测多个上游仓库最近 30 天的更新，通过角色化策略获取数据，过滤噪音，生成带 YAML frontmatter 的结构化报告供用户决策是否整合。

## 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `[F]` | 强制全量扫描（v1 无实际差异，保留为未来缓存接口） | `/ce:sync-upstream [F]` |

## Main Tasks

### Phase 0: 参数解析与前置条件

检测 [F] 标志：如果包含 [F] 或 [f] → FULL_SCAN = true，从参数中移除。

**前置条件验证**：

1. `gh` CLI: `gh auth status`
2. `upstream` remote: `git remote get-url upstream`

失败不中断整体流程，仅对相关仓库标记 status=failed。

### Phase 1: 配置加载与数据获取

#### 1.1 读取配置

读取 `docs/sync-reports/upstream-repos.json`。如不存在，使用默认 4 仓库配置创建。

#### 1.2 并行获取数据

计算 30 天前日期：
```bash
powershell -c "(Get-Date).AddDays(-30).ToString('yyyy-MM-ddTHH:mm:ssZ')"
```

对每个仓库根据 strategy 并行执行：

**git-native** (parent): `git fetch upstream main --no-tags` → `git log --since="30 days ago" HEAD..upstream/main`

**github-api** (reference): `gh api repos/{owner}/{repo}/releases` + `gh api repos/{owner}/{repo}/commits`

**releases** (runtime): `gh api repos/{owner}/{repo}/releases`

### Phase 2: 噪音过滤与分析

排除：`^chore`、`^bump`、`dependabot`、`^Merge pull request`、`^Merge branch`

对每个变更评估相关性（高/中/低），必须附理由。

### Phase 3: 报告生成

写入 `docs/sync-reports/YYYY-MM-DD-upstream-sync.md`，包含 YAML frontmatter + 摘要表格 + 详细分析 + 整合建议优先级。

### Phase 4: 讨论

使用 AskUserQuestion：

"报告已生成。发现 N 个相关更新。下一步？"

1. **逐项讨论** — 对高相关变更逐个评估
2. **创建整合计划** — 运行 `/ce:plan`
3. **执行上游合并** — `git merge upstream/main --squash`
4. **稍后处理** — 结束流程
