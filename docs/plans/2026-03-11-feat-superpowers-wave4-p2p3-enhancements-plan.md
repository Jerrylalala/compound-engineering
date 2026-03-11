---
title: "feat: Superpowers Wave 4 P2-P3 遗留增强"
type: feat
date: 2026-03-11
risk_score: 1
risk_level: low
risk_note: "全部为 Markdown 提示词文件增强，完全可逆，无外部依赖"
---

# Superpowers Wave 4 P2-P3 遗留增强

## Overview

**Goal**: 完成 Superpowers 融合的最后一波（Wave 4），增强 5 个现有文件的工程方法论细节
**Tech Stack**: Markdown 提示词文件（无代码）
**Architecture**: 对 5 个现有 Skill/Command 文件做增量增强，每项 20-40 行，总计约 150 行新增内容

## Background

v2.44.0 完成 Wave 1-3（2 个新 Skill + 6 个文档增强），v2.44.1 做了精准硬化。
Wave 4 为最后一批低工作量 P2-P3 增强项，来源：`docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md`

## Acceptance Criteria

- [x] `systematic-debugging` 包含"无根因"分支 + 协作者信号表 + 跨技能引用
- [x] `git-worktree` 包含目录优先级协议 + 多语言依赖安装
- [x] `work.md` Subagent 模式包含上下文预注入 + 全局最终审查 + 失败任务处理
- [x] `CLAUDE.md` 包含 Rigid/Flexible 分类 + 宣告格式强化
- [x] `load.md` Handoff 包含完成度百分比显示
- [x] 版本号更新至 2.44.2 + CHANGELOG 记录
- [x] `bash scripts/check-handoff.sh` 全部通过
- [x] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 版本一致

---

## Tasks

### Task 1: 增强 systematic-debugging — "无根因"分支

**文件**: `plugins/compound-engineering/skills/systematic-debugging/SKILL.md:164`
**操作**:
- [ ] 在第三阶段 `#### 4. 不确定时` 之后（约 164 行），插入新的 `#### 5. 当找不到根因时`

**代码**:
```markdown
#### 5. 当找不到根因时

当完成所有 4 个阶段后仍无法确定根因时：

| 状态 | 行动 |
|------|------|
| 有假设但无法验证 | 设计最小实验隔离变量，使用 `test-driven-development` 写出失败测试 |
| 完全无方向 | 缩小范围 — 二分法注释代码直到问题消失，定位最小复现区间 |
| 问题间歇性出现 | 添加日志/断点守候，记录每次出现的环境差异 |
| 怀疑外部因素 | 锁定依赖版本、检查环境变量差异、对比正常/异常环境 |

**铁律**：无根因不代表无进展。记录已排除的假设，这本身就是有价值的信息。

> 到达此步骤后，使用 `AskUserQuestion` 向用户汇报已排除的假设列表，征求新线索。
```

**验证**:
- [ ] 搜索 `当找不到根因时` 确认已添加
- [ ] 确认位于第三阶段内部，第四阶段之前

---

### Task 2: 增强 systematic-debugging — 协作者信号解读表

**文件**: `plugins/compound-engineering/skills/systematic-debugging/SKILL.md:46`
**操作**:
- [ ] 在 `## 何时使用` 之后（约 46 行），插入 `## 协作者信号解读`

**代码**:
```markdown
## 协作者信号解读

用户报告问题时的描述往往模糊，需要解读其真实含义：

| 用户说的 | 可能的真实含义 | 调查方向 |
|----------|---------------|----------|
| "它不工作了" | 输出与预期不符 / 报错 / 无响应 | 先确认"不工作"的具体表现 |
| "有时候会出错" | 间歇性问题，可能涉及竞态/缓存/环境 | 收集出错时的环境快照 |
| "改了之后就坏了" | 最近的变更引入了回归 | `git log --oneline -10` 定位变更 |
| "一直都这样" | 可能是设计如此，或长期未被发现的 bug | 先查文档确认预期行为 |
| "很慢" | 性能下降，可能是 N+1、内存泄漏、网络 | 先量化"慢"（具体多少 ms） |
| "报了个奇怪的错" | 错误信息不直观，用户无法理解 | 直接要求完整错误信息和堆栈 |

**原则**：不要假设用户的描述是精确的。第一步永远是复现问题并确认实际症状。
```

**验证**:
- [ ] 搜索 `协作者信号解读` 确认已添加
- [ ] 确认位于 `何时使用` 和 `四个阶段` 之间

---

### Task 3: 增强 systematic-debugging — 跨技能引用闭环

**文件**: `plugins/compound-engineering/skills/systematic-debugging/SKILL.md:272`
**操作**:
- [ ] 在 `## 辅助技术` 末尾（约 272 行），追加跨技能引用

**代码**:
```markdown

### 跨技能闭环

调试不是孤立流程，与其他技能形成闭环：

```
发现 bug → systematic-debugging（定位根因）
    ↓ 找到根因
test-driven-development（写失败测试锁定 bug）
    ↓ 修复通过
finishing-a-feature（收尾验证 + 提交）
    ↓ 提交审查
receiving-code-review（接收反馈）
```

- **调试 → TDD**：找到根因后，先写失败测试再修复（防止回归）
- **调试 → 验证**：修复后必须通过完成前验证（见 CLAUDE.md 验证铁律）
- **调试 → 收尾**：修复完成后使用 `finishing-a-feature` 标准收尾
```

**验证**:
- [ ] 搜索 `跨技能闭环` 确认已添加
- [ ] 确认引用了 `test-driven-development`、`finishing-a-feature`、`receiving-code-review`

---

### Task 4: 增强 git-worktree — 目录选择优先级协议

**文件**: `plugins/compound-engineering/skills/git-worktree/SKILL.md:209`
**操作**:
- [ ] 在 `## Key Design Principles` 之后（约 209 行），`## Integration with Workflows` 之前，插入新章节

**代码**:
```markdown
## 目录选择优先级协议

创建 worktree 后，配置文件读取遵循三级优先级：

| 优先级 | 来源 | 示例 |
|:---:|------|------|
| 1 | **项目配置** | worktree 内的 `.claude/CLAUDE.md`、`CLAUDE.md` |
| 2 | **用户偏好** | `~/.claude/CLAUDE.md`（全局配置） |
| 3 | **插件默认** | 插件内置的 `CLAUDE.md`、skill 定义 |

**冲突规则**：高优先级覆盖低优先级。同级别冲突时，以更具体的配置为准。

> 注意：worktree 内的项目配置是隔离的副本，修改不影响主仓库。
```

**验证**:
- [ ] 搜索 `目录选择优先级协议` 确认已添加
- [ ] 确认位于 Key Design Principles 和 Integration 之间

---

### Task 5: 增强 git-worktree — 多语言依赖安装

**文件**: `plugins/compound-engineering/skills/git-worktree/SKILL.md:104`
**操作**:
- [ ] 在现有 create 命令的基线测试提醒（约 99-104 行）之后，追加依赖安装步骤
- [ ] 注意不要重复基线测试内容

**代码**:
```markdown

7. **环境初始化（自动检测）**

创建 worktree 后，检测项目类型并提醒安装依赖：

| 检测文件 | 包管理器 | 安装命令 |
|----------|----------|----------|
| `package-lock.json` | npm | `npm ci` |
| `yarn.lock` | yarn | `yarn install --frozen-lockfile` |
| `pnpm-lock.yaml` | pnpm | `pnpm install --frozen-lockfile` |
| `Gemfile.lock` | bundler | `bundle install` |
| `requirements.txt` | pip | `pip install -r requirements.txt` |
| `go.sum` | go | `go mod download` |

> **重要**：优先使用 lockfile 对应的包管理器（如有 `yarn.lock` 则用 yarn 而非 npm），确保依赖版本一致。
```

**验证**:
- [ ] 搜索 `环境初始化` 确认已添加
- [ ] 确认位于基线测试提醒之后
- [ ] 确认未重复基线测试内容

---

### Task 6: 增强 work.md — Subagent 上下文预注入

**文件**: `plugins/compound-engineering/commands/workflows/work.md:239`
**操作**:
- [ ] 在 Mode B Subagent-Driven 的任务分发模板（约 239 行）之前，插入上下文预注入指导

**代码**:
```markdown
#### 上下文预注入

在分发子代理之前，预先准备共享上下文，减少每个子代理重复读取文件的开销：

**预注入内容**（按需选择）：
1. **Plan 概要** — 当前计划的 Goal 和 Tech Stack（从 plan header 提取）
2. **架构约束** — 项目 CLAUDE.md 中的关键约束（如禁止项、命名规范）
3. **前置任务结果** — 已完成任务的关键输出（文件路径、API 签名等）

**注入方式**：在子代理 prompt 开头添加 `## Context` 区块：

```
## Context
- Goal: [从 plan header 提取]
- 已完成: Task 1 创建了 `src/auth.ts`，导出 `authenticate()`
- 约束: [项目特定约束]

## Your Task
[原有任务描述]
```

> **原则**：只注入必要上下文（≤500 字），过多上下文反而分散注意力。
```

**验证**:
- [ ] 搜索 `上下文预注入` 确认已添加
- [ ] 确认位于 Mode B 任务分发之前

---

### Task 7: 增强 work.md — 失败任务处理

**文件**: `plugins/compound-engineering/commands/workflows/work.md:283`
**操作**:
- [ ] 在 Mode B 批次执行循环之后（约 283 行），两阶段审查之前，插入失败处理规范

**代码**:
```markdown
#### 失败任务处理

子代理任务失败时，按以下流程处理（与 STOP 协议互补）：

```
子代理报告失败
    ↓
1. 诊断：失败原因是什么？
    ├─ 依赖缺失 → 先解决依赖，重新派发
    ├─ 指令不清晰 → 用 AskUserQuestion 向用户澄清
    ├─ 前置任务输出不符 → 修正前置输出后重试
    └─ 任务本身不可行 → 标记跳过，继续后续任务
    ↓
2. 决策：重试 or 跳过 or 终止？
    ├─ 重试（≤1次）→ 新子代理 + 失败原因注入 prompt
    ├─ 跳过 → 记录原因，继续后续任务
    └─ 终止 → 触发 STOP 协议
    ↓
3. 记录：在批次总结中标注失败/跳过的任务及原因
```

> **铁律**：同一任务最多重试 1 次。重试时必须在 prompt 中注入上次失败的原因。
```

**验证**:
- [ ] 搜索 `失败任务处理` 确认已添加
- [ ] 确认引用了 STOP 协议

---

### Task 8: 增强 work.md — 全局最终审查

**文件**: `plugins/compound-engineering/commands/workflows/work.md:283`
**操作**:
- [ ] 在失败任务处理之后、Phase 3 Quality Check 之前，插入全局最终审查

**代码**:
```markdown
#### 全局最终审查（Subagent 模式专属）

所有子代理任务完成后（进入 Phase 3 之前），执行一次整体一致性检查：

1. **冲突检测**：多个子代理是否修改了同一文件？如有冲突，人工合并
2. **接口一致性**：子代理 A 的输出类型是否与子代理 B 的输入匹配？
3. **命名一致性**：新增的函数/变量/文件名是否遵循项目命名规范？
4. **遗漏检测**：plan 中的所有任务是否都有对应的产出？

> 此审查由主代理执行（非子代理），确保全局视角。如发现问题，在进入 Phase 3 前修复。
```

**验证**:
- [ ] 搜索 `全局最终审查` 确认已添加
- [ ] 确认位于 Phase 2 和 Phase 3 之间

---

### Task 9: 增强 CLAUDE.md — Rigid/Flexible 技能分类

**文件**: `plugins/compound-engineering/CLAUDE.md:51`
**操作**:
- [ ] 在 `### 可用技能（按场景）` 表格之后（约 51 行），`### 技能优先级` 之前，插入分类表

**代码**:
```markdown
### 技能分类（刚性 vs 柔性）

| 分类 | 含义 | 技能 |
|------|------|------|
| **刚性**（铁律） | 必须完整执行每个步骤，不可跳过或简化 | `systematic-debugging`、`test-driven-development`、`finishing-a-feature`、`receiving-code-review` |
| **柔性**（指导） | 必须调用，但可根据上下文调整执行深度 | `brainstorming`、`git-worktree`、`create-agent-skills`、其余技能 |

**区分标准**：
- 刚性技能 = 跳过会导致可观测的质量下降（如：不调试就猜原因、不测试就提交）
- 柔性技能 = 跳过不会立即出错，但长期降低效率

> **注意**：两种分类都必须通过技能检查协议（1% 规则不变）。区别仅在于执行弹性。
```

**验证**:
- [ ] 搜索 `刚性 vs 柔性` 确认已添加
- [ ] 确认分类表包含至少 8 个技能

---

### Task 10: 增强 CLAUDE.md — 宣告格式强化

**文件**: `plugins/compound-engineering/CLAUDE.md:12`
**操作**:
- [ ] 强化现有检查流程中的 `宣布` 步骤（约 12 行），添加格式规范和示例

**代码**:

在现有的检查流程代码块之后，追加：

```markdown
### 宣告格式规范

调用技能时，使用统一格式主动宣告：

**格式**：`使用 [技能名] 来 [具体目的]`

**示例**：
| 场景 | 宣告 |
|------|------|
| 遇到测试失败 | "使用 `systematic-debugging` 来定位测试失败的根因" |
| 开始新功能 | "使用 `test-driven-development` 来实现用户认证" |
| 收到审查反馈 | "使用 `receiving-code-review` 来处理审查反馈" |
| 功能完成收尾 | "使用 `finishing-a-feature` 来完成分支收尾" |

> 宣告的目的是透明度 — 让用户知道 AI 正在使用哪个技能指导行为。
```

**验证**:
- [ ] 搜索 `宣告格式规范` 确认已添加
- [ ] 确认包含至少 4 个示例

---

### Task 11: 增强 load.md — 计划完成度百分比

**文件**: `plugins/compound-engineering/commands/workflows/load.md:110`
**操作**:
- [ ] 增强现有 Handoff 中的计划检测逻辑（约 110 行附近），添加完成度计算

**代码**:

在现有的 `### Handoff` 中，增强计划检测逻辑：

```markdown
### 计划完成度检测

恢复上下文后，自动扫描未完成的计划：

```bash
# 扫描 30 天内修改的计划文件
find docs/plans/ -name "*.md" -mtime -30 2>/dev/null
```

对每个文件计算完成度：
```bash
total=$(grep -c '^\- \[' "$plan_file")
done=$(grep -c '^\- \[x\]' "$plan_file")
percent=$((done * 100 / total))
```

**在 Handoff 选项中展示**：
> "发现未完成计划：`<plan_path>`（完成度 XX%，Y/Z 项已完成）"

**显示规则**：
- 仅显示完成度 < 100% 且 30 天内有修改的计划
- 多个计划时按修改时间倒序，最多显示 3 个
- 完成度 100% 的计划不显示
```

**验证**:
- [ ] 搜索 `计划完成度检测` 确认已添加
- [ ] 确认包含 30 天窗口和百分比计算

---

### Task 12: 更新版本号和 CHANGELOG

**文件**: `.claude-plugin/marketplace.json`, `plugins/compound-engineering/.claude-plugin/plugin.json`, `plugins/compound-engineering/CHANGELOG.md`
**操作**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch` 更新版本号
- [ ] 在 CHANGELOG.md 添加版本记录

**代码**:
```markdown
## [2.44.2] - 2026-03-11

### Changed
- 增强 `systematic-debugging` skill：添加"无根因"分支、协作者信号解读表、跨技能引用闭环
- 增强 `git-worktree` skill：添加目录选择优先级协议、多语言依赖安装提醒
- 增强 `workflows:work`：Subagent 模式添加上下文预注入、失败任务处理、全局最终审查
- 增强 plugin `CLAUDE.md`：添加 Rigid/Flexible 技能分类、宣告格式规范
- 增强 `workflows:load`：Handoff 添加计划完成度百分比显示

### Source
- 精华内容来源：[obra/superpowers](https://github.com/obra/superpowers) Wave 4
- 对比分析：docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md

### Summary
- 29 agents, 43 commands, 26 skills, 1 MCP server
```

**验证**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] CHANGELOG.md 包含 2.44.2 版本条目

---

### Task 13: 最终验证

**操作**:
- [ ] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏
- [ ] 逐一检查每个修改的文件，确认新增内容格式正确
- [ ] 确认 5 个文件的新增内容都在 20-40 行范围内

**验证**:
- [ ] check-handoff.sh 全部 PASS
- [ ] check-versions.ps1 版本一致
- [ ] 无格式错误

---

## References

- **Brainstorm**: `docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md`（Wave 4 定义）
- **Wave 1-3 实现**: `docs/solutions/integration-issues/superpowers-fusion-code-review-2026-03-11.md`
- **架构深度分析**: `docs/solutions/integration-issues/superpowers-architecture-deep-dive-2026-03-11.md`
- **Superpowers 仓库**: https://github.com/obra/superpowers
