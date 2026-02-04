---
title: "feat: 在 /workflows:brainstorm 中集成 [C][G] 外部咨询"
type: feat
date: 2026-02-04
---

# feat: 在 /workflows:brainstorm 中集成 [C][G] 外部咨询

## Overview

在 `/workflows:brainstorm` 命令中新增 `[C]`（Codex）和 `[G]`（Gemini）可选参数，复用 `/workflows:review` 中已有的参数解析模式和 `/codex`、`/gemini` 命令中的咨询调用模式。三个标记 `[P]` `[C]` `[G]` 正交兼容、无序、可任意组合。

**改动范围**：仅 `brainstorm.md` 一个文件 + 版本号和文档更新。

## Acceptance Criteria

- [x] `/workflows:brainstorm [C]` 在 Phase 2 后自动调用 Codex 咨询
- [x] `/workflows:brainstorm [G]` 在 Phase 2 后自动调用 Gemini 咨询
- [x] `/workflows:brainstorm [C][G]` 同时调用两者
- [x] `[P]` `[C]` `[G]` 任意组合、无先后顺序
- [x] `[C][G]` 相关内容用 `<!-- CLAUDE-CODE-ONLY-START/END -->` 包裹
- [x] 外部咨询结果整合进 brainstorm 文档的"外部咨询"小节
- [x] CLI 不可用时优雅降级（提示安装，不中断主流程）
- [x] description 更新为 `"Step 1: [P][C][G] 探索需求和方案，在规划前进行协作对话"`
- [x] 版本号 bump、CHANGELOG 更新

## Task Breakdown

### Task 1: 更新 brainstorm.md 的 frontmatter

**文件**: `plugins/compound-engineering/commands/workflows/brainstorm.md:1-5`
**操作**:
- [ ] 修改 `description` 字段加入 `[C][G]`
- [ ] 修改 `argument-hint` 字段加入 `[C] [G]`

**代码**:
```yaml
---
name: workflows:brainstorm
description: "Step 1: [P][C][G] 探索需求和方案，在规划前进行协作对话"
argument-hint: "[feature idea or problem to explore] [C] [G]"
---
```

**验证**:
- [ ] 检查 frontmatter 格式正确（YAML 合法）

---

### Task 2: 添加参数说明表格和使用示例

**文件**: `plugins/compound-engineering/commands/workflows/brainstorm.md`
**操作**:
- [ ] 在 `## Feature Description` 之前插入参数说明表格
- [ ] 添加 `<!-- CLAUDE-CODE-ONLY-START/END -->` 标记注明仅 Claude Code 可用

**代码**:
```markdown
## 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| 功能描述 | 想探索的功能或问题 | `/workflows:brainstorm Add notifications` |
| `[P]` | 开启派对模式（多视角讨论） | `/workflows:brainstorm [P]` |
| `[C]` | **Phase 2 后自动调用 Codex 方案咨询** | `/workflows:brainstorm [C]` |
| `[G]` | **Phase 2 后自动调用 Gemini 方案咨询** | `/workflows:brainstorm [G]` |

<!-- CLAUDE-CODE-ONLY-START -->
**注意**：`[C]` 和 `[G]` 参数仅在 Claude Code 中有效。转换到 Codex/Gemini 后不需要这些参数。
<!-- CLAUDE-CODE-ONLY-END -->

**示例：**
```bash
/workflows:brainstorm Add notifications           # 基本探索
/workflows:brainstorm [P]                          # 派对模式
/workflows:brainstorm [C]                          # + Codex 咨询
/workflows:brainstorm [G]                          # + Gemini 咨询
/workflows:brainstorm [C][G]                       # + Codex + Gemini 双咨询
/workflows:brainstorm [P][C][G] Add notifications  # 全开
```
```

**验证**:
- [ ] 参数说明表格与 review.md 风格一致

---

### Task 3: 添加 Phase 0 参数解析逻辑

**文件**: `plugins/compound-engineering/commands/workflows/brainstorm.md`
**操作**:
- [ ] 将现有的 `Phase 0: Assess Requirements Clarity` 重编号
- [ ] 在最前面插入新的参数解析步骤（复用 review.md 的 Step 0 模式）
- [ ] 用 `<!-- CLAUDE-CODE-ONLY-START/END -->` 包裹 [C][G] 解析部分

**代码**:
```markdown
### Step 0: 解析参数（检测 [C] 和 [G] 标志）

<!-- CLAUDE-CODE-ONLY-START -->

<argument_parsing>

**检查参数中是否包含 `[C]` 和 `[G]` 标志：**

```
参数: $ARGUMENTS

检测 [C] 标志：
  如果包含 [C] 或 [c]：
    → CODEX_ENABLED = true
    → 从参数中移除 [C]
  否则：
    → CODEX_ENABLED = false

检测 [G] 标志：
  如果包含 [G] 或 [g]：
    → GEMINI_ENABLED = true
    → 从参数中移除 [G]
  否则：
    → GEMINI_ENABLED = false

剩余部分作为功能描述（feature_description）
```

**记住这些标志，Phase 2 完成后根据它们决定是否自动调用 Codex/Gemini。**

如果 CODEX_ENABLED 或 GEMINI_ENABLED 为 true，在 Phase 2 提出方案时提示用户：
"方案提出后将自动咨询 [Codex/Gemini/Codex+Gemini] 寻求更优解。"

</argument_parsing>

<!-- CLAUDE-CODE-ONLY-END -->
```

**验证**:
- [ ] 伪代码逻辑与 review.md Step 0 一致
- [ ] `<!-- CLAUDE-CODE-ONLY-START/END -->` 标记正确包裹

---

### Task 4: 插入 Phase 2.5 外部咨询步骤

**文件**: `plugins/compound-engineering/commands/workflows/brainstorm.md`
**操作**:
- [ ] 在 Phase 2（Explore Approaches）和 Phase 3（Capture the Design）之间插入新的 Phase 2.5
- [ ] 整段用 `<!-- CLAUDE-CODE-ONLY-START/END -->` 包裹
- [ ] 包含：Codex 咨询逻辑、Gemini 咨询逻辑、多工具综合逻辑

**代码**:
```markdown
<!-- CLAUDE-CODE-ONLY-START -->

### Phase 2.5: 外部 AI 咨询（[C][G] 参数触发）

<external_consultation>

**检查 Step 0 中解析的 CODEX_ENABLED 和 GEMINI_ENABLED 标志。**

如果两者都为 false，跳过此步骤。

#### 当 CODEX_ENABLED = true 时：

**Step 2.5.1: 检查 Codex CLI 可用性**

```bash
command -v codex || echo "Codex CLI 未安装，请运行: npm install -g @openai/codex"
```

如果未安装，提示用户安装并跳过 Codex 咨询。

**Step 2.5.2: 构建方案咨询 Prompt 并调用**

构建结构化 prompt（从当前对话上下文中提取）：

```
## 项目背景
[技术栈、框架]

## 本轮头脑风暴的需求
[feature_description]

## Claude 提出的方案
[Phase 2 中提出的 2-3 个方案，包含各方案的描述、优缺点]

## 用户倾向的方向（如有）
[用户在 Phase 2 中选择的偏好]

## 请特别评估
1. 这些方案中是否有最优解？如果都不是，更好的方案是什么？
2. 有没有我们忽略的替代方案或开源库/框架？
3. 性价比方面：是否存在更简洁、更高效的实现路径？
4. 有没有潜在的坑或长期维护风险？
```

使用后台执行调用 Codex：

```bash
CODEX_OUTPUT="${TEMP:-/tmp}/codex-brainstorm-$(date +%s).md"
cat <<'PROMPT_EOF' | codex exec --output-last-message "$CODEX_OUTPUT" -
<构建好的prompt>
PROMPT_EOF
cat "$CODEX_OUTPUT"
```

- 使用 Bash 工具，设置 `run_in_background=true`
- 超时：300 秒（5 分钟）
- 记录返回的 task_id

**Step 2.5.3: 整合 Codex 咨询结果**

将 Codex 的方案评估整合到后续 brainstorm 文档中。

#### 当 GEMINI_ENABLED = true 时：

**Step 2.5.4: 检查 Gemini CLI 可用性**

```bash
command -v gemini || echo "Gemini CLI 未安装，请运行: npm install -g @google/gemini-cli"
```

如果未安装，提示用户安装并跳过 Gemini 咨询。

**Step 2.5.5: 构建方案咨询 Prompt 并调用**

使用与 Codex 相同的 prompt 结构，通过 Gemini CLI 调用：

```bash
cat <<'PROMPT_EOF' | gemini --yolo -p '' -o json
<构建好的prompt>
PROMPT_EOF
```

- 使用 Bash 工具，设置 `run_in_background=true`
- 超时：300 秒（5 分钟）
- 记录返回的 task_id

**Step 2.5.6: 整合 Gemini 咨询结果**

将 Gemini 的方案评估整合到后续 brainstorm 文档中。

#### 当 CODEX_ENABLED 和 GEMINI_ENABLED 都为 true 时：

在 Phase 3 的 brainstorm 文档中生成三方对比：

```markdown
## 外部咨询综合

| 评估维度 | Claude | Codex | Gemini | 共识度 |
|----------|--------|-------|--------|--------|
| 推荐方案 | [X] | [Y] | [Z] | 一致/分歧 |
| 替代建议 | ... | ... | ... | ... |
| 风险提示 | ... | ... | ... | ... |

**综合建议**：
1. 多方一致的观点（可信度最高）
2. 双方一致的建议（次优先）
3. 单方独特见解（供参考）
```

#### 超时处理

如果 Codex 或 Gemini 在 5 分钟内未完成：

```markdown
## ⏱️ [Codex/Gemini] 咨询超时

咨询未在 5 分钟内完成。可手动运行：
- Codex：`/codex [你的问题]`
- Gemini：`/gemini [你的问题]`

brainstorm 主流程结果仍然有效。
```

</external_consultation>

<!-- CLAUDE-CODE-ONLY-END -->
```

**验证**:
- [ ] `<!-- CLAUDE-CODE-ONLY-START/END -->` 正确包裹整个 Phase 2.5
- [ ] Codex 调用命令与 `/codex` 命令一致（`codex exec --output-last-message`）
- [ ] Gemini 调用命令与 `/gemini` 命令一致（`gemini --yolo -p '' -o json`）
- [ ] 超时处理逻辑完备

---

### Task 5: 微调 Phase 3 文档模板

**文件**: `plugins/compound-engineering/commands/workflows/brainstorm.md`
**操作**:
- [ ] 在 Phase 3 的文档结构说明中，添加"外部咨询"可选小节

**代码**:

在现有 Phase 3 的 "Key sections" 描述后追加：

```markdown
<!-- CLAUDE-CODE-ONLY-START -->
**如果 CODEX_ENABLED 或 GEMINI_ENABLED 为 true**，在 brainstorm 文档中额外添加：

```markdown
## 外部 AI 咨询结果

### Codex 评估（如启用）
[Codex 的方案评估和替代建议]

### Gemini 评估（如启用）
[Gemini 的方案评估和替代建议]

### 综合分析
[多方共识 > 双方一致 > 单方建议]
```
<!-- CLAUDE-CODE-ONLY-END -->
```

**验证**:
- [ ] 文档模板与 Phase 2.5 的输出结构匹配

---

### Task 6: 更新版本号和 CHANGELOG

**文件**:
- `.claude-plugin/marketplace.json`
- `plugins/compound-engineering/.claude-plugin/plugin.json`
- `plugins/compound-engineering/CHANGELOG.md`

**操作**:
- [ ] 版本号从 `2.38.1` 升级到 `2.39.0`（新功能 = MINOR bump）
- [ ] CHANGELOG 添加版本记录

**代码**（CHANGELOG 条目）:
```markdown
## [2.39.0] - 2026-02-04

### 新增
- `/workflows:brainstorm [C][G]` 支持 - 在方案探索阶段调用 Codex/Gemini 外部咨询
  - `[C]` 参数：Phase 2 后自动调用 Codex 挑战方案
  - `[G]` 参数：Phase 2 后自动调用 Gemini 挑战方案
  - `[P]` `[C]` `[G]` 三者正交兼容，可任意组合、无先后顺序
  - 结果整合进 brainstorm 文档的"外部咨询"小节
  - 使用 `<!-- CLAUDE-CODE-ONLY-START/END -->` 排除，不同步到 Codex/Gemini 格式
```

**验证**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致

---

### Task 7: 更新 brainstorm 命令描述中的 description（CLAUDE.md 等引用）

**文件**: `plugins/compound-engineering/CLAUDE.md`
**操作**:
- [ ] 更新 Workflow 命令列表中 brainstorm 的描述

**代码**:
```markdown
| Step 1: | `/workflows:brainstorm` | 探索需求和方案（支持 [P][C][G]） |
```

**验证**:
- [ ] 描述与 brainstorm.md 的 frontmatter description 语义一致

---

### Task 8: 提交并验证

**操作**:
- [ ] `git add` 所有修改文件
- [ ] `git commit` 使用中文 commit message

**验证**:
- [ ] `git status` 确认所有文件已提交
- [ ] 版本号一致性检查通过

## References

### Internal References
- 参数解析模式：`plugins/compound-engineering/commands/workflows/review.md:52-80`
- Codex 调用方式：`plugins/compound-engineering/commands/codex.md:46-56`
- Gemini 调用方式：`plugins/compound-engineering/commands/gemini.md:46-56`
- CLAUDE-CODE-ONLY 过滤：`plugins/compound-engineering/commands/workflows/review.md:753-851`
- 多工具综合：`plugins/compound-engineering/commands/workflows/review.md:853-872`
- Brainstorm 来源：`docs/brainstorms/2026-02-04-brainstorm-cg-integration-brainstorm.md`

### Related Experience
- Marketplace 更新与 Unicode 显示：`docs/solutions/integration-issues/marketplace-update-failure-and-unicode-display.md`
- Skill vs Agent 调用方式：`docs/solutions/integration-issues/skill-vs-agent-invocation.md`
