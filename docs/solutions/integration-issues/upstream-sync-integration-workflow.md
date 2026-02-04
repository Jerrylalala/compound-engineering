---
title: 上游同步整合的完整工作流
date: 2026-02-04
category: integration-issues
tags: [upstream-sync, git-merge-squash, multi-tool-review, changelog, yaml-frontmatter]
module: workflows
symptoms:
  - 上游有更新需要整合
  - commit 历史中英文混杂
  - CHANGELOG 格式不规范
resolution: verified
---

# 上游同步检测到整合的完整工作流

## 问题描述

本仓库（`Jerrylalala/compound-engineering-plugin-private`）是 `EveryInc/compound-engineering-plugin` 的私有 fork，同时监控 4 个上游仓库的变更：

| 上游仓库 | 作用 |
|----------|------|
| EveryInc/compound-engineering-plugin | 主上游，插件源码 |
| anthropics/claude-code | Claude Code 官方，语法/API 变更 |
| jasonm23/superpowers | 最佳实践参考（subagent worktree 等） |
| obie/claude-on-rails | Rails 相关参考 |

当 `/workflows:sync-upstream` 检测到上游有变更时，需要一套标准化的整合流程。缺乏规范的流程会导致以下问题：

1. **commit 历史混乱** -- 上游英文 commit 与本仓库中文 commit 混杂
2. **CHANGELOG 格式不一致** -- 使用非标准 section 名称（如 Merged/Verified）
3. **同步报告状态过期** -- YAML frontmatter 的 `action` 字段未更新，下游自动化误判
4. **整合质量不可控** -- 缺少多方审核，问题遗漏到生产环境

## 根因 / 上下文

### 1. 多仓库监控的复杂性

同时监控 4 个仓库意味着每次同步可能产生多种操作类型：

| 操作类型 | 说明 | 典型场景 |
|----------|------|----------|
| merge | 直接合并代码 | EveryInc 有新功能/修复 |
| skip | 确认无需操作 | 变更与本仓库无关 |
| reference | 参考最佳实践 | superpowers 的新模式 |
| review | 仅评估，不合并 | claude-code 的语法变更 |

### 2. commit 历史一致性要求

本仓库约定使用中文 commit message，但上游仓库全部使用英文。直接 `git merge` 会将大量英文 commit 混入历史，破坏可读性。

### 3. CHANGELOG 规范

Keep a Changelog 标准只允许以下 section：

```
Added / Changed / Deprecated / Removed / Fixed / Security
```

自定义 section（如 Merged、Verified、Synced）会导致解析工具和阅读习惯的不兼容。

## 解决方案

### 完整工作流（7 步）

```
Step 1: 生成同步报告
  │
  ▼
Step 2: 逐项评估变更
  │
  ├── 需要合并 ──► Step 3: git merge --squash
  ├── 需要验证 ──► Step 4: 搜索验证
  ├── 需要参考 ──► Step 5: 整合最佳实践
  └── 无需操作 ──► 标记 skip
  │
  ▼
Step 6: 多方审核
  │
  ▼
Step 7: 根据审核反馈修复
```

---

### Step 1: 运行 `/workflows:sync-upstream` 生成报告

```bash
/workflows:sync-upstream
```

生成的报告包含 YAML frontmatter，格式如下：

```yaml
---
sync_date: "2026-02-04"
repositories:
  - name: EveryInc/compound-engineering-plugin
    status: behind
    commits_behind: 5
    action: pending        # ← 初始状态，整合后必须更新
  - name: anthropics/claude-code
    status: behind
    commits_behind: 12
    action: pending
  - name: jasonm23/superpowers
    status: behind
    commits_behind: 3
    action: pending
---
```

### Step 2: 逐项评估每个仓库的变更

选择「逐项讨论」模式，逐个评估每个仓库的变更内容和影响：

```
对每个仓库：
  1. 查看 commit 列表和 diff
  2. 判断与本仓库的关联性
  3. 决定操作类型（merge / skip / reference / review）
  4. 记录理由
```

### Step 3: 使用 `git merge --squash` 合并上游代码

**关键技巧**：`--squash` 将上游多个英文 commit 压缩为一个，再用中文编写 commit message。

```bash
# 1. 确保上游 remote 已配置
git remote -v
# upstream  https://github.com/EveryInc/compound-engineering-plugin.git (fetch)

# 2. 拉取上游最新代码
git fetch upstream

# 3. 使用 --squash 合并（不自动 commit）
git merge --squash upstream/main

# 4. 检查合并内容
git diff --cached --stat

# 5. 用中文编写 commit message
git commit -m "$(cat <<'EOF'
合并上游 EveryInc #142: 新增 X 功能、修复 Y 问题

- 合并 upstream/main 的 5 个 commit
- 主要变更：...
- 冲突解决：...（如有）

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**为什么用 `--squash` 而不是 `merge` 或 `rebase`**：

| 方式 | commit 历史 | 中文一致性 | 冲突处理 |
|------|-------------|------------|----------|
| `git merge` | 保留所有英文 commit | 破坏 | 一次性 |
| `git rebase` | 重写历史 | 破坏 | 逐 commit |
| `git merge --squash` | 压缩为一个 commit | 保持 | 一次性 |

### Step 4: 搜索验证（不需要合并的变更）

对于不需要合并但需要验证是否影响本仓库的变更（如 Claude Code 语法更新）：

```bash
# 例：Claude Code v2.1.19 引入 $ARGUMENTS 语法
# 搜索本仓库是否使用了相关语法
Grep pattern="\\\$ARGUMENTS" path=plugins/compound-engineering/

# 如果无匹配，标记为 reviewed（确认无需修改）
# 如果有匹配，评估是否需要更新
```

### Step 5: 整合最佳实践（参考但不合并）

对于上游仓库的优秀实践，提取核心理念并适配到本仓库：

```
例：superpowers 的 subagent worktree 最佳实践

1. 阅读上游实现
2. 提取核心模式（而非复制代码）
3. 适配到本仓库的 /workflows:work 命令
4. 标记 action 为 referenced
```

### Step 6: 运行多方审核

```bash
/workflows:review [C][G]
```

本次实践中使用了五方审核（3 Claude agents + Codex + Gemini），发现了 3 个 P2 问题：

| 问题 | 审核方 | 修复 |
|------|--------|------|
| CHANGELOG 使用非标准 section | Codex + Gemini | 改为 Added/Changed/Fixed |
| YAML frontmatter action 未更新 | 架构策略师 | 更新为实际状态 |
| Guard 伪代码不清晰 | 简洁审查员 | 补充完整逻辑 |

### Step 7: 根据审核反馈修复

逐个修复审核中发现的问题，每个修复都需要验证：

```bash
# 修复后验证
git diff                    # 确认修改内容
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1  # 版本一致性
```

---

### 整合后更新 YAML frontmatter

**这一步容易遗漏，但至关重要。** 同步报告中每个仓库的 `action` 字段必须更新为实际结果：

```yaml
repositories:
  - name: EveryInc/compound-engineering-plugin
    action: merged           # ← 已合并
  - name: anthropics/claude-code
    action: reviewed         # ← 已验证，无需修改
  - name: jasonm23/superpowers
    action: referenced       # ← 已参考整合
  - name: obie/claude-on-rails
    action: skipped          # ← 无相关变更
```

**合法的 action 值**：

| 值 | 含义 |
|----|------|
| `pending` | 初始状态，尚未处理 |
| `merged` | 已合并代码 |
| `skipped` | 已评估，无需操作 |
| `referenced` | 已参考最佳实践 |
| `reviewed` | 已验证，确认无需修改 |

### CHANGELOG 格式规范

使用 Keep a Changelog 标准 section，不要发明自定义 section：

```markdown
## [2.35.0] - 2026-02-04

### Added
- 新增 X 功能

### Changed
- 整合上游 EveryInc #142 的 Y 变更
- 参考 superpowers 优化 subagent 执行模式

### Fixed
- 修复 Z 问题
```

**禁止使用的 section 名称**：Merged、Verified、Synced、Referenced、Upstream -- 这些都不是 Keep a Changelog 标准。

## 预防策略

### 1. 整合前检查清单

每次运行 `/workflows:sync-upstream` 后，按此清单操作：

- [ ] 逐个评估每个仓库的变更
- [ ] 需合并的使用 `git merge --squash`（保持中文 commit）
- [ ] 需验证的用 Grep 搜索本仓库是否受影响
- [ ] 需参考的提取核心理念适配（不直接复制）
- [ ] 更新 YAML frontmatter 的 action 字段
- [ ] CHANGELOG 使用标准 section 名称
- [ ] 运行多方审核（至少 `/workflows:review`）
- [ ] 修复审核反馈中的问题

### 2. CHANGELOG 格式自动校验

在审核阶段，检查 CHANGELOG 是否只包含标准 section：

```bash
# 检查 CHANGELOG 是否包含非标准 section
grep "^### " plugins/compound-engineering/CHANGELOG.md | \
  grep -v -E "^### (Added|Changed|Deprecated|Removed|Fixed|Security)"
# 如果有输出，说明使用了非标准 section
```

### 3. prompt 文件中的冗余策略

五方审核中发现了一个有价值的分歧：

- **架构策略师**：prompt 中的冗余约束是「安全网」，LLM 不保证遵循单一指令
- **简洁审查员**：3 处说同一件事，85% 冗余

**结论**：prompt 文件（`.md` 中的 LLM 指令）与代码文件的冗余标准不同。代码中冗余是坏味道，但 prompt 中适度冗余是合理的防御策略。

### 4. 定期同步节奏

建议每周运行一次 `/workflows:sync-upstream`，避免积压过多变更导致整合困难。

## 关键教训

1. **`git merge --squash` 是 fork 仓库整合的最佳策略** -- 将上游多个英文 commit 压缩为一个中文 commit，保持历史一致性，同时保留完整变更内容
2. **YAML frontmatter action 字段必须在整合后更新** -- 初始状态 `pending` 如果不更新为实际结果（merged/skipped/referenced/reviewed），下游自动化工具会误判该仓库仍需处理
3. **CHANGELOG 必须使用 Keep a Changelog 标准** -- Added/Changed/Fixed/Deprecated/Removed/Security，不要发明 Merged/Verified/Synced 等非标准 section
4. **prompt 文件的冗余标准不同于代码** -- LLM 不保证遵循单一指令，关键约束在 prompt 中重复 2-3 次是合理的安全网
5. **多方审核能发现单视角盲区** -- 五方审核中，不同角色从不同维度发现问题，互相补充

## 相关文档

| 文档 | 说明 |
|------|------|
| [安装与使用指南](../../zh-CN/INSTALL.md) | `/workflows:sync-upstream` 命令说明 |
| [上游同步指南](../../zh-CN/SYNC.md) | 手动同步上游的步骤 |
| [幻影 Agent 引用问题](phantom-agent-references-in-workflows.md) | 上游同步时发现的 agent 缺失问题 |
| [Subagent-Driven 工作流整合](subagent-driven-workflow-integration.md) | 从 superpowers 参考整合的执行模式 |
| [版本管理预防策略](../../zh-CN/VERSION-STRATEGY.md) | 同步后版本号更新规范 |
