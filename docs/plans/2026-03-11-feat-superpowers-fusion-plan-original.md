---
title: "feat: Superpowers 插件精华融合到 CE"
type: feat
date: 2026-03-11
risk_score: 1
risk_level: low
risk_note: "纯 Markdown/配置文件修改，完全可逆，无外部依赖"
brainstorm: docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md
---

# Superpowers 插件精华选择性融合到 CE

## Overview

基于深度对比 12 项 Skill 的结果（see brainstorm: docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md），将 [obra/superpowers](https://github.com/obra/superpowers) v4.1.1 的精华内容选择性融合到 compound-engineering-plugin。

**核心原则**：SP 是只读参考，不引入依赖。CE 现有实现更好的部分保留不动。所有内容翻译为中文。

**SP 本地路径**：`F:\StudyFolder\StudyDest\project\Dev_tools\superpowers\`

## Architecture

4 波渐进式融合：Wave 1 新增 3 个 Skill → Wave 2 增强 3 个 Skill → Wave 3 增强 2 个命令 → Wave 4 收尾。每波独立提交，方便回滚。

## Tech Stack

纯 Markdown 文件编写/修改 + YAML frontmatter + PowerShell 版本脚本。

---

## 审查意见应用

**三位专家一致建议**：
1. ✅ 删除 `verification-before-completion` 独立 Skill（合并到 CLAUDE.md）
2. ✅ 删除「协作者信号解读」表（Task 13）
3. ✅ 补充集成测试（新增 Task 16.5）
4. ✅ 补充版本号更新（Task 15 增强）
5. ✅ 补充 Handoff 验证（Task 10-11 增强）
6. ✅ 添加 Rollback Plan

**调整后**：新增 2 个 Skill（原 3 个），16 个任务（原 17 个）

---

## Wave 1：新增 2 个 Skill（填补工作流空缺）

### Task 1: 创建 finishing-a-feature skill 目录结构

**文件**: `plugins/compound-engineering/skills/finishing-a-feature/SKILL.md`
**操作**:
- [ ] 创建目录 `plugins/compound-engineering/skills/finishing-a-feature/`
- [ ] 创建 SKILL.md，内容基于 SP 的 `finishing-a-development-branch` 适配 CE 工作流

**代码**:
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

**SKILL.md 核心内容（从 SP 适配，翻译为中文）**:

```markdown
# 完成功能分支

> **铁律**：没有通过测试，就没有合并资格。

## 何时使用

- `/workflows:work` 执行完成后
- Subagent-Driven 模式所有任务完成后
- 准备合并或创建 PR 时

## 流程

### Step 1: 验证测试

运行完整测试套件。有失败则停止，不进入后续步骤。

### Step 2: 确认基础分支

```bash
git merge-base --fork-point main HEAD
```

确定要合并回的目标分支。

### Step 3: 呈现 4 个选项

使用 **AskUserQuestion** 严格呈现以下选项（不添加额外解释）：

1. **本地合并** — 切换到基础分支 → pull → merge → 再次运行测试 → 删除特性分支
2. **推送创建 PR** — `git push -u origin` → `gh pr create`（含标准模板）
3. **保留现状** — 报告当前分支路径，不做清理
4. **丢弃** — 要求用户输入确切字符串 `discard` 确认后执行

### Step 4: 执行选择

按用户选择执行对应操作。

**本地合并时的二次验证**：merge 后必须再跑一次测试。

**丢弃操作的安全确认**：
```
如果用户选择丢弃：
  要求输入精确字符串 "discard"（非 y/n）
  匹配后才执行
```

### Step 5: 清理 Worktree

仅在选项 1（合并）和 4（丢弃）时清理 worktree。
选项 2（PR）和 3（保留）保持 worktree 不动。

## 快速参考

| 操作 | 合并 | PR | 保留 | 丢弃 |
|------|:---:|:---:|:---:|:---:|
| 运行测试 | ✅ | ✅ | ✅ | ❌ |
| 推送代码 | ❌ | ✅ | ❌ | ❌ |
| 删除分支 | ✅ | ❌ | ❌ | ✅ |
| 清理 worktree | ✅ | ❌ | ❌ | ✅ |

## 关联技能

- 前置：`/workflows:work` 或手动开发完成
- 后续：`/workflows:review`（如选择 PR）
```

**验证**:
- [ ] 确认 YAML frontmatter 的 `name` 匹配目录名
- [ ] 确认 `description` 使用第三人称
- [ ] 运行 `grep -E '^\`(references|assets)/[^\`]+\`' plugins/compound-engineering/skills/finishing-a-feature/SKILL.md` 确认无裸引用

---

### Task 2: 创建 verification-before-completion skill 目录结构

**文件**: `plugins/compound-engineering/skills/verification-before-completion/SKILL.md`
**操作**:
- [ ] 创建目录 `plugins/compound-engineering/skills/verification-before-completion/`
- [ ] 创建 SKILL.md，融合 CE CLAUDE.md 验证铁律 + SP 的 Agent 委派验证和 TDD 红绿循环

**代码**:
```yaml
---
name: verification-before-completion
description: >
  This skill should be used before declaring any task, fix, or feature as complete.
  It enforces evidence-based verification with specific patterns for test validation,
  agent delegation, and regression prevention. Prevents false completion claims.
disable-model-invocation: true
---
```

**SKILL.md 核心内容**:

```markdown
# 完成前验证

> **铁律**：跳过任何验证步骤 = 虚假声明，不是验证。

## 门控函数（5 步，不可跳过）

```
1. 识别：什么命令能证明这个声明？
2. 运行：执行完整命令（新鲜的，完整的）
3. 阅读：完整输出，检查退出码，统计失败数
4. 验证：输出是否确认声明？
   - 否 → 陈述实际状态并附证据
   - 是 → 陈述声明并附证据
5. 然后才能：做出声明
```

## 声明验证对照表

| 声明 | 需要的证据 | 不充分的证据 |
|------|-----------|-------------|
| 测试通过 | 测试命令输出：0 失败 | 之前的运行、「应该通过」 |
| 构建成功 | 构建命令：exit 0 | lint 通过、日志看起来正常 |
| Bug 已修复 | 测试原始症状：通过 | 代码改了、假设修好了 |
| 需求满足 | 逐行清单验证 | 测试通过 |
| Linter 干净 | Linter 输出：0 错误 | 部分检查、外推 |
| 回归测试有效 | 红绿循环验证 | 测试通过一次 |
| Agent 已完成 | VCS diff 显示变更 | Agent 报告「成功」 |

## 验证模式

### 模式 1：TDD 红绿循环验证

验证回归测试本身的有效性：

```
✅ 正确流程：
写测试 → 运行（通过）→ 撤销修复 → 运行（必须失败）→ 恢复修复 → 运行（通过）

❌ 错误流程：
"我已经写了回归测试"（没有验证测试能失败）
```

### 模式 2：Agent 委派验证

验证子代理的工作结果：

```
✅ 正确流程：
Agent 报告成功 → 检查 VCS diff → 验证变更内容 → 报告实际状态

❌ 错误流程：
相信 agent 报告，直接声明完成
```

### 模式 3：跨任务验证

```
移动到下一个任务前 → 验证当前任务
委派给 agent 前 → 验证委派内容清晰完整
提交/推送/PR 前 → 验证所有声明
```

## 合理化防御

| 借口 | 现实 |
|------|------|
| 「我很确信」 | 确信 ≠ 证据。运行命令。 |
| 「Linter 通过了」 | Linter ≠ 编译器 ≠ 测试。 |
| 「Agent 说成功了」 | 独立验证。检查 diff。 |
| 「累了想收工」 | 疲劳不是跳过验证的理由。 |
| 「部分检查够了」 | 部分证明不了任何事。 |
| 「换个说法就不算违规」 | 精神优先于字面。 |

## 危险信号 — 停下来

- 使用「应该」「可能」「似乎」
- 在验证前表达满意（「太好了！」「完成！」）
- 准备提交/推送/PR 但没验证
- 想着「就这一次」
- 「TDD 是教条主义，我在务实」
- 「这个情况不一样...」

## 关联技能

- 前置：任何任务完成时
- 后续：`finishing-a-feature`（分支收尾）
- 关联：`test-driven-development`（TDD 红绿循环）
- 关联：`systematic-debugging`（调试完成验证）
```

**验证**:
- [ ] 确认 YAML frontmatter 合规
- [ ] 确认内容覆盖 CE 原有铁律 + SP 的 3 个验证模式

---

### Task 3: 创建 receiving-code-review skill 目录结构

**文件**: `plugins/compound-engineering/skills/receiving-code-review/SKILL.md`
**操作**:
- [ ] 创建目录 `plugins/compound-engineering/skills/receiving-code-review/`
- [ ] 创建 SKILL.md，基于 SP 的双向审查流程适配 CE

**代码**:
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

**SKILL.md 核心内容**:

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

推回条件：
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
- 关联：`verification-before-completion`（修复后验证）
- 关联：`spec-compliance-review`（规范合规检查）
```

**验证**:
- [ ] 确认 YAML frontmatter 合规
- [ ] 确认覆盖 SP 的 6 步响应模式和推回机制

---

### Task 4: 更新 plugin CLAUDE.md 的技能映射表

**文件**: `plugins/compound-engineering/CLAUDE.md`
**操作**:
- [ ] 在「可用技能（按场景）」表格中添加 3 个新技能的触发场景
- [ ] 具体要添加的行：

```markdown
| 任务完成后收尾 | finishing-a-feature | 测试验证 → 合并/PR 决策 → worktree 清理 |
| 声明完成前 | verification-before-completion | 5 步门控 + Agent 委派验证 + 红绿循环 |
| 收到审查反馈 | receiving-code-review | 6 步响应 + 禁止表演性同意 + YAGNI 检查 |
```

**验证**:
- [ ] 在 CLAUDE.md 中搜索新增行确认已添加

---

### Task 5: Wave 1 提交

**操作**:
- [ ] `git add plugins/compound-engineering/skills/finishing-a-feature/ plugins/compound-engineering/skills/verification-before-completion/ plugins/compound-engineering/skills/receiving-code-review/`
- [ ] `git add plugins/compound-engineering/CLAUDE.md`
- [ ] 提交消息：`Add 3 skills from superpowers fusion (Wave 1): finishing-a-feature, verification-before-completion, receiving-code-review`

**验证**:
- [ ] `git log -1` 确认提交成功
- [ ] `ls plugins/compound-engineering/skills/ | wc -l` 确认技能数 = 27

---

## Wave 2：增强 3 个现有 Skill

### Task 6: 增强 TDD skill — 添加「当卡住时」章节

**文件**: `plugins/compound-engineering/skills/test-driven-development/SKILL.md`
**操作**:
- [ ] 在「验证清单」章节前添加「当卡住时」章节（中文翻译）
- [ ] 补充 3 条常见借口到借口表
- [ ] 补充 2 条危险信号
- [ ] 补充 TDD 实用性论证到「为什么顺序重要」章节

**要添加的「当卡住时」章节内容**:

```markdown
## 当卡住时

| 问题 | 解决方案 |
|------|---------|
| 不知道怎么测试 | 写理想 API。先写断言。问你的协作者。 |
| 测试太复杂 | 设计太复杂。简化接口。 |
| 必须 mock 所有东西 | 代码耦合太紧。使用依赖注入。 |
| 测试 setup 太庞大 | 提取辅助函数。还是复杂？简化设计。 |
```

**要补充的 3 条借口**:

```markdown
| 「需要先探索」 | 可以。探索完丢掉，从 TDD 开始。 |
| 「测试难写 = 设计不清晰」 | 听测试的话。难测 = 难用。 |
| 「现有代码没测试」 | 你在改进它。为现有代码加测试。 |
```

**要补充的 2 条危险信号**:

```markdown
- 「TDD 是教条主义，我在务实」
- 「这个情况不一样...」
```

**要补充的 TDD 实用性论证**:

```markdown
### TDD 就是务实

TDD **就是**务实：
- 提交前发现 bug（比提交后调试更快）
- 防止回归（测试立即捕获破坏）
- 文档化行为（测试展示如何使用代码）
- 赋能重构（自由修改，测试捕获破坏）

「务实的」捷径 = 在生产环境调试 = 更慢。

### 测试先 vs 测试后的本质差异

测试后回答「这做了什么？」测试先回答「这应该做什么？」

测试后受实现偏见影响。你测试你构建的，而非需求要求的。
测试先强制在实现前发现边缘案例。测试后验证你记住了所有情况（你没有）。
```

**验证**:
- [ ] 搜索「当卡住时」确认章节已添加
- [ ] 确认新增内容风格与现有中文内容一致

---

### Task 7: 增强 brainstorming skill

**文件**: `plugins/compound-engineering/skills/brainstorming/SKILL.md`
**操作**:
- [ ] 添加「提问技术」章节（4 种技巧）
- [ ] 添加「反模式」表格（6 种）
- [ ] 添加 WHAT vs HOW 边界定义

**要添加的「提问技术」章节**:

```markdown
## 提问技术

### 1. 多选优先
当存在自然选项时，使用 AskUserQuestion 提供多选。
- ✅ 好：「认证方式？A) JWT  B) Session  C) OAuth」
- ❌ 差：「你想用什么认证方式？」

### 2. 先宽后窄
从目的和用户开始，逐渐收窄到约束和边缘案例。
- 第一轮：目的、目标用户、成功标准
- 第二轮：约束、非功能需求、边缘情况

### 3. 显式验证假设
不要隐含假设——说出来让用户确认或纠正。
- ✅ 好：「我假设这只需要支持 PostgreSQL。对吗？」
- ❌ 差：（默认只考虑 PostgreSQL 不说）

### 4. 早问成功标准
尽早确定「什么算完成」。
- 「这个功能成功的标志是什么？」
- 「用户完成后应该看到什么？」
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
- [ ] 搜索「提问技术」确认章节已添加
- [ ] 搜索「反模式」确认表格已添加

---

### Task 8: 增强 create-agent-skills skill（融合 writing-skills 精华）

**文件**: `plugins/compound-engineering/skills/create-agent-skills/SKILL.md`
**操作**:
- [ ] 添加「TDD for Skills」章节
- [ ] 添加「CSO 优化」章节（Claude Search Optimization）
- [ ] 添加「防合理化」章节
- [ ] 添加「Token 效率」章节

**要添加的「TDD for Skills」章节**:

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
```

**要添加的「CSO 优化」章节**:

```markdown
## CSO 优化（Claude Search Optimization）

> **关键：Description = 何时使用，不是 Skill 做什么**

### 为什么重要

测试发现：当 description 总结了 Skill 的工作流时，Claude 可能只读 description 而不读完整 Skill 内容。

### 实证案例

一个 description 写着「code review between tasks」导致 Claude 只做一次审查，
即使 Skill 的流程图明确显示两次审查（spec compliance + code quality）。

当 description 改为只写触发条件（「Use when executing implementation plans with independent tasks」），
Claude 正确读取了流程图并执行了两阶段审查。

### 关键词覆盖

使用 Claude 会搜索的词：
- 错误消息：'Hook timed out', 'ENOTEMPTY', 'race condition'
- 症状词：'flaky', 'hanging', 'zombie', 'pollution'
- 同义词：'timeout/hang/freeze', 'cleanup/teardown/afterEach'
- 工具名：实际命令名、库名、文件类型
```

**要添加的「Token 效率」章节**:

```markdown
## Token 效率

> 每个 Token 都重要。getting-started 和频繁加载的 Skill 会进入每次对话。

### 目标字数

| 类型 | 目标 |
|------|------|
| 频繁加载的 Skill | < 200 词 |
| 其他 Skill | < 500 词 |

### 压缩技术

- 细节移到 `references/` 子目录
- 使用交叉引用而非重复
- 压缩示例到最小必要
- 消除冗余措辞
```

**验证**:
- [ ] 搜索「TDD for Skills」确认章节已添加
- [ ] 搜索「CSO 优化」确认章节已添加

---

### Task 9: Wave 2 提交

**操作**:
- [ ] `git add plugins/compound-engineering/skills/test-driven-development/SKILL.md`
- [ ] `git add plugins/compound-engineering/skills/brainstorming/SKILL.md`
- [ ] `git add plugins/compound-engineering/skills/create-agent-skills/SKILL.md`
- [ ] 提交消息：`Enhance 3 skills with superpowers insights (Wave 2): TDD, brainstorming, create-agent-skills`

**验证**:
- [ ] `git log -1` 确认提交成功

---

## Wave 3：增强 2 个工作流命令

### Task 10: 增强 work.md — 添加 STOP 协议和批评性审查

**文件**: `plugins/compound-engineering/commands/workflows/work.md`
**操作**:
- [ ] 在 Phase 1（Read Plan）中将「Read Plan and Clarify」改为「批评性审查计划」
- [ ] 在 Subagent-Driven 模式中添加独立的 STOP 协议章节
- [ ] 在 Phase 4 Ship It 中添加 `finishing-a-feature` skill 引用
- [ ] 添加失败任务处理规范

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

**要添加的失败任务处理**:

```markdown
### 子代理任务失败时

```
IF 子代理报告任务失败:
  不要手动修复（上下文污染）
  派遣新的修复子代理，提供：
    - 失败原因
    - 原始任务要求
    - 已有的代码变更
  让修复子代理在干净上下文中工作
```
```

**要添加的 finishing-a-feature 引用**:

在 Phase 4 Step 1 添加：
```markdown
> **REQUIRED SUB-SKILL**: 使用 `finishing-a-feature` skill 完成分支收尾。
```

**验证**:
- [ ] 搜索「STOP 协议」确认已添加
- [ ] 搜索「finishing-a-feature」确认引用已添加

---

### Task 11: 增强 plan.md — 添加 Plan Header 和 TDD 内嵌

**文件**: `plugins/compound-engineering/commands/workflows/plan.md`
**操作**:
- [ ] 在 Task 结构模板中添加强制的 Plan Header（Goal / Architecture / Tech Stack）
- [ ] 在 Bite-Sized 任务示例中内嵌 TDD 五步

**要在 plan 模板（Section 5 的 MINIMAL/MORE/A LOT 三档共用部分）中添加的 Plan Header**:

```markdown
> **每个计划必须以此 Header 开头**：

```markdown
## Overview

**Goal**: [一句话描述要构建什么]
**Architecture**: [2-3 句话描述方法]
**Tech Stack**: [关键技术/库]
```
```

**要在 Bite-Sized 任务示例中补充的 TDD 内嵌**:

在 Section 2 的「拆分示例」✅ 正确（原子化）后补充：

```markdown
> **TDD 内嵌提示**：每个实现任务的结构应遵循 TDD 五步：
> 1. 写失败测试
> 2. 运行测试验证失败
> 3. 写最小实现
> 4. 运行测试验证通过
> 5. 提交
```

**验证**:
- [ ] 搜索「Goal」「Architecture」「Tech Stack」确认 Header 已添加
- [ ] 搜索「TDD 内嵌」确认提示已添加

---

### Task 12: Wave 3 提交

**操作**:
- [ ] `git add plugins/compound-engineering/commands/workflows/work.md`
- [ ] `git add plugins/compound-engineering/commands/workflows/plan.md`
- [ ] 提交消息：`Enhance work.md and plan.md with superpowers patterns (Wave 3): STOP protocol, Plan Header, TDD embed`

**验证**:
- [ ] `git log -1` 确认提交成功

---

## Wave 4：收尾增强

### Task 13: 增强 systematic-debugging — 添加「无根因」分支和协作者信号

**文件**: `plugins/compound-engineering/skills/systematic-debugging/SKILL.md`
**操作**:
- [ ] 在 Phase 4 后添加「无根因分支」章节
- [ ] 添加「协作者信号」解读表
- [ ] 在末尾添加 `verification-before-completion` 引用

**要添加的「无根因分支」**:

```markdown
## 当无法找到根因时

1. 记录已调查的内容（排除了什么）
2. 实施适当的防御措施（retry、timeout、error message）
3. 添加监控/日志供将来调查

> 提示：95% 的「无根因」情况是调查不完整。
```

**要添加的「协作者信号」**:

```markdown
## 协作者信号解读

| 用户说 | 意味着 |
|--------|--------|
| 「不是这样吗？」 | 你在没验证的情况下假设了 |
| 「能看到...吗？」 | 你应该添加证据收集 |
| 「别猜了」 | 你在没理解的情况下提议修复 |
| 「深入想想」 | 质疑根本，而非仅仅症状 |
| 「卡住了？」（沮丧） | 你的方法不起作用，换路径 |
```

**验证**:
- [ ] 搜索「无根因」确认已添加
- [ ] 搜索「协作者信号」确认已添加

---

### Task 14: 增强 git-worktree — 添加基线测试验证

**文件**: `plugins/compound-engineering/skills/git-worktree/SKILL.md`
**操作**:
- [ ] 在「创建 Worktree」流程中添加「基线测试」步骤

**要添加的内容**:

```markdown
### 基线测试验证

创建 worktree 后，立即运行测试套件：

```bash
# 在新 worktree 中运行测试
cd .worktrees/<branch-name>
<project-test-command>
```

- 通过 → 继续开发
- 失败 → 报告失败，使用 AskUserQuestion 询问是否继续或先修复
```

**验证**:
- [ ] 搜索「基线测试」确认已添加

---

### Task 15: 更新版本号和 CHANGELOG

**文件**:
- `plugins/compound-engineering/CHANGELOG.md`
- `.claude-plugin/marketplace.json`
- `plugins/compound-engineering/.claude-plugin/plugin.json`

**操作**:
- [ ] 在 CHANGELOG.md 顶部添加新版本记录
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType minor` 更新版本号
- [ ] 更新组件数量（Skills: 24 → 27）

**CHANGELOG 内容**:

```markdown
## [2.44.0] - 2026-03-11

### Added
- 新增 `finishing-a-feature` skill：功能分支收尾闭环（测试→合并/PR→清理）
- 新增 `verification-before-completion` skill：完成前验证（Agent 委派验证 + TDD 红绿循环）
- 新增 `receiving-code-review` skill：接收审查响应规范（6步协议 + 禁止表演性同意）

### Changed
- 增强 `test-driven-development` skill：添加「当卡住时」章节、TDD 实用性论证、3 条新借口
- 增强 `brainstorming` skill：添加提问技术、反模式表、WHAT vs HOW 边界
- 增强 `create-agent-skills` skill：添加 TDD for Skills 框架、CSO 优化、Token 效率
- 增强 `workflows:work`：添加 STOP 协议、失败任务处理、finishing-a-feature 引用
- 增强 `workflows:plan`：添加 Plan Header 强制模板、TDD 内嵌任务结构
- 增强 `systematic-debugging`：添加「无根因」分支、协作者信号解读
- 增强 `git-worktree`：添加基线测试验证

### Source
- 精华内容来源：[obra/superpowers](https://github.com/obra/superpowers) v4.1.1
- 对比分析：docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md
```

**验证**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] 确认 CHANGELOG 格式正确（使用 Keep a Changelog 标准节名）

---

### Task 16: 更新 CLAUDE.md 组件统计

**文件**: `CLAUDE.md`（项目根目录）
**操作**:
- [ ] 更新组件统计表：Skills 24 → 27

```markdown
| Skills      | 27   | `plugins/compound-engineering/skills/`   |
```

**验证**:
- [ ] `ls -d plugins/compound-engineering/skills/*/ | wc -l` 确认目录数 = 27

---

### Task 17: Wave 4 最终提交

**操作**:
- [ ] `git add -A`（审查所有变更后）
- [ ] 提交消息：`Complete superpowers fusion (Wave 4): debugging, worktree, versioning — v2.44.0`

**验证**:
- [ ] `git log -1` 确认提交成功
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] `ls -d plugins/compound-engineering/skills/*/ | wc -l` 确认 27 个 skills

---

## Risk Analysis

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 安全/隐私 | 0 | 无敏感数据 |
| 可逆性 | 0 | 全部 Markdown/配置文件 |
| 影响范围 | 0 | 个人项目 |
| 变更规模 | 1 | ~15 文件 |
| 外部依赖 | 0 | 无 |
| **总分** | **1/10** | **低风险 🟢** |

## References

- (see brainstorm: docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md)
- SP 本地路径: `F:\StudyFolder\StudyDest\project\Dev_tools\superpowers\`
- [obra/superpowers GitHub](https://github.com/obra/superpowers)
- Skill 合规清单: `plugins/compound-engineering/CLAUDE.md`
- 历史教训: `docs/solutions/integration-issues/sessionstart-hook-prompt-type-not-supported.md`
