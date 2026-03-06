---
name: workflows:brainstorm
description: "Step 1: [P][C][G] 探索需求和方案，在规划前进行协作对话"
argument-hint: "[feature idea or problem to explore] [C] [G]"
---

# Brainstorm a Feature or Improvement

**Note: The current year is 2026.** Use this when dating brainstorm documents.

Brainstorming helps answer **WHAT** to build through collaborative dialogue. It precedes `/workflows:plan`, which answers **HOW** to build it.

**Process knowledge:** Load the `brainstorming` skill for detailed question techniques, approach exploration patterns, and YAGNI principles.

**Party Mode available:** At any point, user can say `[P]` or "开启派对模式" to switch to multi-agent collaborative discussion. Load the `party-mode` skill for details.

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

## Feature Description

<feature_description> #$ARGUMENTS </feature_description>

**If the feature description above is empty, ask the user:** "What would you like to explore? Please describe the feature, problem, or improvement you're thinking about."

Do not proceed until you have a feature description from the user.

## Execution Flow

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

### Phase 0: Assess Requirements Clarity

Evaluate whether brainstorming is needed based on the feature description.

**Clear requirements indicators:**
- Specific acceptance criteria provided
- Referenced existing patterns to follow
- Described exact expected behavior
- Constrained, well-defined scope

**If requirements are already clear:**
Use **AskUserQuestion tool** to suggest: "Your requirements seem detailed enough to proceed directly to planning. Should I run `/workflows:plan` instead, or would you like to explore the idea further?"

### Phase 1: Understand the Idea

#### 1.1 Repository Research (Lightweight)

Run a quick repo scan to understand existing patterns:

- Task repo-research-analyst("Understand existing patterns related to: <feature_description>")

Focus on: similar features, established patterns, CLAUDE.md guidance.

#### 1.2 Collaborative Dialogue

Use the **AskUserQuestion tool** to ask questions **one at a time**.

**Guidelines (see `brainstorming` skill for detailed techniques):**
- Prefer multiple choice when natural options exist
- Start broad (purpose, users) then narrow (constraints, edge cases)
- Validate assumptions explicitly
- Ask about success criteria

**Exit condition:** Continue until the idea is clear OR user says "proceed"

### Phase 2: Explore Approaches

Propose **2-3 concrete approaches** based on research and conversation.

For each approach, provide:
- Brief description (2-3 sentences)
- Pros and cons
- When it's best suited

Lead with your recommendation and explain why. Apply YAGNI—prefer simpler solutions.

Use **AskUserQuestion tool** to ask which approach the user prefers.

**Party Mode option:** If the decision involves complex trade-offs or would benefit from multiple expert perspectives, offer:
- Option: "[P] Party Mode - 听听多位专家的意见" - Loads `party-mode` skill for multi-agent discussion

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

如果未安装，提示用户安装并跳过 Codex 咨询（主流程不中断）。

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

**执行流程**：

```
Step 1: 后台启动 Codex
  - 使用 Bash 工具，设置 run_in_background=true
  - 调用:
    CODEX_OUTPUT="${TEMP:-/tmp}/codex-brainstorm-$(date +%s).md"
    cat <<'PROMPT_EOF' | codex exec -m gpt-5.3-codex --output-last-message "$CODEX_OUTPUT" -
    <构建好的prompt>
    PROMPT_EOF
  - 记录返回的 task_id

Step 2: 等待完成
  - 使用 TaskOutput 工具等待任务完成（最多 5 分钟）

Step 3: 读取结果
  - cat "$CODEX_OUTPUT" 获取 Codex 回答
  - 整合到后续 brainstorm 文档中
```

#### 当 GEMINI_ENABLED = true 时：

**Step 2.5.4: 检查 Gemini CLI 可用性**

```bash
command -v gemini || echo "Gemini CLI 未安装，请运行: npm install -g @google/gemini-cli"
```

如果未安装，提示用户安装并跳过 Gemini 咨询（主流程不中断）。

**Step 2.5.5: 构建方案咨询 Prompt 并调用**

使用与 Codex 相同的 prompt 结构，通过 Gemini CLI 调用。

**执行流程**：

```
Step 1: 后台启动 Gemini
  - 使用 Bash 工具，设置 run_in_background=true
  - 调用:
    cat <<'PROMPT_EOF' | gemini -m gemini-3-pro-preview -p '' -o json
    <构建好的prompt>
    PROMPT_EOF
  - 记录返回的 task_id

Step 2: 等待完成
  - 使用 TaskOutput 工具等待任务完成（最多 5 分钟）

Step 3: 读取结果
  - 解析 JSON 输出，提取 .response 字段
  - 整合到后续 brainstorm 文档中
```

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

### Phase 3: Capture the Design

Before writing, check for existing brainstorm documents with matching topic:

```bash
ls -la docs/brainstorms/*-<topic>-brainstorm.md 2>/dev/null
```

**If a matching brainstorm already exists:**
Use **AskUserQuestion tool** to present options:

**Question:** "发现已有同主题的 brainstorm 文档。如何处理？"

**Options:**
1. **续接** - 在现有文档基础上追加新内容
2. **新建** - 创建新文档（添加日期区分）
3. **查看已有** - 先查看现有内容再决定

Based on selection:
- **续接** → 读取现有文档，在末尾追加新章节
- **新建** → 使用新日期创建独立文档
- **查看已有** → 展示现有文档内容，然后重新呈现选项

**禁止**：检测到存在就自动覆盖或自动续接。

Write a brainstorm document to `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`.

**Document structure:** See the `brainstorming` skill for the template format. Key sections: What We're Building, Why This Approach, Key Decisions, Open Questions.

<!-- CLAUDE-CODE-ONLY-START -->
**如果 CODEX_ENABLED 或 GEMINI_ENABLED 为 true**，将 Phase 2.5 的外部咨询结果写入文档的「外部 AI 咨询结果」小节（使用 Phase 2.5 中定义的三方对比表格格式）。
<!-- CLAUDE-CODE-ONLY-END -->

Ensure `docs/brainstorms/` directory exists before writing.

### Phase 4: Handoff

Use **AskUserQuestion tool** to present next steps:

**Question:** "头脑风暴已记录。下一步？"

**Options:**
1. **进入规划** - 运行 `/workflows:plan`（将自动检测此 brainstorm）（推荐）
2. **继续探索** - 继续细化设计
3. **停止** - 稍后再继续

Based on selection:
- **进入规划** → 调用 `/workflows:plan`
- **继续探索** → 回到 Phase 1 或 Phase 2 继续对话
- **停止** → 结束流程

## Output Summary

When complete, display:

```
Brainstorm complete!

Document: docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md

Key decisions:
- [Decision 1]
- [Decision 2]

Next: Run `/workflows:plan` when ready to implement.
```

## Important Guidelines

- **Stay focused on WHAT, not HOW** - Implementation details belong in the plan
- **Ask one question at a time** - Don't overwhelm
- **Apply YAGNI** - Prefer simpler approaches
- **Keep outputs concise** - 200-300 words per section max

**Party Mode Guidelines:**
- User can activate anytime with `[P]` or "开启派对模式"
- In party mode: 2-3 agents discuss from different perspectives
- Each agent maintains consistent personality and communication style
- User can exit with `[E]` or "结束派对"
- Party mode output integrates into the brainstorm document

NEVER CODE! Just explore and document decisions.
