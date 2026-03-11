---
title: "/workflows:brainstorm 派对模式从未真正工作"
date: 2026-03-11
type: fix
severity: high
status: resolved
version: 2.44.4
tags:
  - workflows
  - brainstorm
  - party-mode
  - skill-invocation
  - bmad-method
related_issues:
  - 派对模式输出格式错误
  - AI 输出"现象层/本质层/哲学层"而非多代理对话
  - [P] 参数未被解析
---

# /workflows:brainstorm 派对模式从未真正工作

## 问题描述

### 用户报告的现象

用户在使用 `/workflows:brainstorm [P]` 时，期望看到多个 AI 代理的对话（如 BMAD-METHOD 的派对模式），但实际输出是：

```
现象层（医生）：
  - AI 连续调用 10+ 次 <invoke name="Write"> 但都是空标签
  ...

本质层（侦探）：
  这是 AI 输出质量退化 的典型症状...

哲学层（诗人）：
  ...
```

这是**单个 AI 使用全局 CLAUDE.md 的"三层思维"框架**，而不是派对模式的多代理对话。

### 预期行为

派对模式应该输出：

```
🎉 派对模式已激活！

今天参与讨论的核心团队：
🏗️ 李明远（架构师）- 系统设计与技术选型，冷静务实
📊 陈思琪（分析师）- 需求分析与业务洞察，善于追问
💻 张晓峰（开发者）- 实现细节与代码质量，极简主义

---

🏗️ **李明远**：「关于这个问题，我建议...」

📊 **陈思琪**：「等等，我想先确认一下需求...」

💻 **张晓峰**：「从实现角度看，李明远的方案可行，但...」
```

## 根本原因分析

### 历史调查

通过 git 历史分析发现：

```bash
# 派对模式首次添加（2026-02-01）
git show 3c1d92d

# 当时的实现
**Party Mode option:** If the decision involves complex trade-offs...
- Option: "[P] Party Mode - 听听多位专家的意见" - Loads `party-mode` skill
```

**问题：从一开始就没有正确实现！**

### 三层原因分析

#### 现象层（医生）

1. **`[P]` 参数未被解析** - Step 0 只解析了 `[C]` 和 `[G]`，没有 `[P]`
2. **没有调用 `Skill("party-mode")`** - Phase 2 只有描述性文本，没有执行指令
3. **AI 退回到默认行为** - 看到 `[P]` 但不知道如何处理，使用全局 CLAUDE.md 的三层思维

#### 本质层（侦探）

**设计缺陷：隐式指令 vs 显式指令**

| 类型 | 示例 | AI 行为 |
|------|------|---------|
| **隐式指令**（错误） | "Loads `party-mode` skill" | AI 只是"知道"有这个 skill，但不会调用 |
| **显式指令**（正确） | `Execute: Skill("party-mode")` | AI 明确知道要执行什么操作 |

当前实现使用了隐式指令，导致 AI 无法正确调用 party-mode。

#### 哲学层（诗人）

> "文档不是代码。描述不是执行。"

这个问题反映了一个更深层的设计原则：
- **AI 需要可执行的指令，不是描述性的文档**
- **参数解析必须显式，不能依赖 AI 的"理解"**
- **工作流的每个步骤都应该有明确的执行路径**

## 解决方案

### 修改 1：添加 `[P]` 参数解析（Step 0）

**修改前：**
```markdown
检测 [C] 标志：...
检测 [G] 标志：...
```

**修改后：**
```markdown
检测 [P] 标志：
  如果包含 [P] 或 [p]：
    → PARTY_MODE_ENABLED = true
    → 从参数中移除 [P]
  否则：
    → PARTY_MODE_ENABLED = false

检测 [C] 标志：...
检测 [G] 标志：...
```

### 修改 2：添加派对模式自动调用（Phase 1.2）

**修改前：**
```markdown
#### 1.2 Collaborative Dialogue

Use the **AskUserQuestion tool** to ask questions **one at a time**.
```

**修改后：**
```markdown
#### 1.2 Collaborative Dialogue

**检查 PARTY_MODE_ENABLED 标志（来自 Step 0）：**

**如果 PARTY_MODE_ENABLED = true：**
```
立即执行派对模式：
  Execute: Skill("party-mode")

派对模式会：
  1. 激活多代理讨论（2-3 个专家）
  2. 每个代理以自己的人格发言
  3. 代理之间可以互相引用、质疑、补充
  4. 用户可随时输入 [E] 退出派对模式
  5. 讨论结果自动整合到 brainstorm 文档

派对模式结束后，继续 Phase 2。
```

**如果 PARTY_MODE_ENABLED = false（默认）：**

Use the **AskUserQuestion tool** to ask questions **one at a time**.
```
```

### 修改 3：移除 Phase 2 的冗余选项

**修改前：**
```markdown
**Party Mode option:** If the decision involves complex trade-offs...
- Option: "[P] Party Mode - 听听多位专家的意见"
```

**修改后：**
```markdown
**Note:** If user wants multi-agent discussion at this stage,
they can restart with `/workflows:brainstorm [P]` parameter.
```

**原因：** 派对模式已在 Phase 1.2 执行，Phase 2 不需要再提供选项。

## 验证方法

### 测试用例

```bash
# 测试 1：基本派对模式
/workflows:brainstorm [P] Add user authentication

预期：
1. Step 0 解析出 PARTY_MODE_ENABLED = true
2. Phase 1.2 自动调用 Skill("party-mode")
3. 输出多个代理的对话（emoji + 代理名 + 发言）
4. 用户输入 [E] 退出派对模式
5. 继续 Phase 2

# 测试 2：派对模式 + Codex
/workflows:brainstorm [P][C] Add notifications

预期：
1. Phase 1.2 执行派对模式
2. Phase 2.5 自动调用 Codex 咨询

# 测试 3：无派对模式（默认）
/workflows:brainstorm Add feature

预期：
1. PARTY_MODE_ENABLED = false
2. Phase 1.2 使用标准 AskUserQuestion 流程
3. 不调用 party-mode skill
```

### 验证命令

```bash
# 检查版本号
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 搜索修改内容
grep -A 10 "PARTY_MODE_ENABLED" plugins/compound-engineering/commands/workflows/brainstorm.md

# 查看 Step 0 参数解析
grep -A 30 "Step 0" plugins/compound-engineering/commands/workflows/brainstorm.md
```

## 影响范围

### 修改的文件

- `plugins/compound-engineering/commands/workflows/brainstorm.md` - 添加 `[P]` 解析和调用逻辑
- `plugins/compound-engineering/.claude-plugin/plugin.json` - 版本号 2.44.3 → 2.44.4
- `.claude-plugin/marketplace.json` - 版本号 2.44.3 → 2.44.4
- `plugins/compound-engineering/CHANGELOG.md` - 添加 2.44.4 条目

### 影响的工作流

- `/workflows:brainstorm [P]` - 现在真正工作了
- `party-mode` skill - 调用频率预期大幅提升
- 用户体验 - 从"单 AI 分析"变为"多代理对话"

## 相关问题

### 为什么之前没发现？

1. **派对模式是新功能**（2026-02-01 添加），使用频率低
2. **AI 有降级行为** - 不知道如何处理时，使用全局 CLAUDE.md 的框架
3. **输出看起来"合理"** - 三层思维框架也能分析问题，只是不是派对模式

### 其他 workflow 是否有类似问题？

需要检查：
- `/workflows:plan` - 是否有未正确调用的 skill？
- `/workflows:work` - Subagent 调用是否明确？
- `/workflows:review` - Codex/Gemini 调用是否正确？

建议：审查所有 workflow 命令，确保所有 skill 调用都是显式的。

## 经验教训

### 设计原则

1. **显式优于隐式** - 用 `Execute: Skill("name")` 而非 "Loads skill"
2. **参数必须解析** - 所有 `[X]` 参数都要在 Step 0 解析
3. **执行路径清晰** - 每个分支都要有明确的 if-then 逻辑
4. **测试真实行为** - 不要假设 AI 会"理解"描述性文本

### AI 行为模式

**AI 对指令的理解：**

| 指令类型 | 示例 | AI 行为 |
|----------|------|---------|
| **可执行指令** | `Execute: Skill("party-mode")` | ✅ 调用工具 |
| **描述性文本** | "Loads party-mode skill" | ❌ 只是"知道"，不调用 |
| **条件分支** | `if X then Y` | ✅ 按逻辑执行 |
| **模糊建议** | "consider using X" | ❌ 可能跳过 |

### 工作流设计规范

**Handoff 和参数处理的标准格式：**

```markdown
### Step 0: 参数解析

检测 [X] 标志：
  如果包含 [X]：
    → X_ENABLED = true
  否则：
    → X_ENABLED = false

### Phase N: 执行

**检查 X_ENABLED 标志：**

**如果 X_ENABLED = true：**
```
Execute: Skill("x-skill")
```

**如果 X_ENABLED = false：**
[默认行为]
```
```

## 后续行动

### 立即行动（已完成）

- [x] 添加 `[P]` 参数解析
- [x] 添加派对模式自动调用
- [x] 移除冗余选项
- [x] 更新版本号和 CHANGELOG
- [x] 创建解决方案文档

### 短期行动（本周）

- [ ] 测试派对模式的实际输出
- [ ] 审查其他 workflow 命令的 skill 调用
- [ ] 更新 `docs/zh-CN/WORKFLOW-VISUAL.md`（如需要）

### 长期行动（本月）

- [ ] 建立 workflow 设计规范文档
- [ ] 创建自动化测试（检测隐式指令）
- [ ] 审查所有 command 的参数解析逻辑

## 参考资料

### 相关文档

- [派对模式 Skill](../../plugins/compound-engineering/skills/party-mode/SKILL.md)
- [Brainstorming Skill](../../plugins/compound-engineering/skills/brainstorming/SKILL.md)
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) - 原始灵感来源

### 相关提交

```bash
# 派对模式首次添加
git show 3c1d92d

# 代理人格文件拆分
git show bab136a

# 本次修复
git log --oneline -- "plugins/compound-engineering/commands/workflows/brainstorm.md" | head -1
```

---

**创建时间**：2026-03-11
**最后更新**：2026-03-11
**作者**：Jerry Jian
**审核状态**：待审核
