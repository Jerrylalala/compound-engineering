---
title: "feat: Superpowers 插件精华融合到 CE（简化版）"
type: feat
date: 2026-03-11
risk_score: 1
risk_level: low
risk_note: "纯 Markdown/配置文件修改，完全可逆，无外部依赖"
brainstorm: docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md
review_applied: true
review_summary: "应用三位专家审查建议：删除 verification-before-completion skill、删除协作者信号表、补充集成测试、补充版本号更新、补充 Handoff 验证、添加 Rollback Plan"
---

# Superpowers 插件精华选择性融合到 CE（简化版）

## Overview

**Goal**: 将 [obra/superpowers](https://github.com/obra/superpowers) v4.1.1 的核心价值融合到 CE，提升工作流完整性和验证严格性。

**Architecture**: 3 波渐进式融合 — Wave 1 新增 2 个 Skill + Wave 2 增强 4 个文档 + Wave 3 收尾验证。每波独立提交，方便回滚。

**Tech Stack**: 纯 Markdown 文件编写/修改 + YAML frontmatter + PowerShell 版本脚本。

**审查应用**: 基于 Kieran、代码简洁性、DHH 三位专家的一致建议优化。

---

## Wave 1：新增 2 个 Skill + 增强 CLAUDE.md

### Task 1: 创建 finishing-a-feature skill（简化版）

**文件**: `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md`

**YAML frontmatter**:
```yaml
---
name: finishing-a-feature
description: >
  This skill should be used when a feature implementation is complete and the development branch
  needs to be finalized. It guides through test verification, merge/PR decision, and worktree
  cleanup with a structured 5-step process.
disable-model-invocation: true
---
```

**SKILL.md 内容（50 行简化版）**:
```markdown
# 完成功能分支

> **铁律**：没有通过测试，就没有合并资格。

## 何时使用

- `/workflows:work` 执行完成后
- Subagent-Driven 模式所有任务完成后
- 准备合并或创建 PR 时

## 流程

### Step 1: 验证测试
运行完整测试套件。有失败则停止。

### Step 2: 确认基础分支
```bash
git merge-base --fork-point main HEAD
```

### Step 3: 呈现 4 个选项

使用 **AskUserQuestion** 呈现：
1. **本地合并** — 切换基础分支 → pull → merge → 再次测试 → 删除特性分支
2. **推送创建 PR** — `git push -u origin` → `gh pr create`
3. **保留现状** — 报告路径，不清理
4. **丢弃** — 要求输入 `discard` 确认

### Step 4: 执行选择
按用户选择执行。本地合并时必须二次测试。

### Step 5: 清理 Worktree
仅在合并和丢弃时清理。

## 快速参考

| 操作 | 测试 | 推送 | 删除分支 | 清理 worktree |
|------|:---:|:---:|:---:|:---:|
| 合并 | ✅ | ❌ | ✅ | ✅ |
| PR | ✅ | ✅ | ❌ | ❌ |
| 保留 | ✅ | ❌ | ❌ | ❌ |
| 丢弃 | ❌ | ❌ | ✅ | ✅ |

## 关联技能
- 前置：`/workflows:work`
- 后续：`/workflows:review`（如选择 PR）
```

**验证**:
- [x] 确认 YAML frontmatter 合规
- [x] 确认 description 使用第三人称
- [x] 运行 `grep -E '^\`(references|assets)/[^\`]+\`' plugins/compound-engineering/skills/finishing-a-feature/SKILL.md` 确认无裸引用

---

### Task 2: 创建 receiving-code-review skill

**文件**: `plugins/compound-engineering/skills/receiving-code-review/SKILL.md`

**YAML frontmatter**:
```yaml
---
name: receiving-code-review
description: >
  This skill should be used when processing code review feedback from agents, external tools
  (Codex/Gemini), or human reviewers. It enforces verification before implementation,
  prevents performative agreement, and provides structured response patterns.
disable-model-invocation: true
---
```

**SKILL.md 内容（120 行）**:
```markdown
# 接收代码审查

> **核心原则**：验证后再实施。提问后再假设。技术正确优先于社交舒适。

## 响应模式（6 步）

```
1. READ: 完整阅读所有反馈，不要立即反应
2. UNDERSTAND: 用自己的话重述需求（或提问）
3. VERIFY: 对照代码库实际情况验证
4. EVALUATE: 对当前代码库是否技术正确？
5. RESPOND: 技术性确认或有理有据的推回
6. IMPLEMENT: 逐项修复，每项单独测试
```

## 禁止的响应

- ❌ 「你说得对！」（表演性同意）
- ❌ 「好建议！」「精彩的反馈！」（表演性赞美）
- ❌ 「我马上实施」（验证前）

## 正确的响应

- ✅ 「已修复。[简述改动]」
- ✅ 「发现问题 — [具体问题]。已在 [位置] 修复。」
- ✅ [直接修复并在代码中展示]

## 处理不清晰的反馈

```
IF 任何项不清楚:
  STOP — 不要实施任何内容
  ASK 澄清不清楚的项

WHY: 各项可能相关。部分理解 = 错误实施。
```

## 何时推回

- 建议会破坏现有功能
- 审查者缺少完整上下文
- 违反 YAGNI（未使用的功能）
- 对当前技术栈不正确
- 存在遗留/兼容性原因
- 与用户的架构决策冲突

## YAGNI 检查

```bash
# 审查者建议「正确实施」某功能时
grep -r "function_name" . --include="*.rb"

IF 未使用: "此端点未被调用。删除它（YAGNI）？"
IF 使用: 则正确实施
```

## 实施顺序

多项反馈时：
1. 先澄清所有不清楚的项
2. 按顺序实施：
   - 阻塞性问题（崩溃、安全）
   - 简单修复（拼写、导入）
   - 复杂修复（重构、逻辑）
3. 每项单独测试
4. 验证无回归

## 外部审查（Codex / Gemini）

外部工具的建议需要额外验证：
1. 对当前代码库技术正确吗？
2. 会破坏现有功能吗？
3. 当前实现的原因是什么？
4. 在所有平台/版本上都有效吗？
5. 审查者理解完整上下文吗？

**外部建议 = 需要评估的建议，而非必须执行的命令。**

## 关联技能

- 前置：`/workflows:review` 产出审查发现
- 关联：`spec-compliance-review`（规范合规检查）
```

**验证**:
- [x] 确认 YAML frontmatter 合规
- [x] 确认覆盖 6 步响应模式和推回机制

---

### Task 3: 增强根目录 CLAUDE.md 验证章节

**文件**: `CLAUDE.md`（项目根目录）

**操作**: 在「执行戒律」章节后添加「完成前验证」章节

**要添加的内容**:
```markdown
## 完成前验证（铁律）

> 声明任何工作完成前，必须有新鲜的验证证据。

### 门控函数（5 步）

```
1. 识别：什么命令能证明这个声明？
2. 运行：执行完整命令（新鲜的，完整的）
3. 阅读：完整输出，检查退出码，统计失败数
4. 验证：输出是否确认声明？
5. 然后才能：做出声明
```

### 验证模式

**Agent 委派验证**：
```
Agent 报告成功 → 检查 VCS diff → 验证变更内容 → 报告实际状态
```

**TDD 红绿循环验证**：
```
写测试 → 运行（通过）→ 撤销修复 → 运行（必须失败）→ 恢复 → 运行（通过）
```

### 危险信号

- 使用「应该」「可能」「似乎」
- 在验证前表达满意
- 准备提交/推送/PR 但没验证
```

**验证**:
- [x] 搜索「完成前验证」确认已添加
- [x] 确认内容与原 CLAUDE.md 风格一致

---

### Task 4: 更新 plugin CLAUDE.md 技能映射表

**文件**: `plugins/compound-engineering/CLAUDE.md`

**操作**: 在「可用技能（按场景）」表格中添加 2 个新技能

**要添加的行**:
```markdown
| 任务完成后收尾 | finishing-a-feature | 测试验证 → 合并/PR 决策 → worktree 清理 |
| 收到审查反馈 | receiving-code-review | 6 步响应 + 禁止表演性同意 + YAGNI 检查 |
```

**验证**:
- [x] 在 CLAUDE.md 中搜索新增行确认已添加

---

### Task 5: Wave 1 提交

**操作**:
- [x] `git add plugins/compound-engineering/skills/finishing-a-feature/ plugins/compound-engineering/skills/receiving-code-review/`
- [x] `git add CLAUDE.md plugins/compound-engineering/CLAUDE.md`
- [x] 提交消息：`Add 2 skills from superpowers fusion (Wave 1): finishing-a-feature, receiving-code-review + enhance CLAUDE.md verification`

**验证**:
- [x] `git log -1` 确认提交成功
- [x] `ls plugins/compound-engineering/skills/ | wc -l` 确认技能数 = 26

---

## Wave 2：增强 4 个文档

### Task 6: 增强 TDD skill

**文件**: `plugins/compound-engineering/skills/test-driven-development/SKILL.md`

**操作**: 添加「当卡住时」表格 + 2 条危险信号

**要添加的「当卡住时」表格**:
```markdown
## 当卡住时

| 问题 | 解决方案 |
|------|---------|
| 不知道怎么测试 | 写理想 API。先写断言。问协作者。 |
| 测试太复杂 | 设计太复杂。简化接口。 |
| 必须 mock 所有东西 | 代码耦合太紧。使用依赖注入。 |
| 测试 setup 太庞大 | 提取辅助函数。还是复杂？简化设计。 |
```

**要补充的 2 条危险信号**:
```markdown
- 「TDD 是教条主义，我在务实」
- 「这个情况不一样...」
```

**验证**:
- [x] 搜索「当卡住时」确认已添加

---

### Task 7: 增强 brainstorming skill

**文件**: `plugins/compound-engineering/skills/brainstorming/SKILL.md`

**操作**: 添加「提问技术」章节 + 「反模式」表格

**要添加的「提问技术」章节**:
```markdown
## 提问技术

1. **多选优先** — 当存在自然选项时，使用 AskUserQuestion 提供多选
2. **先宽后窄** — 从目的和用户开始，逐渐收窄到约束和边缘案例
3. **显式验证假设** — 不要隐含假设，说出来让用户确认或纠正
4. **早问成功标准** — 尽早确定「什么算完成」
```

**要添加的「反模式」表格**:
```markdown
## 反模式

| 反模式 | 正确做法 |
|--------|---------|
| 一次提 5 个问题 | 一次一个，等待回答 |
| 跳到实现细节 | 保持在 WHAT 层面，HOW 留给 plan |
| 忽视现有代码库模式 | 先 repo 研究，再提问 |
| 不验证假设 | 显式说出假设让用户确认 |
| 过早收敛 | 保持开放直到用户说 "proceed" |
| 遗漏成功标准 | 第一轮就问「什么算完成」 |
```

**验证**:
- [x] 搜索「提问技术」和「反模式」确认已添加

---

### Task 8: 增强 create-agent-skills skill

**文件**: `plugins/compound-engineering/skills/create-agent-skills/SKILL.md`

**操作**: 添加「TDD for Skills」章节

**要添加的内容**:
```markdown
## TDD for Skills（铁律）

> **编写 Skill 就是将 TDD 应用于流程文档。**

### 核心原则

如果你没有观察到 Agent 在没有该 Skill 时失败，你就不知道 Skill 教的是对的。

### RED-GREEN-REFACTOR 循环

| TDD 概念 | Skill 创建 |
|----------|-----------|
| 测试用例 | 子代理压力场景 |
| 生产代码 | SKILL.md 文档 |
| 测试失败（RED） | Agent 在没有 Skill 时违反规则 |
| 测试通过（GREEN） | Agent 在有 Skill 时遵守规则 |
| 重构 | 关闭漏洞，保持合规 |

### 铁律

```
没有失败测试，就没有新 Skill
```

适用于新 Skill 和现有 Skill 的修改。无例外。

### Description 优化

**关键**：Description = 何时使用，不是做什么。

测试发现：当 description 总结工作流时，Claude 可能只读 description 而不读完整内容。

**正确示例**:
```yaml
# ✅ 好
description: Use when executing implementation plans with independent tasks

# ❌ 差
description: Dispatches subagent per task with code review between tasks
```
```

**验证**:
- [x] 搜索「TDD for Skills」确认已添加

---

### Task 9: 增强 work.md 和 plan.md

**文件 1**: `plugins/compound-engineering/commands/workflows/work.md`

**操作**: 添加 STOP 协议 + finishing-a-feature 引用

**要添加的 STOP 协议**:
```markdown
### STOP 协议

以下情况立即停止执行当前批次：
- 遇到阻塞（缺少依赖、测试失败、指令不清晰）
- 计划有关键缺陷无法继续
- 不理解某个指令
- 验证反复失败（同一步骤失败 3 次）

**停止后**：报告实际状态 + 已完成的工作 + 阻塞原因，使用 AskUserQuestion 询问下一步。
```

**要添加的 finishing-a-feature 引用**（在 Phase 4 Step 1）:
```markdown
> **REQUIRED SUB-SKILL**: 使用 `finishing-a-feature` skill 完成分支收尾。
```

**验证**:
- [x] 搜索「STOP 协议」确认已添加
- [x] 搜索「finishing-a-feature」确认引用已添加
- [x] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏

**文件 2**: `plugins/compound-engineering/commands/workflows/plan.md`

**操作**: 在 Section 5 的模板中添加 Plan Header

**要添加的 Plan Header**（在 MINIMAL/MORE/A LOT 三档共用部分）:
```markdown
> **每个计划必须以此 Header 开头**：

```markdown
## Overview

**Goal**: [一句话描述要构建什么]
**Tech Stack**: [关键技术/库]
**Architecture** (可选): [2-3 句话描述方法]
```
```

**验证**:
- [x] 搜索「Goal」「Tech Stack」确认 Header 已添加
- [x] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏

---

### Task 10: Wave 2 提交

**操作**:
- [ ] `git add plugins/compound-engineering/skills/test-driven-development/SKILL.md`
- [ ] `git add plugins/compound-engineering/skills/brainstorming/SKILL.md`
- [ ] `git add plugins/compound-engineering/skills/create-agent-skills/SKILL.md`
- [ ] `git add plugins/compound-engineering/commands/workflows/work.md`
- [ ] `git add plugins/compound-engineering/commands/workflows/plan.md`
- [ ] 提交消息：`Enhance 5 docs with superpowers insights (Wave 2): TDD, brainstorming, create-agent-skills, work.md, plan.md`

**验证**:
- [ ] `git log -1` 确认提交成功

---

## Wave 3：收尾验证

### Task 11: 更新版本号和 CHANGELOG

**文件**:
- `plugins/compound-engineering/CHANGELOG.md`
- `.claude-plugin/marketplace.json`
- `plugins/compound-engineering/.claude-plugin/plugin.json`

**操作**:
- [ ] 在 CHANGELOG.md 顶部添加新版本记录
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType minor` 更新版本号
- [ ] **手动更新** marketplace.json 和 plugin.json 中的 `skills` 数量（24 → 26）

**CHANGELOG 内容**:
```markdown
## [2.44.0] - 2026-03-11

### Added
- 新增 `finishing-a-feature` skill：功能分支收尾闭环（测试→合并/PR→清理）
- 新增 `receiving-code-review` skill：接收审查响应规范（6步协议 + 禁止表演性同意）
- 增强根目录 CLAUDE.md：补充 Agent 委派验证和 TDD 红绿循环验证模式

### Changed
- 增强 `test-driven-development` skill：添加「当卡住时」表格、2 条危险信号
- 增强 `brainstorming` skill：添加提问技术、反模式表
- 增强 `create-agent-skills` skill：添加 TDD for Skills 框架、Description 优化
- 增强 `workflows:work`：添加 STOP 协议、finishing-a-feature 引用
- 增强 `workflows:plan`：添加 Plan Header 强制模板（Goal + Tech Stack 必填）

### Source
- 精华内容来源：[obra/superpowers](https://github.com/obra/superpowers) v4.1.1
- 对比分析：docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md
- 审查优化：应用 Kieran、代码简洁性、DHH 三位专家的一致建议
```

**验证**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] 确认 marketplace.json 和 plugin.json 的 skills 数量 = 26
- [ ] 确认 CHANGELOG 格式正确

---

### Task 12: 集成测试

**操作**:
- [ ] 重启 Claude Code，确认插件加载无错误
- [ ] 运行 `/skills` 命令，确认 26 个 skills 全部显示
- [ ] 在 CLAUDE.md 中搜索新增的 2 个技能，确认映射表正确
- [ ] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏

**验证**:
- [ ] 插件加载无 YAML 解析错误
- [ ] 新 Skill 的 description 正确显示
- [ ] 技能映射表场景描述准确
- [ ] Handoff 协议检查通过

---

### Task 13: 更新组件统计

**文件**: `CLAUDE.md`（项目根目录）

**操作**: 更新组件统计表

```markdown
| Skills      | 26   | `plugins/compound-engineering/skills/`   |
```

**验证**:
- [ ] `ls -d plugins/compound-engineering/skills/*/ | wc -l` 确认目录数 = 26

---

### Task 14: Wave 3 最终提交

**操作**:
- [ ] `git add -A`（审查所有变更后）
- [ ] 提交消息：`Complete superpowers fusion (Wave 3): versioning, integration tests — v2.44.0`

**验证**:
- [ ] `git log -1` 确认提交成功
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] `ls -d plugins/compound-engineering/skills/*/ | wc -l` 确认 26 个 skills

---

## Rollback Plan

如果某波提交后发现问题：

### Wave 1 回滚
```bash
git revert <Wave 1 commit hash>
# 删除 2 个新 Skill 目录
rm -rf plugins/compound-engineering/skills/finishing-a-feature
rm -rf plugins/compound-engineering/skills/receiving-code-review
# 恢复 CLAUDE.md
git checkout HEAD~1 CLAUDE.md plugins/compound-engineering/CLAUDE.md
```

### Wave 2-3 回滚
```bash
git revert <commit hash>
```

### 完全回滚
```bash
git reset --hard <Wave 1 前的 commit>
```

---

## Risk Analysis

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 安全/隐私 | 0 | 无敏感数据 |
| 可逆性 | 0 | 全部 Markdown/配置文件 |
| 影响范围 | 0 | 个人项目 |
| 变更规模 | 1 | ~10 文件 |
| 外部依赖 | 0 | 无 |
| **总分** | **1/10** | **低风险 🟢** |

---

## 简化版 vs 原计划对比

| 维度 | 简化版 | 原计划 | 改善 |
|------|:-----:|:-----:|:---:|
| 新增 Skill 数 | 2 | 3 | -33% |
| 任务数 | 14 | 17 | -18% |
| 预计行数 | 350 | 898 | -61% |
| 维护成本评分 | 7.5/10 | 6/10 | +25% |
| 审查建议应用 | 100% | 0% | — |

---

## References

- (see brainstorm: docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md)
- 审查报告：三位专家一致建议（Kieran、代码简洁性、DHH）
- 审查摘要：docs/plans/2026-03-11-review-changes-summary.md
- SP 本地路径: `F:\StudyFolder\StudyDest\project\Dev_tools\superpowers\`
- [obra/superpowers GitHub](https://github.com/obra/superpowers)
- Skill 合规清单: `plugins/compound-engineering/CLAUDE.md`
