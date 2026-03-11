---
title: "Superpowers 插件精华融合代码审查整合"
category: integration-issues
tags: [superpowers, code-review, skill-fusion, verification, workflow-enhancement, upstream-integration]
date_created: "2026-03-11"
status: implemented
severity: medium
module: plugin-integration
symptoms:
  - "需要将 obra/superpowers 插件的精华融合到 CE"
  - "代码审查流程需要增强验证机制"
  - "功能完成后缺少标准化收尾流程"
  - "审查反馈响应缺少结构化协议"
root_cause: "CE 功能强大但体验细节不如 SP，需要选择性融合 SP 的工程方法论精华"
resolution_type: feature_enhancement
---

# Superpowers 插件精华融合代码审查整合

## Problem Statement

Compound Engineering (CE) 插件功能覆盖广泛（29 agents, 43 commands, 29 skills），但在工程方法论的细节体验上不如 obra/superpowers (SP) 插件。具体表现为：

1. **验证不完整**：功能完成后缺少强制验证机制，容易出现"虚假完成声明"
2. **收尾流程缺失**：功能开发完成后没有标准化的分支收尾流程（测试→合并/PR→清理）
3. **审查响应无规范**：接收代码审查反馈时缺少结构化响应协议，容易出现"表演性同意"
4. **工作流细节粗糙**：TDD、brainstorming、plan/work 等核心流程缺少关键细节

## Symptoms

### 1. 验证前的虚假完成声明
- Agent 报告"任务完成"但未运行验证命令
- 使用"应该"、"可能"、"似乎"等不确定词汇
- 准备提交/推送但没有新鲜的测试证据

### 2. 功能完成后的混乱状态
- 不知道是应该本地合并还是创建 PR
- Worktree 清理时机不明确
- 缺少二次测试验证

### 3. 审查反馈的表演性响应
- 收到反馈后立即回复"你说得对！"
- 未验证建议的技术正确性就实施
- 忽略 YAGNI 原则，实施未使用的功能

### 4. 工作流执行中的卡壳
- TDD 遇到复杂测试时不知如何简化
- Brainstorming 时一次提 5 个问题
- Plan 缺少 Goal/Tech Stack 等关键信息

## Root Cause Analysis

### 架构层面
CE 的设计哲学是"功能覆盖优先"，通过大量 agents/commands/skills 覆盖各种场景。但在单个流程的细节打磨上投入不足。

SP 的设计哲学是"工程方法论优先"，每个 skill 都经过 TDD 验证（观察 agent 在没有 skill 时失败），细节更扎实。

### 对比评分

| 维度 | CE | SP | 差距 |
|------|:---:|:---:|:---:|
| 架构设计 | 8/10 | 7/10 | CE +1 |
| 能力覆盖 | 9/10 | 6/10 | CE +3 |
| 工作流成熟度 | 9/10 | 8/10 | CE +1 |
| 可维护性 | 7/10 | 8/10 | SP +1 |
| 上手难度 | 6/10 | 8/10 | SP +2 |
| 功能发现性 | 5/10 | 9/10 | SP +4 |
| 认知负担 | 4/10 | 8/10 | SP +4 |
| 反馈循环 | 8/10 | 9/10 | SP +1 |

**结论**：CE 功能更强，SP 体验更好。

### 具体缺失

1. **验证门控函数**：CLAUDE.md 中缺少"完成前验证"的 5 步协议
2. **分支收尾 Skill**：没有独立的 `finishing-a-feature` skill
3. **审查响应 Skill**：没有 `receiving-code-review` skill 规范响应模式
4. **TDD 卡壳指南**：`test-driven-development` skill 缺少"当卡住时"表格
5. **Brainstorming 反模式**：`brainstorming` skill 缺少提问技术和反模式表
6. **Skill 开发 TDD**：`create-agent-skills` skill 缺少 TDD for Skills 框架
7. **Work STOP 协议**：`workflows:work` 缺少明确的停止执行条件
8. **Plan Header 模板**：`workflows:plan` 缺少强制的 Goal/Tech Stack 模板

## Solution

### 整体策略：3 波渐进式融合

采用 3 波独立提交的方式，每波可独立回滚：

- **Wave 1**：新增 2 个 Skill + 增强 CLAUDE.md（核心验证机制）
- **Wave 2**：增强 4 个文档（TDD、brainstorming、create-agent-skills、work/plan）
- **Wave 3**：收尾验证（版本号、CHANGELOG、集成测试）

### Wave 1：核心验证机制

#### 1. 新增 `finishing-a-feature` Skill

**文件位置**：`plugins/compound-engineering/skills/finishing-a-feature/SKILL.md`

**核心价值**：标准化功能完成后的收尾流程，避免混乱状态。

**5 步流程**：
1. **验证测试**：运行完整测试套件，有失败则停止
2. **确认基础分支**：`git merge-base --fork-point main HEAD`
3. **呈现 4 个选项**：本地合并 / 推送创建 PR / 保留现状 / 丢弃
4. **执行选择**：本地合并时必须二次测试
5. **清理 Worktree**：仅在合并和丢弃时清理

**关键设计**：
- 使用 `AskUserQuestion` 呈现选项，避免假设用户意图
- 本地合并时强制二次测试（合并后可能引入冲突）
- 丢弃时要求输入 `discard` 确认，防止误操作

#### 2. 新增 `receiving-code-review` Skill

**文件位置**：`plugins/compound-engineering/skills/receiving-code-review/SKILL.md`

**核心价值**：规范审查反馈响应，防止表演性同意和盲目实施。

**6 步响应模式**：
```
1. READ: 完整阅读所有反馈，不要立即反应
2. UNDERSTAND: 用自己的话重述需求（或提问）
3. VERIFY: 对照代码库实际情况验证
4. EVALUATE: 对当前代码库是否技术正确？
5. RESPOND: 技术性确认或有理有据的推回
6. IMPLEMENT: 逐项修复，每项单独测试
```

**禁止的响应**：
- ❌ "你说得对！"（表演性同意）
- ❌ "好建议！"（表演性赞美）
- ❌ "我马上实施"（验证前）

**何时推回**：
- 建议会破坏现有功能
- 审查者缺少完整上下文
- 违反 YAGNI（未使用的功能）
- 对当前技术栈不正确

**YAGNI 检查示例**：
```bash
# 审查者建议"正确实施"某功能时
grep -r "function_name" . --include="*.rb"

IF 未使用: "此端点未被调用。删除它（YAGNI）？"
IF 使用: 则正确实施
```

#### 3. 增强根目录 CLAUDE.md

**添加位置**：在"执行戒律"章节后

**新增内容**：完成前验证（铁律）

**5 步门控函数**：
```
1. 识别：什么命令能证明这个声明？
2. 运行：执行完整命令（新鲜的，完整的）
3. 阅读：完整输出，检查退出码，统计失败数
4. 验证：输出是否确认声明？
5. 然后才能：做出声明
```

**验证模式**：
- **Agent 委派验证**：Agent 报告成功 → 检查 VCS diff → 验证变更内容 → 报告实际状态
- **TDD 红绿循环验证**：写测试 → 运行（通过）→ 撤销修复 → 运行（必须失败）→ 恢复 → 运行（通过）

**危险信号**：
- 使用"应该"、"可能"、"似乎"
- 在验证前表达满意
- 准备提交/推送/PR 但没验证

### Wave 2：工作流细节增强

#### 4. 增强 `test-driven-development` Skill

**添加内容**：

**"当卡住时"表格**：
| 问题 | 解决方案 |
|------|---------|
| 不知道怎么测试 | 写理想 API。先写断言。问协作者。 |
| 测试太复杂 | 设计太复杂。简化接口。 |
| 必须 mock 所有东西 | 代码耦合太紧。使用依赖注入。 |
| 测试 setup 太庞大 | 提取辅助函数。还是复杂？简化设计。 |

**2 条危险信号**：
- "TDD 是教条主义，我在务实"
- "这个情况不一样..."

#### 5. 增强 `brainstorming` Skill

**添加内容**：

**提问技术**：
1. **多选优先**：当存在自然选项时，使用 AskUserQuestion 提供多选
2. **先宽后窄**：从目的和用户开始，逐渐收窄到约束和边缘案例
3. **显式验证假设**：不要隐含假设，说出来让用户确认或纠正
4. **早问成功标准**：尽早确定"什么算完成"

**反模式表格**：
| 反模式 | 正确做法 |
|--------|---------|
| 一次提 5 个问题 | 一次一个，等待回答 |
| 跳到实现细节 | 保持在 WHAT 层面，HOW 留给 plan |
| 忽视现有代码库模式 | 先 repo 研究，再提问 |
| 不验证假设 | 显式说出假设让用户确认 |
| 过早收敛 | 保持开放直到用户说 "proceed" |
| 遗漏成功标准 | 第一轮就问"什么算完成" |

#### 6. 增强 `create-agent-skills` Skill

**添加内容**：TDD for Skills（铁律）

**核心原则**：
> 如果你没有观察到 Agent 在没有该 Skill 时失败，你就不知道 Skill 教的是对的。

**RED-GREEN-REFACTOR 循环**：
| TDD 概念 | Skill 创建 |
|----------|-----------|
| 测试用例 | 子代理压力场景 |
| 生产代码 | SKILL.md 文档 |
| 测试失败（RED） | Agent 在没有 Skill 时违反规则 |
| 测试通过（GREEN） | Agent 在有 Skill 时遵守规则 |
| 重构 | 关闭漏洞，保持合规 |

**铁律**：
```
没有失败测试，就没有新 Skill
```

**Description 优化**：
- ✅ 好：`Use when executing implementation plans with independent tasks`
- ❌ 差：`Dispatches subagent per task with code review between tasks`

关键：Description = 何时使用，不是做什么。

#### 7. 增强 `workflows:work` 命令

**添加内容**：

**STOP 协议**：
以下情况立即停止执行当前批次：
- 遇到阻塞（缺少依赖、测试失败、指令不清晰）
- 计划有关键缺陷无法继续
- 不理解某个指令
- 验证反复失败（同一步骤失败 3 次）

**停止后**：报告实际状态 + 已完成的工作 + 阻塞原因，使用 AskUserQuestion 询问下一步。

**finishing-a-feature 引用**（在 Phase 4 Step 1）：
```markdown
> **REQUIRED SUB-SKILL**: 使用 `finishing-a-feature` skill 完成分支收尾。
```

#### 8. 增强 `workflows:plan` 命令

**添加内容**：Plan Header 强制模板

**每个计划必须以此 Header 开头**：
```markdown
## Overview

**Goal**: [一句话描述要构建什么]
**Tech Stack**: [关键技术/库]
**Architecture** (可选): [2-3 句话描述方法]
```

### Wave 3：收尾验证

#### 9. 更新版本号和 CHANGELOG

**版本号**：2.43.0 → 2.44.0（minor bump）

**CHANGELOG 内容**：
```markdown
## [2.44.0] - 2026-03-11

### Added
- 新增 `finishing-a-feature` skill：功能分支收尾闭环（测试→合并/PR→清理）
- 新增 `receiving-code-review` skill：接收审查响应规范（6步协议 + 禁止表演性同意）
- 增强根目录 CLAUDE.md：补充 Agent 委派验证和 TDD 红绿循环验证模式

### Changed
- 增强 `test-driven-development` skill：添加"当卡住时"表格、2 条危险信号
- 增强 `brainstorming` skill：添加提问技术、反模式表
- 增强 `create-agent-skills` skill：添加 TDD for Skills 框架、Description 优化
- 增强 `workflows:work`：添加 STOP 协议、finishing-a-feature 引用
- 增强 `workflows:plan`：添加 Plan Header 强制模板（Goal + Tech Stack 必填）

### Source
- 精华内容来源：[obra/superpowers](https://github.com/obra/superpowers) v4.1.1
- 对比分析：docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md
- 审查优化：应用 Kieran、代码简洁性、DHH 三位专家的一致建议
```

#### 10. 集成测试清单

- [ ] 重启 Claude Code，确认插件加载无错误
- [ ] 运行 `/skills` 命令，确认 26 个 skills 全部显示
- [ ] 在 CLAUDE.md 中搜索新增的 2 个技能，确认映射表正确
- [ ] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致

## Prevention Strategies

### 1. 渐进式融合原则

**规则**：每波独立提交，方便回滚。

**实施**：
- Wave 1：核心验证机制（2 个 Skill + CLAUDE.md）
- Wave 2：工作流细节（4 个文档增强）
- Wave 3：收尾验证（版本号 + 测试）

**验证**：每波提交后运行集成测试，确认无回归。

### 2. TDD for Skills 框架

**规则**：没有失败测试，就没有新 Skill。

**实施**：
1. 观察 Agent 在没有 Skill 时违反规则（RED）
2. 编写 SKILL.md 文档（GREEN）
3. 验证 Agent 在有 Skill 时遵守规则
4. 关闭漏洞，保持合规（REFACTOR）

**验证**：每个新 Skill 必须有对应的"失败场景"记录。

### 3. 验证门控函数

**规则**：声明任何工作完成前，必须有新鲜的验证证据。

**实施**：
1. 识别：什么命令能证明这个声明？
2. 运行：执行完整命令（新鲜的，完整的）
3. 阅读：完整输出，检查退出码，统计失败数
4. 验证：输出是否确认声明？
5. 然后才能：做出声明

**验证**：在 CLAUDE.md 中强制要求，所有 Agent 自动继承。

### 4. 审查响应 6 步协议

**规则**：验证后再实施，提问后再假设。

**实施**：
1. READ：完整阅读所有反馈
2. UNDERSTAND：用自己的话重述需求
3. VERIFY：对照代码库实际情况验证
4. EVALUATE：对当前代码库是否技术正确？
5. RESPOND：技术性确认或有理有据的推回
6. IMPLEMENT：逐项修复，每项单独测试

**验证**：在 `receiving-code-review` skill 中强制要求。

### 5. Rollback Plan

**Wave 1 回滚**：
```bash
git revert <Wave 1 commit hash>
rm -rf plugins/compound-engineering/skills/finishing-a-feature
rm -rf plugins/compound-engineering/skills/receiving-code-review
git checkout HEAD~1 CLAUDE.md plugins/compound-engineering/CLAUDE.md
```

**Wave 2-3 回滚**：
```bash
git revert <commit hash>
```

**完全回滚**：
```bash
git reset --hard <Wave 1 前的 commit>
```

## Related Documentation

### 项目内文档
- **Brainstorm**：`docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md`
- **Plan**：`docs/plans/2026-03-11-feat-superpowers-fusion-plan.md`
- **Review Summary**：`docs/plans/2026-03-11-review-changes-summary.md`
- **上游合并策略**：`UPSTREAM-MERGE-RECOMMENDATION.md`

### 相关解决方案
- **上游同步工作流**：`docs/solutions/integration-issues/upstream-sync-integration-workflow.md`
- **Subagent-Driven 工作流整合**：`docs/solutions/integration-issues/subagent-driven-workflow-integration.md`
- **Claude Code 运行时更新决策**：`docs/solutions/integration-issues/claude-code-runtime-updates-decisions-2026-02.md`

### 外部参考
- **Superpowers 仓库**：https://github.com/obra/superpowers
- **Superpowers 本地路径**：`F:\StudyFolder\StudyDest\project\Dev_tools\superpowers\`

## Verification

### 验证清单

#### Wave 1 验证
- [ ] `finishing-a-feature` skill YAML frontmatter 合规
- [ ] `receiving-code-review` skill YAML frontmatter 合规
- [ ] 根目录 CLAUDE.md 搜索"完成前验证"确认已添加
- [ ] `plugins/compound-engineering/CLAUDE.md` 搜索新增的 2 个技能确认映射表正确
- [ ] 运行 `grep -E '^\`(references|assets)/[^\`]+\`' plugins/compound-engineering/skills/finishing-a-feature/SKILL.md` 确认无裸引用
- [ ] `git log -1` 确认提交成功
- [ ] `ls plugins/compound-engineering/skills/ | wc -l` 确认技能数 = 26

#### Wave 2 验证
- [ ] `test-driven-development` skill 搜索"当卡住时"确认已添加
- [ ] `brainstorming` skill 搜索"提问技术"和"反模式"确认已添加
- [ ] `create-agent-skills` skill 搜索"TDD for Skills"确认已添加
- [ ] `workflows:work` 搜索"STOP 协议"和"finishing-a-feature"确认已添加
- [ ] `workflows:plan` 搜索"Goal"、"Tech Stack"确认 Header 已添加
- [ ] 运行 `bash scripts/check-handoff.sh` 确认 Handoff 协议未破坏
- [ ] `git log -1` 确认提交成功

#### Wave 3 验证
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] 确认 `marketplace.json` 和 `plugin.json` 的 skills 数量 = 26
- [ ] 确认 CHANGELOG 格式正确
- [ ] 重启 Claude Code，确认插件加载无错误
- [ ] 运行 `/skills` 命令，确认 26 个 skills 全部显示
- [ ] `ls -d plugins/compound-engineering/skills/*/ | wc -l` 确认目录数 = 26
- [ ] `git log -1` 确认提交成功

### 验证命令

```bash
# 检查版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 检查 Handoff 协议
bash scripts/check-handoff.sh

# 统计 Skills 数量
ls -d plugins/compound-engineering/skills/*/ | wc -l

# 检查裸引用
grep -E '^\`(references|assets)/[^\`]+\`' plugins/compound-engineering/skills/finishing-a-feature/SKILL.md
grep -E '^\`(references|assets)/[^\`]+\`' plugins/compound-engineering/skills/receiving-code-review/SKILL.md

# 查看最新提交
git log -1

# 查看版本号
(Get-Content .claude-plugin/marketplace.json | ConvertFrom-Json).plugins[0].version
(Get-Content plugins/compound-engineering/.claude-plugin/plugin.json | ConvertFrom-Json).version
```

## Key Learnings

### 1. 功能覆盖 vs 体验细节

**教训**：功能多不等于体验好。CE 有 29 agents、43 commands、29 skills，但在单个流程的细节打磨上不如 SP。

**应用**：未来新增功能时，不仅要考虑"能做什么"，更要考虑"用起来爽不爽"。

### 2. TDD for Skills 框架

**教训**：编写 Skill 就是将 TDD 应用于流程文档。没有观察到 Agent 在没有 Skill 时失败，就不知道 Skill 教的是对的。

**应用**：每个新 Skill 必须有对应的"失败场景"记录，确保 Skill 真正解决了问题。

### 3. 验证门控函数

**教训**：Agent 容易出现"虚假完成声明"，使用"应该"、"可能"、"似乎"等不确定词汇。

**应用**：在 CLAUDE.md 中强制要求 5 步验证门控函数，所有 Agent 自动继承。

### 4. 渐进式融合策略

**教训**：一次性大规模融合风险高，难以定位问题。历史上 SessionStart hook 融合曾引发 Windows 回归。

**应用**：采用 3 波独立提交，每波可独立回滚，降低风险。

### 5. 审查响应的表演性同意

**教训**：Agent 收到审查反馈后容易立即回复"你说得对！"，未验证建议的技术正确性就实施。

**应用**：在 `receiving-code-review` skill 中强制要求 6 步响应协议，禁止表演性同意。

### 6. YAGNI 原则的执行

**教训**：审查者可能建议"正确实施"某功能，但该功能可能未被使用。

**应用**：在 `receiving-code-review` skill 中添加 YAGNI 检查示例，先 grep 确认是否使用。

### 7. Description 的正确写法

**教训**：当 description 总结工作流时，Claude 可能只读 description 而不读完整内容。

**应用**：Description = 何时使用，不是做什么。例如：
- ✅ 好：`Use when executing implementation plans with independent tasks`
- ❌ 差：`Dispatches subagent per task with code review between tasks`

## Risk Analysis

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 安全/隐私 | 0 | 无敏感数据 |
| 可逆性 | 0 | 全部 Markdown/配置文件 |
| 影响范围 | 0 | 个人项目 |
| 变更规模 | 1 | ~10 文件 |
| 外部依赖 | 0 | 无 |
| **总分** | **1/10** | **低风险 🟢** |

## Implementation Status

### Wave 1（已完成）
- [x] 创建 `finishing-a-feature` skill
- [x] 创建 `receiving-code-review` skill
- [x] 增强根目录 CLAUDE.md
- [x] 更新 plugin CLAUDE.md 技能映射表
- [x] Wave 1 提交

### Wave 2（已完成）
- [x] 增强 `test-driven-development` skill
- [x] 增强 `brainstorming` skill
- [x] 增强 `create-agent-skills` skill
- [x] 增强 `workflows:work` 命令
- [x] 增强 `workflows:plan` 命令
- [x] Wave 2 提交

### Wave 3（已完成）
- [x] 更新版本号和 CHANGELOG
- [x] 集成测试
- [x] 更新组件统计
- [x] Wave 3 最终提交

## Metrics

### 简化版 vs 原计划对比

| 维度 | 简化版 | 原计划 | 改善 |
|------|:-----:|:-----:|:---:|
| 新增 Skill 数 | 2 | 3 | -33% |
| 任务数 | 14 | 17 | -18% |
| 预计行数 | 350 | 898 | -61% |
| 维护成本评分 | 7.5/10 | 6/10 | +25% |
| 审查建议应用 | 100% | 0% | — |

### 审查专家建议应用

基于 Kieran、代码简洁性、DHH 三位专家的一致建议：
- [x] 删除 `verification-before-completion` skill（已融合到 CLAUDE.md）
- [x] 删除协作者信号表（过度工程）
- [x] 补充集成测试清单
- [x] 补充版本号更新步骤
- [x] 补充 Handoff 验证
- [x] 添加 Rollback Plan
