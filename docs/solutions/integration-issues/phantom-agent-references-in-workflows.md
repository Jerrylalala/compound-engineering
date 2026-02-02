---
title: "工作流命令引用不存在的 Agents（幻影引用问题）"
category: integration-issues
tags:
  - claude-code-plugin
  - agents
  - workflow
  - code-review
  - upstream-sync
symptoms:
  - "工作流命令引用的 agent 实际不存在"
  - "Task 调用可能失败或被静默忽略"
  - "上游代码与实现不一致"
module: compound-engineering-plugin
date_created: 2026-02-02
date_resolved: 2026-02-02
severity: medium
global_reference: ~/.claude/solutions/phantom-agent-references-in-workflows.md
---

# 工作流命令引用不存在的 Agents（幻影引用问题）

## 问题描述

在审查插件代码时发现，`/workflows:review`、`/workflows:work`、`/workflows:compound` 等命令引用了 5 个实际不存在的 agents：

| Agent 名称 | 引用位置 | 实际状态 |
|------------|----------|----------|
| rails-turbo-expert | review.md | ❌ 不存在 |
| dependency-detective | review.md | ❌ 不存在 |
| code-philosopher | review.md | ❌ 不存在 |
| devops-harmony-analyst | review.md | ❌ 不存在 |
| cora-test-reviewer | work.md, compound.md | ❌ 不存在 |

### 症状表现

- 执行 `/workflows:review` 时，Claude 尝试调用这些 agents
- 调用可能静默失败或被忽略
- 用户不清楚为什么某些"功能"不生效

## 根因分析

### 1. 上游仓库本身存在此问题

```bash
# 上游 review.md 引用了这些 agents
git show upstream/main:plugins/compound-engineering/commands/workflows/review.md | grep -E "turbo-expert|detective|philosopher|devops|cora"

# 但上游 agents/ 目录中并没有对应文件
git ls-tree upstream/main plugins/compound-engineering/agents/ | grep -E "turbo|detective|philosopher|devops|cora"
# (无输出)
```

### 2. 可能的历史原因

- **愿望清单**：原作者规划了这些 agents 但未实现
- **CORA 项目遗留**：`cora-test-reviewer` 明显是 Every 内部项目特定的
- **复制粘贴遗忘**：从其他项目复制了引用但忘记添加实现

### 3. 外部资源调查

| 资源 | 是否存在这些 agents |
|------|---------------------|
| GitHub 搜索 | ❌ 无匹配项目 |
| skills.sh | ❌ 无匹配 skill |
| BMAD-METHOD | ❌ 不存在 |
| superpowers | ❌ 不存在 |
| VoltAgent/awesome-claude-code-subagents | ❌ 无完全匹配，有类似功能 |

## 解决方案

### 选择：删除引用而非创建 agents

**理由**：

1. **YAGNI 原则** - 现有 agents 已覆盖核心需求
2. **功能重叠** - 已有 agents 可替代：
   - `kieran-rails-reviewer` 已包含 Turbo 规范
   - `architecture-strategist` + `code-simplicity-reviewer` 覆盖代码哲学
   - `security-sentinel` 可处理依赖安全
3. **维护成本** - 自建 agents 需持续维护
4. **未知定义** - 不清楚这些 agents 应该做什么

### 实施步骤

```bash
# 从 review.md 移除引用
# 原: 13 个 agents
# 改: 9 个 agents（移除 5 个不存在的）

# 从 work.md 移除 cora-test-reviewer
# 从 compound.md 移除 cora-test-reviewer
```

### 修改后的 agents 列表

```markdown
#### Parallel Agents to review the PR:

1. Task kieran-rails-reviewer(PR content)
2. Task dhh-rails-reviewer(PR title)
3. Task git-history-analyzer(PR content)
4. Task pattern-recognition-specialist(PR content)
5. Task architecture-strategist(PR content)
6. Task security-sentinel(PR content)
7. Task performance-oracle(PR content)
8. Task data-integrity-guardian(PR content)
9. Task agent-native-reviewer(PR content)
```

## 现有 Agents 覆盖分析

| 审查维度 | 现有 Agent | 覆盖情况 |
|---------|-----------|----------|
| Rails + Turbo | kieran-rails-reviewer | ✅ 包含 Turbo 规范 |
| Rails 哲学 | dhh-rails-reviewer | ✅ DHH 风格 |
| 架构设计 | architecture-strategist | ✅ |
| 代码简洁 | code-simplicity-reviewer | ✅ |
| 安全 | security-sentinel | ✅ |
| 性能 | performance-oracle | ✅ |
| 数据完整性 | data-integrity-guardian | ✅ |
| 模式识别 | pattern-recognition-specialist | ✅ |
| Git 历史 | git-history-analyzer | ✅ |
| Agent 可访问性 | agent-native-reviewer | ✅ |

## 预防策略

### 1. Fork 同步时检查

同步上游更新时，检查新引用的 agents 是否存在：

```bash
# 检查 workflow 命令中引用的 agents
grep -h "Task [a-z-]*(" plugins/compound-engineering/commands/workflows/*.md | \
  sed 's/.*Task \([a-z-]*\).*/\1/' | sort -u > /tmp/referenced-agents.txt

# 检查实际存在的 agents
ls plugins/compound-engineering/agents/**/*.md | \
  xargs -n1 basename | sed 's/.md//' | sort -u > /tmp/existing-agents.txt

# 找出差异
comm -23 /tmp/referenced-agents.txt /tmp/existing-agents.txt
```

### 2. 向上游反馈

考虑向上游提 Issue 或 PR：
- 报告 review.md 引用了不存在的 agents
- 建议移除或实现这些 agents

### 3. 添加新 agent 前评估

添加新 agent 前问：
1. 现有 agents 是否已覆盖此功能？
2. 这个 agent 是否有明确定义的职责？
3. 是否值得长期维护？

## 关键教训

1. **代码与文档要一致** - 引用的组件必须存在
2. **上游不一定正确** - Fork 时要审查，不要盲目信任
3. **YAGNI 优于完美** - 不要为"可能有用"的功能创建实现
4. **搜索先于创建** - 先搜索 GitHub/skills.sh 看是否有现成方案

## 相关资源

- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [obie/claude-on-rails](https://github.com/obie/claude-on-rails)
- [skills.sh](https://skills.sh/)
- Commit: `517387b` - 修复多个工作流配置错误
