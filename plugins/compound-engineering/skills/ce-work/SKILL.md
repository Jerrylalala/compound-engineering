---
name: ce:work
description: Execute work efficiently while maintaining quality and finishing features
argument-hint: "[计划路径] [T=Agent Teams 3角色:合约主+执行者+验证者] [T+=Agent Teams 4角色:+风险卫，适合auth/payment/migration] [V=四层自验证:CLI→API/DB→浏览器→验收，通过才算完成] [V+=V+Playwright浏览器层（自动含[V]，无需单独传[V]）] [R=历史检索：learnings-researcher搜索docs/solutions] [C=Codex参与标记，仅审计溯源，不触发调用] [G=Gemini参与标记，仅审计溯源，不触发调用]"
---

# Work Execution Command

Execute work efficiently while maintaining quality and finishing features.

## Introduction

This command takes a work document (plan, specification, or todo file) or a bare prompt describing the work, and executes it systematically. The focus is on **shipping complete features** by understanding requirements quickly, following existing patterns, and maintaining quality throughout.

## Input Document

<input_document> #$ARGUMENTS </input_document>

## Execution Workflow

### Phase -1: 参数检测与模式初始化

检测所有可选标志并 strip from arguments before passing to Phase 0。

**[R] 历史检索标志检测**（最先执行，防止污染路径解析）：
- 如果 `$ARGUMENTS` 包含 `[R]` 或 `[r]`：
  - 设置 R_MODE_ENABLED = true
  - 从参数中移除 `[R]`
- 否则：R_MODE_ENABLED = false


> **向后兼容（参数别名）**：以下旧参数名在传入时自动识别并映射：
> - `[team]` → 等同 `[T]`
> - `[team:full]` → 等同 `[T+]`
> - `[T]`（旧：四层验证）→ 等同 `[V]`（新名）
> - `[PW]` → 等同 `[V+]`
> 传入旧名不会报错，等同传入新名。

**[V] 自验证标志检测**（独立执行）：
- 如果 `$ARGUMENTS` 包含 `[V]` 或 `[v]`，或向后兼容的 `[T]`（旧名）：
  - 设置 V_MODE_ENABLED = true
  - 从参数中移除 `[V]`（或 `[T]`）
  - 宣告：「✅ [V] 自验证模式已启用——执行完成后将运行四层验证（Phase 3.5）」
  - **[V+] 检测**（[V+] 自动启用四层验证，无需单独传 [V]）：
    - 如果 `$ARGUMENTS` 包含 `[V+]` 或 `[pw]`：
      - 检查 Playwright MCP 工具可用性（`mcp__playwright__browser_navigate` 是否在工具列表中）
      - 若可用：设置 V_PLUS_MODE_ENABLED = true，从参数中移除 `[V+]`，宣告：「✅ [V+] Playwright MCP 模式已启用——Layer 2 将使用 Playwright MCP（高精度浏览器验证）」
      - 若不可用：V_PLUS_MODE_ENABLED = false，输出：「⚠️ Playwright MCP Server 未配置，[V+] 模式不可用，Layer 2 自动降级为 agent-browser。如需 Playwright MCP，请先安装并配置 Playwright MCP Server。」
    - 否则：V_PLUS_MODE_ENABLED = false（Layer 2 使用 agent-browser，token 低 30-50 倍）
- 否则：V_MODE_ENABLED = false
  - 如果 `$ARGUMENTS` 包含 `[V+]` 或 `[pw]`（向后兼容旧 `[PW]`）：
    - **自动升级**：设置 V_MODE_ENABLED = true（[V+] 隐含 [V]，无需单独传 [V]）
    - 按上方 [V+] 检测逻辑继续执行（检查 Playwright MCP 可用性）
  - V_PLUS_MODE_ENABLED = false（默认）

**[C] Codex 标志检测**：
- 如果 `$ARGUMENTS` 包含 `[C]` 或 `[c]`：
  - 设置 CODEX_ENABLED = true
  - 从参数中移除 `[C]`
  - 宣告：「✅ [C] 标志已检测——标记外部 AI（Codex）已参与整体工作流。注：[C] 不透传给内嵌 ce:review（透传无收益，详见 Phase 3）」
- 否则：CODEX_ENABLED = false

**[G] Gemini 标志检测**：
- 如果 `$ARGUMENTS` 包含 `[G]` 或 `[g]`：
  - 设置 GEMINI_ENABLED = true
  - 从参数中移除 `[G]`
  - 宣告：「✅ [G] 标志已检测——标记外部 AI（Gemini）已参与整体工作流。注：[G] 不透传给内嵌 ce:review（透传无收益，详见 Phase 3）」
- 否则：GEMINI_ENABLED = false

**[T] / [T+] 检测**（仅当包含时）：
Strip the team token from arguments before passing to Phase 0.
Load the `team-mode` skill for the complete initialization sequence:
- TeamCreate（命名团队）
- .team-contract.md 加载与版本检测
- Spawn verifier teammate（独立 context window，只读，接收 SendMessage 通知并验证）
- [T+] 额外 spawn risk-guard teammate（高风险路径拦截）
- 宣告团队就绪
- Phase 2 每 Unit 完成后：SendMessage("verifier", ...) → 等待 PASS/FAIL → 修复或继续
- 全部 Unit 完成后：SendMessage("verifier", "全量集成验证") → 最终 PASS
- Phase 4 完成后：TeamDelete

---

### Phase -1.5: 环境指纹（Environment Fingerprint）

**触发条件**：V_MODE_ENABLED = true（由 [V] 或 [V+] 激活）。否则跳过本阶段。

**目标**：在进入执行流程前，自动确定「应用启动命令」（START_COMMAND），确保 Layer 2/4 验证时可以启动应用——对非开发者用户完全零记忆负担。

---

#### 决策树（按优先级顺序执行，找到即停止）

**Level 1：读取 CLAUDE.md 显式覆盖（最高优先级）**

搜索当前项目的 CLAUDE.md，寻找 ce-work 启动命令标记：

```
<!-- ce-work-start-command: <command> -->
<!-- ce-work-start-command-source: auto-detected|user-provided -->
```

- 若找到：
  - 读取 source 字段：
    - **`source: user-provided`**：用户明确指定的覆盖，无条件使用。设置 `START_COMMAND = <command>`，宣告 `✅ 已读取 CLAUDE.md 用户覆盖命令`，**跳转 Level 4**
    - **`source: auto-detected`**（或字段不存在）：需跨会话漂移校验。重新执行 Level 2 推导（新鲜读取 package.json）：
      - 若 Level 2 推导结果 = 已存储命令 → 无漂移，设置 `START_COMMAND = <command>`，**跳转 Level 4**
      - 若 Level 2 推导结果 ≠ 已存储命令（或 Level 2 无法推导）→ 宣告 `⚠️ 检测到启动命令可能已过期`，清除旧记录，**继续 Level 2**（会触发重写 CLAUDE.md）
- 若未找到：继续 Level 2

**Level 2：从 package.json 动态推导（每次新鲜读取，禁止依赖缓存）**

读取当前目录下的 `package.json`（若不存在则跳过此 Level）：

**先检测包管理器**（影响命令前缀）：
- `packageManager` 字段含 `yarn` → 使用 `yarn` 前缀（`yarn dev`）
- `packageManager` 字段含 `pnpm` → 使用 `pnpm run` 前缀
- 目录下存在 `pnpm-lock.yaml` → 使用 `pnpm run` 前缀
- 目录下存在 `yarn.lock`（且无 `pnpm-lock.yaml`）→ 使用 `yarn` 前缀
- 其他：使用 `npm run` 前缀（默认）

**按以下优先级顺序匹配 scripts**（PKG_RUN = 上方检测到的前缀）：

| 优先级 | 匹配条件 | 推导结果 |
|--------|---------|---------|
| 1 | scripts 中有 key 精确匹配 start-like 名称（`electron`/`start:electron`/`dev:electron`/`serve:electron`），或脚本值包含 `electron .`/`electron-forge start` | `<PKG_RUN> <该key>` |
| 2 | scripts.dev 或 scripts.serve 存在，且 devDependencies 或 dependencies 中含 `electron` | `<PKG_RUN> dev` / `<PKG_RUN> serve` |
| 3 | scripts.start 存在，且 devDependencies 或 dependencies 中含 `electron` | `<PKG_RUN> start` |
| 4 | `main` 字段存在，且 devDependencies 或 dependencies 含 `electron`，且无上述 scripts | `npx electron .` |
| 5 | devDependencies 或 dependencies 含 `electron-forge`，或 config 含 `electron-forge` | `<PKG_RUN> start`（electron-forge 默认） |
| 6 | scripts.dev 存在（普通 Web 项目） | `<PKG_RUN> dev` |
| 7 | scripts.start 存在（普通 Web 项目） | `<PKG_RUN> start` |

- 若推导成功：
  - 设置 `START_COMMAND = <推导结果>`
  - 宣告：`✅ 自动检测到启动命令：\`<command>\`（来源：package.json scripts，包管理器：<npm/yarn/pnpm>）`
  - **跳转至「Level 3b：写入 CLAUDE.md」**
- 若 package.json 不存在或无法推导：继续 Level 3（询问用户）

**Level 3：询问用户一次（业务友好语言）**

用 `AskUserQuestion` 以业务语言提问（不展示技术错误信息）：

> 我需要知道怎么启动这个应用，才能帮你自动验证效果。
>
> 请选择或输入：
> 1. 告诉我启动命令（如 `npm run dev`、`yarn start`、`electron .`）
> 2. 不知道，帮我从项目文件中判断

- 用户选 2（不知道）：重新执行 Level 2 推导；若仍无法推导，以业务语言询问项目类型（Web/Electron/其他），再尝试推导；若依然失败，请用户检查后重试
- 用户输入命令后：
  - **语义校验**：
    - 若命令形如 `<PKG_RUN> <script>`（npm/yarn/pnpm/bun run xxx）：检查 package.json 中 scripts.xxx 是否存在，若不存在则提示用户确认（`⚠️ 未在 package.json 中找到 script "<xxx>"，是否仍使用此命令？`）
    - 若命令包含 `-->` 或换行符：以业务语言提示"命令格式有误，请检查后重输"，重新提问（此为格式安全防护，防止破坏 CLAUDE.md 注释结构）
    - 其他裸命令：接受，不做额外校验
  - 校验通过后：设置 `START_COMMAND = <用户答案>`，设置 SOURCE = `user-provided`
  - **继续「Level 3b：写入 CLAUDE.md」**

**Level 3b：写入 CLAUDE.md 持久化（Level 2 推导成功 或 Level 3 用户回答后执行）**

在项目 CLAUDE.md 中追加启动命令记录（若已有 `<!-- ce-work-start-command:` 标记行则替换，否则追加到文件末尾）：

```markdown
<!-- ce-work-start-command: <command> -->
<!-- ce-work-start-command-source: auto-detected|user-provided -->
<!-- ce-work-start-command-updated: <YYYY-MM-DD> -->
```

宣告：`✅ 启动命令已记录到 CLAUDE.md，后续会话自动复用，无需再次配置`

**Level 4：验证命令可用性（格式 + 安全校验，不实际启动）**

检查 START_COMMAND：
- 若命令为空 → 以业务语言提示，重进 Level 3
- 若命令包含 `-->` 或换行符 → 以业务语言提示"命令格式有误，请检查"，重进 Level 3（**安全防护：避免破坏 CLAUDE.md HTML 注释结构**）
- 若命令形如 `<PKG_RUN> <script>`：验证 package.json 中该 script 是否存在（警告但不阻断）
- 若通过：环境指纹阶段完成，宣告：
  ```
  ✅ 环境指纹就绪：启动命令 = `<START_COMMAND>`
     Layer 2/4 验证将使用此命令启动应用
  ```

---

#### 主动漂移检测（防止 AI 修改 package.json 后启动命令失效）

**触发时机**：本次会话执行过程中，若任何步骤写入或修改了 `package.json`（任意字段，包括 `scripts`、`dependencies`、`devDependencies`、`main`、`config`、`packageManager`）：

1. **重新执行 Level 2 推导**（从磁盘新鲜读取修改后的 package.json）
2. **对比结果**：
   - 若推导结果 = 当前 START_COMMAND → 无漂移，静默继续
   - 若推导结果 ≠ 当前 START_COMMAND（或 CLAUDE.md 中的覆盖值）：
     - 宣告：`⚠️ 检测到 package.json scripts 已更新，启动命令可能已变更`
     - 展示：`旧命令：<old> → 新推导：<new>`
     - 用 `AskUserQuestion` 询问：
       > package.json 的启动脚本有更新。是否同步更新启动命令？
       > 1. 是，使用新命令 `<new>`（推荐）
       > 2. 保持旧命令 `<old>` 不变
     - 用户选 1：更新 START_COMMAND，同步更新 CLAUDE.md 标记行
     - 用户选 2：保持 START_COMMAND 不变，CLAUDE.md 保持旧覆盖值

---

### Phase 0: Input Triage

Determine how to proceed based on what was provided in `<input_document>`.

**Plan document** (input is a file path to an existing plan, specification, or todo file) → skip to Phase 1.

**Bare prompt** (input is a description of work, not a file path):

1. **Scan the work area**

   - Identify files likely to change based on the prompt
   - Find existing test files for those areas (search for test/spec files that import, reference, or share names with the implementation files)
   - Note local patterns and conventions in the affected areas

2. **Assess complexity and route**

   | Complexity | Signals | Action |
   |-----------|---------|--------|
   | **Trivial** | 1-2 files, no behavioral change (typo, config, rename) | Proceed to Phase 1 step 2 directly. Skip step 3 (Intent Gate) and step 4 ([R]). Apply Test Discovery if the change touches behavior-bearing code |
   | **Small / Medium** | Clear scope, under ~10 files | Build a task list from discovery. Proceed to Phase 1 step 2 |
   | **Large** | Cross-cutting, architectural decisions, 10+ files, touches auth/payments/migrations | Inform the user this would benefit from `/ce:brainstorm` or `/ce:plan` to surface edge cases and scope boundaries. Honor their choice. If proceeding, continue to step 3 (Intent Gate) |

3. **Intent Gate（仅限 Large 复杂度 + bare prompt）**

   触发条件：复杂度评估为 **Large** 且输入为 bare prompt（非文件路径）。跳过条件：复杂度为 Trivial/Small/Medium，或输入为文件路径。

   **路由问题**（使用 `AskUserQuestion` tool）:
   > 这个任务规模较大，建议先规划。你想：
   > 1. 先转 `/ce:plan` 创建结构化计划（推荐）
   > 2. 继续直接执行，我来补充关键信息
   > 3. 取消

   - 用户选 1（转计划）→ 调用 `/ce:plan`，结束当前执行
   - 用户选 3（取消）→ 停止执行
   - 用户选 2（继续执行）→ 进入关键信息补充

   **关键信息补充**（仅当用户选择「继续执行」时）：

   从以下 3 个维度中，针对 prompt 中**尚未明确**的部分提问：

   **目标**（如 prompt 已清楚则跳过）:
   > 这次改动最终要达成什么可验证的结果？

   **边界**（如 prompt 已指定范围则跳过）:
   > 哪些模块/文件在改动范围内？有什么明确不改的？

   **验收**（如 prompt 已包含验收标准则跳过）:
   > 怎么判断做完了？用什么标准验收？

   将用户补充的答案整合到任务列表构建中（forbidden_surfaces、acceptance criteria 等），然后继续步骤 4。

4. **[R] 历史检索（bare prompt 场景，仅当 R_MODE_ENABLED = true 时）**

   触发条件：输入为 bare prompt（非文件路径）且 R_MODE_ENABLED = true（由 Phase -1 设置）。Trivial 任务跳过（见步骤 2）。

   ```
   Task compound-engineering:research:learnings-researcher(prompt_content)
   ```

   **去重规则**（当前 skill 内有效，跨 skill 不生效）：
   同一 session 内相同关键词（lowercase + trim + token sort）不重复搜索。
   子代理派发时各子代理 in-memory 状态独立，跨子代理去重不生效（同一搜索词可能被多个子代理重复触发）。
   跨 skill 去重不生效（如先运行 ce:brainstorm [R]，再运行 ce:work [R]，相同关键词仍会重新检索）。

   检索结果注入执行上下文，不修改 plan 文档格式。在每个 Implementation Unit 执行前，
   如有相关历史经验，以注释形式提示：「📚 历史参考：[文档名] — [核心洞察]」。无匹配时写 `No relevant learnings found`，不阻断主流程。

   **[R]+[T] 组合行为**：
   - [R] 历史检索在 Phase 0 执行，结果注入 Phase 2 实现上下文
   - Layer 3 验收审查**可引用**历史经验作为补充佐证（如"历史上类似场景通过了 X 检查"）
   - 但 Layer 3 的验收标准以当前计划的验收场景为准，历史经验不改变 pass/fail 判断

---

### Phase 1: Quick Start

1. **Read Plan and Clarify** _(skip if arriving from Phase 0 with a bare prompt)_

   - Read the work document completely
   - Treat the plan as a decision artifact, not an execution script
   - If the plan includes sections such as `Implementation Units`, `Work Breakdown`, `Requirements Trace`, `Files`, `Test Scenarios`, or `Verification`, use those as the primary source material for execution
   - Check for `Execution note` on each implementation unit — these carry the plan's execution posture signal for that unit (for example, test-first or characterization-first). Note them when creating tasks.
   - Check for a `Deferred to Implementation` or `Implementation-Time Unknowns` section — these are questions the planner intentionally left for you to resolve during execution. Note them before starting so they inform your approach rather than surprising you mid-task
   - Check for a `Scope Boundaries` section — these are explicit non-goals. Refer back to them if implementation starts pulling you toward adjacent work
   - Review any references or links provided in the plan
   - If the user explicitly asks for TDD, test-first, or characterization-first execution in this session, honor that request even if the plan has no `Execution note`
   - If anything is unclear or ambiguous, ask clarifying questions now
   - Get user approval to proceed
   - **Do not skip this** - better to ask questions now than build the wrong thing

2. **Setup Environment**

   First, check the current branch:

   ```bash
   current_branch=$(git branch --show-current)
   default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

   # Fallback if remote HEAD isn't set
   if [ -z "$default_branch" ]; then
     default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
   fi
   ```

   **If already on a feature branch** (not the default branch):

   First, check whether the branch name is **meaningful** — a name like `feat/crowd-sniff` or `fix/email-validation` tells future readers what the work is about. Auto-generated worktree names (e.g., `worktree-jolly-beaming-raven`) or other opaque names do not.

   If the branch name is meaningless or auto-generated, suggest renaming it before continuing:
   ```bash
   git branch -m <meaningful-name>
   ```
   Derive the new name from the plan title or work description (e.g., `feat/crowd-sniff`). Present the rename as a recommended option alongside continuing as-is.

   Then ask: "Continue working on `[current_branch]`, or create a new branch?"
   - If continuing (with or without rename), proceed to step 3
   - If creating new, follow Option A or B below

   **If on the default branch**, choose how to proceed:

   **Option A: Create a new branch**
   ```bash
   git pull origin [default_branch]
   git checkout -b feature-branch-name
   ```
   Use a meaningful name based on the work (e.g., `feat/user-authentication`, `fix/email-validation`).

   **Option B: Use a worktree (recommended for parallel development)**
   ```bash
   skill: git-worktree
   # The skill will create a new branch from the default branch in an isolated worktree
   ```

   **Option C: Continue on the default branch**
   - Requires explicit user confirmation
   - Only proceed after user explicitly says "yes, commit to [default_branch]"
   - Never commit directly to the default branch without explicit permission

   **Recommendation**: Use worktree if:
   - You want to work on multiple features simultaneously
   - You want to keep the default branch clean while experimenting
   - You plan to switch between branches frequently

3. **Create Todo List** _(skip if Phase 0 already built one, or if Phase 0 routed as Trivial)_
   - Use your available task tracking tool (e.g., TodoWrite, task lists) to break the plan into actionable tasks
   - Derive tasks from the plan's implementation units, dependencies, files, test targets, and verification criteria
   - Carry each unit's `Execution note` into the task when present
   - For each unit, read the `Patterns to follow` field before implementing — these point to specific files or conventions to mirror
   - Use each unit's `Verification` field as the primary "done" signal for that task
   - Do not expect the plan to contain implementation code, micro-step TDD instructions, or exact shell commands
   - Include dependencies between tasks
   - Prioritize based on what needs to be done first
   - Include testing and quality check tasks
   - Keep tasks specific and completable

4. **Choose Execution Strategy**

   After creating the task list, decide how to execute based on the plan's size and dependency structure:

   | Strategy | When to use |
   |----------|-------------|
   | **Inline** | 1-2 small tasks, or tasks needing user interaction mid-flight. **Default for bare-prompt work** — bare prompts rarely produce enough structured context to justify subagent dispatch |
   | **Serial subagents** | 3+ tasks with dependencies between them. Each subagent gets a fresh context window focused on one unit — prevents context degradation across many tasks. Requires plan-unit metadata (Goal, Files, Approach, Test scenarios) |
   | **Parallel subagents** | 3+ tasks where some units have no shared dependencies and touch non-overlapping files. Dispatch independent units simultaneously, run dependent units after their prerequisites complete. Requires plan-unit metadata |

   **Subagent dispatch** uses your available subagent or task spawning mechanism. For each unit, give the subagent:
   - The full plan file path (for overall context)
   - The specific unit's Goal, Files, Approach, Execution note, Patterns, Test scenarios, and Verification
   - Any resolved deferred questions relevant to that unit
   - Instruction to check whether the unit's test scenarios cover all applicable categories (happy paths, edge cases, error paths, integration) and supplement gaps before writing tests

   **Team mode dispatch (when TEAM_MODE is active):** The verifier teammate (spawned in Phase -1) handles verification independently. Pass to each subagent:
   - TEAM_NAME（即 Phase -1 创建的团队名，如"ce-work-20260410T143022"，subagent 用它调用 SendMessage）
   - TEAM_VARIANT (default/full)
   - The content of `.team-contract.md` (allowed_files, forbidden_surfaces, required_invariants, max_files_per_patch)
   - Instruction: enforce single-writer principle — only write files in this unit's Files list, verify they are in allowed_files
   - Instruction: after completing its unit, call `SendMessage("verifier", "Unit X 已完成。变更文件：[...]。请验证。")` and await PASS/FAIL reply before marking done
   - Note: subagents share the same verifier teammate; they must use the TEAM_NAME they were passed to route messages correctly

   **Permission mode:** Omit the `mode` parameter when dispatching subagents so the user's configured permission settings apply. Do not pass `mode: "auto"` — it overrides user-level settings like `bypassPermissions`.

   After each subagent completes, update the plan checkboxes and task list before dispatching the next dependent unit.

   For genuinely large plans needing persistent inter-agent communication (agents challenging each other's approaches, shared coordination across 10+ tasks), see Swarm Mode below which uses Agent Teams.

### Phase 2: Execute

1. **Task Execution Loop**

   For each task in priority order:

   ```
   while (tasks remain):
     - Mark task as in-progress
     - Read any referenced files from the plan or discovered during Phase 0
     - Look for similar patterns in codebase
     - Find existing test files for implementation files being changed (Test Discovery — see below)
     - Implement following existing conventions
     - Add, update, or remove tests to match implementation changes (see Test Discovery below)
     - Run System-Wide Test Check (see below)
     - Run tests after changes
     - Assess testing coverage: did this task change behavior? If yes, were tests written or updated? If no tests were added, is the justification deliberate (e.g., pure config, no behavioral change)?
     - Mark task as completed
     - Evaluate for incremental commit (see below)
   ```

   When a unit carries an `Execution note`, honor it. For test-first units, write the failing test before implementation for that unit. For characterization-first units, capture existing behavior before changing it. For units without an `Execution note`, proceed pragmatically.

   Guardrails for execution posture:
   - Do not write the test and implementation in the same step when working test-first
   - Do not skip verifying that a new test fails before implementing the fix or feature
   - Do not over-implement beyond the current behavior slice when working test-first
   - Skip test-first discipline for trivial renames, pure configuration, and pure styling work

   **Test Discovery** — Before implementing changes to a file, find its existing test files (search for test/spec files that import, reference, or share naming patterns with the implementation file). When a plan specifies test scenarios or test files, start there, then check for additional test coverage the plan may not have enumerated. Changes to implementation files should be accompanied by corresponding test updates — new tests for new behavior, modified tests for changed behavior, removed or updated tests for deleted behavior.

   **Test Scenario Completeness** — Before writing tests for a feature-bearing unit, check whether the plan's `Test scenarios` cover all categories that apply to this unit. If a category is missing or scenarios are vague (e.g., "validates correctly" without naming inputs and expected outcomes), supplement from the unit's own context before writing tests:

   | Category | When it applies | How to derive if missing |
   |----------|----------------|------------------------|
   | **Happy path** | Always for feature-bearing units | Read the unit's Goal and Approach for core input/output pairs |
   | **Edge cases** | When the unit has meaningful boundaries (inputs, state, concurrency) | Identify boundary values, empty/nil inputs, and concurrent access patterns |
   | **Error/failure paths** | When the unit has failure modes (validation, external calls, permissions) | Enumerate invalid inputs the unit should reject, permission/auth denials it should enforce, and downstream failures it should handle |
   | **Integration** | When the unit crosses layers (callbacks, middleware, multi-service) | Identify the cross-layer chain and write a scenario that exercises it without mocks |

   **System-Wide Test Check** — Before marking a task done, pause and ask:

   | Question | What to do |
   |----------|------------|
   | **What fires when this runs?** Callbacks, middleware, observers, event handlers — trace two levels out from your change. | Read the actual code (not docs) for callbacks on models you touch, middleware in the request chain, `after_*` hooks. |
   | **Do my tests exercise the real chain?** If every dependency is mocked, the test proves your logic works *in isolation* — it says nothing about the interaction. | Write at least one integration test that uses real objects through the full callback/middleware chain. No mocks for the layers that interact. |
   | **Can failure leave orphaned state?** If your code persists state (DB row, cache, file) before calling an external service, what happens when the service fails? Does retry create duplicates? | Trace the failure path with real objects. If state is created before the risky call, test that failure cleans up or that retry is idempotent. |
   | **What other interfaces expose this?** Mixins, DSLs, alternative entry points (Agent vs Chat vs ChatMethods). | Grep for the method/behavior in related classes. If parity is needed, add it now — not as a follow-up. |
   | **Do error strategies align across layers?** Retry middleware + application fallback + framework error handling — do they conflict or create double execution? | List the specific error classes at each layer. Verify your rescue list matches what the lower layer actually raises. |

   **When to skip:** Leaf-node changes with no callbacks, no state persistence, no parallel interfaces. If the change is purely additive (new helper method, new view partial), the check takes 10 seconds and the answer is "nothing fires, skip."

   **When this matters most:** Any change that touches models with callbacks, error handling with fallback/retry, or functionality exposed through multiple interfaces.


2. **Incremental Commits**

   After completing each task, evaluate whether to create an incremental commit:

   | Commit when... | Don't commit when... |
   |----------------|---------------------|
   | Logical unit complete (model, service, component) | Small part of a larger unit |
   | Tests pass + meaningful progress | Tests failing |
   | About to switch contexts (backend → frontend) | Purely scaffolding with no behavior |
   | About to attempt risky/uncertain changes | Would need a "WIP" commit message |

   **Heuristic:** "Can I write a commit message that describes a complete, valuable change? If yes, commit. If the message would be 'WIP' or 'partial X', wait."

   If the plan has Implementation Units, use them as a starting guide for commit boundaries — but adapt based on what you find during implementation. A unit might need multiple commits if it's larger than expected, or small related units might land together. Use each unit's Goal to inform the commit message.

   **Commit workflow:**
   ```bash
   # 1. Verify tests pass (use project's test command)
   # Examples: bin/rails test, npm test, pytest, go test, etc.

   # 2. Stage only files related to this logical unit (not `git add .`)
   git add <files related to this logical unit>

   # 3. Commit with conventional message
   git commit -m "feat(scope): description of this unit"
   ```

   **Handling merge conflicts:** If conflicts arise during rebasing or merging, resolve them immediately. Incremental commits make conflict resolution easier since each commit is small and focused.

   **Note:** Incremental commits use clean conventional messages without attribution footers. The final Phase 4 commit/PR includes the full attribution.

3. **Follow Existing Patterns**

   - The plan should reference similar code - read those files first
   - Match naming conventions exactly
   - Reuse existing components where possible
   - Follow project coding standards (see AGENTS.md; use CLAUDE.md only if the repo still keeps a compatibility shim)
   - When in doubt, grep for similar implementations

4. **Test Continuously**

   - Run relevant tests after each significant change
   - Don't wait until the end to test
   - Fix failures immediately
   - Add new tests for new behavior, update tests for changed behavior, remove tests for deleted behavior
   - **Unit tests with mocks prove logic in isolation. Integration tests with real objects prove the layers work together.** If your change touches callbacks, middleware, or error handling — you need both.

5. **Simplify as You Go**

   After completing a cluster of related implementation units (or every 2-3 units), review recently changed files for simplification opportunities — consolidate duplicated patterns, extract shared helpers, and improve code reuse and efficiency. This is especially valuable when using subagents, since each agent works with isolated context and can't see patterns emerging across units.

   Don't simplify after every single unit — early patterns may look duplicated but diverge intentionally in later units. Wait for a natural phase boundary or when you notice accumulated complexity.

   If a `/simplify` skill or equivalent is available, use it. Otherwise, review the changed files yourself for reuse and consolidation opportunities.

7. **Figma Design Sync** (if applicable)

   For UI work with Figma designs:

   - Implement components following design specs
   - Use figma-design-sync agent iteratively to compare
   - Fix visual differences identified
   - Repeat until implementation matches design

6. **Track Progress**
   - Keep the task list updated as you complete tasks
   - Note any blockers or unexpected discoveries
   - Create new tasks if scope expands
   - Keep user informed of major milestones

### Phase 3: Quality Check

1. **Run Core Quality Checks**

   Always run before submitting:

   ```bash
   # Run full test suite (use project's test command)
   # Examples: bin/rails test, npm test, pytest, go test, etc.

   # Run linting (per AGENTS.md or CLAUDE.md lint command)
   ```

2. **Code Review** (REQUIRED)

   Every change gets reviewed before shipping. The depth scales with the change's risk profile, but review itself is never skipped.

   **Tier 2: Full review (default)** — REQUIRED unless Tier 1 criteria are explicitly met. Invoke the `ce:review` skill with `mode:autofix` to run specialized reviewer agents, auto-apply safe fixes, and surface residual work as todos. When the plan file path is known, pass it as `plan:<path>`. This is the mandatory default — proceed to Tier 1 only after confirming every criterion below.
   - If TEAM_GATE_ENABLED: also pass `[T]`（或 `[T+]`）to ce:review（确保 Patch Gate 白名单门控激活，不传则 Patch Gate 静默跳过）

   参数拼接示例：
   - 基础调用：`Skill("ce:review", "mode:autofix")`
   - 含计划路径：`Skill("ce:review", "mode:autofix plan:docs/plans/xxx.md")`
   - 含 [T]：`Skill("ce:review", "mode:autofix plan:docs/plans/xxx.md [T]")`
   - 含 [T+]：`Skill("ce:review", "mode:autofix plan:docs/plans/xxx.md [T+]")`

   注：[C]/[G] **不透传**给内嵌 ce:review。[C]/[G] 在 ce:work 层的作用是标记外部 AI 已参与整体工作流；内嵌 ce:review 仅负责代码质量把关，不涉及外部模型调用，透传只会将 safe_auto 降级为 gated_auto 而无实际收益。

   **Tier 1: Inline self-review** — A lighter alternative permitted only when **all four** criteria are true. Before choosing Tier 1, explicitly state which criteria apply and why. If any criterion is uncertain, use Tier 2.
   - Purely additive (new files only, no existing behavior modified)
   - Single concern (one skill, one component — not cross-cutting)
   - Pattern-following (implementation mirrors an existing example with no novel logic)
   - Plan-faithful (no scope growth, no deferred questions resolved with surprising answers)

3. **Final Validation**
   - All tasks marked completed
   - Testing addressed -- tests pass and new/changed behavior has corresponding test coverage (or an explicit justification for why tests are not needed)
   - Linting passes
   - Code follows existing patterns
   - Figma designs match (if applicable)
   - No console errors or warnings
   - If the plan has a `Requirements Trace`, verify each requirement is satisfied by the completed work
   - If any `Deferred to Implementation` questions were noted, confirm they were resolved during execution

4. **Prepare Operational Validation Plan** (REQUIRED)
   - Add a `## Post-Deploy Monitoring & Validation` section to the PR description for every change.
   - Include concrete:
     - Log queries/search terms
     - Metrics or dashboards to watch
     - Expected healthy signals
     - Failure signals and rollback/mitigation trigger
     - Validation window and owner
   - If there is truly no production/runtime impact, still include the section with: `No additional operational monitoring required` and a one-line reason.

---

### Phase 3.5: 四层自验证（仅当 `[T]` 时）

**触发条件**：V_MODE_ENABLED = true（在 Phase -1 中设置）。V_MODE_ENABLED = false 时跳过本节，直接进入 Phase 4。

---

#### 3.5.0 初始化验证状态

**检查 `.context/compound-engineering/ce-work-verification.json` 是否存在**（与 ce:review artifact 目录一致，避免多 worktree 根目录冲突）：

**情况 A：文件已存在且 `passes: false`**
1. 读取文件内容
2. 比对文件中的 `task_id` 和 `description` 与当前任务：
   - **匹配**（同一任务 session 中断后恢复）→ 继续步骤 3-6
   - **不匹配**（不同任务遗留的旧文件）→ 转入情况 B（覆盖旧文件，全新开始），宣告：「⚠️ 检测到旧任务的验证文件（[旧task_id]），当前任务不同，重新初始化」
3. 读取 `current_layer` 字段（如 `"layer1"`）和 `verification_rounds` 字段
4. 宣告：「🔄 检测到未完成的验证状态（session 恢复），从 [current_layer] 继续，跳过已完成的层」
5. 跳转到 Phase 3.5.2 对应层（根据 `current_layer` 值）：
   | `current_layer` 值 | 跳转到 | 含义 |
   |---|---|---|
   | `"layer0"` | Phase 3.5.2 Layer 0 节 | 从 Layer 0 重新开始 |
   | `"layer1"` | Phase 3.5.2 Layer 1 节 | 跳过 Layer 0，从 Layer 1 开始 |
   | `"layer2"` | Phase 3.5.2 Layer 2 节 | 跳过 Layer 0-1，从 Layer 2 开始 |
   | `"layer3"` | Phase 3.5.2 Layer 3 节 | 跳过 Layer 0-2，从 Layer 3 开始 |
   注：跳过的层必须在文件中状态为 `"pass"` 才可跳过，否则从最早 `"fail"` 层重新开始
6. 不重置 verification_rounds（继续累计）

**情况 B：文件不存在，或 `passes: true`（上次已成功）**
确保目录存在后新建文件：`mkdir -p .context/compound-engineering/`

```json
{
  "task_id": "<任务描述前20字（仅保留字母数字中文连字符下划线，过滤 ../等特殊字符）>-<ISO时间戳前10位,如2026-04-09>",
  "description": "<完整任务描述>",
  "verification_rounds": 0,
  "current_layer": "layer0",
  "layer0_inner_retries": 0,
  "layers": {
    "layer0": "pending",
    "layer1": "pending",
    "layer2": "pending",
    "layer3": "pending"
  },
  "passes": false
}
```

**字段说明**：
- `task_id`：`前20字 + ISO日期` 确保同日内同前缀任务不冲突
- `current_layer`：当前正在执行的层（`layer0/1/2/3`）；session 中断重启后，Phase 3.5.0 会检测此文件并从此层继续，而非全部重跑
- `layer0_inner_retries`：Layer 0 层内重试次数，上限 3 次，不计入 verification_rounds
- `passes: false` 初始值：防止验证未完成就进入 Phase 4

**只读文件系统降级**：若 `.context/compound-engineering/` 不可写（如 CI 只读容器），以内存状态继续执行：
- 所有状态变量在 session 内存中维护
- Phase 3.5 结束时输出状态摘要（代替写文件）
- 宣告：「⚠️ 根目录不可写，以内存状态模式执行验证（无 session 恢复能力）」

#### 3.5.1 Layer 触发判断

扫描当前任务描述 + 已变更文件列表，判断激活哪些层：

| 触发信号 | 激活层 | 判断依据 |
|----------|--------|----------|
| 描述含「前端/UI/组件/页面/样式/交互」或变更含 `.tsx/.vue/.html/.css` | Layer 2 | 关键词 + 扩展名 |
| 描述含「API/接口/数据库/路由/endpoint/migration」或变更含 `routes/controllers/models/migrations` | Layer 1 | 关键词 + 路径 |
| 描述含「Markdown/文档/提示词/SKILL」 | 跳过 Layer 1/2，仅 Layer 0 + Layer 3 | 关键词 |
| 始终 | Layer 0（无条件激活） | — |

**Layer 0 无命令兜底**：若项目 CLAUDE.md 中未找到构建/测试命令（如纯 Markdown/SKILL 插件项目），Layer 0 执行文件格式检查（如 markdownlint）或版本一致性检查（如 `scripts/check-versions.ps1`）。若确无任何可执行命令，记录 `layers.layer0 = "skip"`，输出：「⚠️ 未检测到构建命令，Layer 0 跳过 CLI 执行，仅记录 skip」。

不确定时：激活 Layer 0 + Layer 3，Layer 1/2 使用 **AskUserQuestion** 询问用户确认。

**全层跳过的情况**：若扫描结果所有层均判断为 `"skip"`（如纯 Markdown 项目无构建命令、无 UI、无验收场景），则：
- 设置 passes = true，写入 .context/compound-engineering/ce-work-verification.json
- 宣告：「⚠️ 未检测到验证内容，所有层跳过，标记验证通过（纯文档/无可执行验证场景）」
- 直接进入 Phase 4（跳过 Phase 3.5.2 和 3.5.3）

#### 3.5.2 验证循环（最多 2 轮）

**轮次定义**：一轮 = 所有激活层各执行一次（Layer 0 → Layer 1/2（如触发）→ Layer 3）；每轮结束后无论成功与否，`verification_rounds +1`。Layer 内部的修复重试不计入 verification_rounds。

当 `passes: false` 且 `verification_rounds < 2`，执行以下四层：

---

**Layer 0：CLI 静态检查**（始终执行）

1. 读取项目 CLAUDE.md，提取构建/测试命令（如 `npm run build`、`pytest`、`cargo test`）
2. 执行命令，捕获 exit code + stderr
3. exit code = 0 → 更新 `layers.layer0 = "pass"`
4. exit code ≠ 0 → 分析错误输出 → 修复代码/配置 → 重试 Layer 0（**不计入 verification_rounds**，属于层内重试）
   - **层内最大重试次数：3 次**。每次重试 `layer0_inner_retries +1`（记录在 .context/compound-engineering/ce-work-verification.json 或内存中）。
   - 超过 3 次后：
     - 更新 `layers.layer0 = "fail"` 并记录错误摘要
     - 继续本轮的后续激活层（Layer 1/2/3），不提前中断
     - **本轮所有层执行完毕后**，`verification_rounds +1`（Layer 0 内部重试不独立计入轮次）

---

**Layer 1：API/DB 验证**（条件执行）

*如未触发*：`layers.layer1 = "skip"`

*如触发*：
1. 读取计划验收场景中标注「Layer 1」的行
2. **认证 token 获取**（如 API 需要认证 token）：
   - **Step a**：读取项目 `.env` 或 CLAUDE.md 中记录的**测试 token**（优先使用 `TEST_API_TOKEN`、`TEST_TOKEN` 等 TEST_ 前缀变量，若只有生产 token 变量，使用 AskUserQuestion 询问用户确认再注入，不自动使用生产凭证）→ 注入 Authorization header
   - **Step b**（Step a 失败时）：识别登录端点（按优先级）：
     1. 读取 CLAUDE.md 中标注的 `test_login_endpoint` 或 `auth_endpoint` 配置
     2. 读取项目 OpenAPI/Swagger spec（如 `openapi.yaml` / `swagger.json`）中的认证端点
     3. 读取 `README.md` 中的认证流程说明
     4. 如项目关键词含 `oauth/sso/openid/saml` → 标记 skip，注明「OAuth/SSO 项目无法自动认证，Layer 1 跳过」
     5. 以上均无法确定 → 标记 skip，注明「无法识别登录端点，Layer 1 跳过（不猜测 /api/login 等路径）」
   - **Step c**（Step b 成功时）：调用识别到的登录端点获取 token，注入后续请求的 `Authorization` header
3. 若均无法获取，记录「⚠️ Layer 1 需要认证，无法自动注入，跳过 + 标记 skip」
4. 执行对应的 curl 请求或 DB CLI 查询
5. 验证响应码 + 返回体结构 + 数据库状态
6. 成功 → `layers.layer1 = "pass"`；失败 → 修复 → 重试

---

**Layer 2：浏览器 UI 验证**（条件执行）

*如未触发*：`layers.layer2 = "skip"`

*如 dev server 未运行*：
- 尝试启动；若本项目无 dev server（纯 API/CLI 项目）→ `layers.layer2 = "skip"`，记录「⚠️ 项目无 dev server，Layer 2 跳过」
- 若项目应有 dev server 但**启动失败**（可能是代码问题）→ 记录 `layers.layer2 = "fail"`，标注「⚠️ dev server 启动失败，可能是代码编译错误，Layer 2 计为失败而非跳过」（区别：不掩盖真实构建问题）
- Layer 2 URL 推断：优先读 CLAUDE.md 中的 dev server URL；其次读计划文件；若均未指定，默认 `http://localhost:3000` 并宣告使用的 URL

**工具选择由 Phase -1 的 V_PLUS_MODE_ENABLED 决定（不自动切换）**：

*V_PLUS_MODE_ENABLED = false（默认，使用 agent-browser，token 低 30-50 倍）*：

```bash
Skill("agent-browser")   # 加载 skill 文档（了解 CLI 语法和可用命令）
# ⚠️ 上方 Skill 调用仅加载文档。以下命令需通过 Bash 工具执行（`npx agent-browser ...`）：
agent-browser open <dev-server-url>                  # 从 CLAUDE.md 或计划获取 URL
agent-browser snapshot -i --json                     # 获取可交互元素（带 ref）
agent-browser click @e<N>                            # 根据验收场景执行操作
agent-browser screenshot verification-<timestamp>.png  # 捕获视觉证据（timestamp 使用 ISO 格式，跨平台兼容）
```

*V_PLUS_MODE_ENABLED = true（用户显式传入 `[V+]`，使用 Playwright MCP）*——适用于网络请求拦截、JS 执行、拖拽、文件上传：
- `mcp__playwright__browser_navigate` + `mcp__playwright__browser_snapshot`
- `mcp__playwright__browser_console_messages`（捕获 console 错误）
- `mcp__playwright__browser_network_requests`（拦截 API 调用）
- `mcp__playwright__browser_evaluate`（执行 JS 断言）

**铁律：不基于任务关键词自动升级到 Playwright MCP。用户传 [V+] 才用。**

成功 → `layers.layer2 = "pass"`；失败 → 修复 → 重试

---

**Layer 3：验收确认**（始终执行——独立 reviewer 视角）

> 「不信任实现者报告」原则（Superpowers spec-reviewer 原则）：独立读取变更文件，不依赖执行阶段的自我声明。

1. 读取计划文件中的「验收场景」章节
2. **若无验收场景章节**：输出警告 "⚠️ 计划中无验收场景，切换宽松核查模式"，转为对照任务需求逐条检查已修改文件
3. 逐条独立读取所有变更文件（使用文件读取工具，不依赖内存中的已有内容），对照验收场景核查：
   - 功能是否实现？（检查代码/Markdown 逻辑）
   - 是否遗漏边界条件？
   - 与验收场景逐条比对
4. 发现未达标项 → 列出 → 修复 → 重试 Layer 3

**[V]+[T] 职责矩阵**：

| 职责 | Phase 3.5 Layer 3 | team 验证者 Hook |
|------|-------------------|-----------------|
| 触发时机 | 所有任务完成后（Phase 3.5） | 每个 Implementation Unit 完成后 |
| 检查范围 | 跨任务全局一致性 | 单任务局部正确性 |
| 读取方式 | 独立读所有变更文件（不信任执行者报告） | 运行测试命令 + 不变式检查 |
| 失败行为 | 进入 BLOCKED（AskUserQuestion 三选一） | 停止当前 Unit，等待执行者修复 |
| 重复检查 | 只核查跨任务维度条目，不重复局部已覆盖条目 | 不关注跨任务组合 |

**[V] + [T] 特殊处理**：
- **Layer 3 delegation**：[T] 模式的验证者 Hook 在每任务后运行（时机早于 Phase 3.5，逐任务局部验证）。Phase 3.5 的 Layer 3 执行轻量全局确认：
  - **精确职责**：只核查验收场景表中跨任务维度的条目（如"整体流程通过"类场景），不重复核查已被 team 验证者 Hook 覆盖的单任务条目
  - **跨任务组合问题处理**：若发现跨任务组合破坏了不变式，记录到 `.context/compound-engineering/ce-work-verification.json` 的 Layer 3 失败信息，进入标准 BLOCKED 流程（AskUserQuestion 三选一），不触发新一轮 team 验证者 Hook
  - 状态标记：`layers.layer3 = "delegated-to-team+light-check"`（team Hook 已完成局部验证，Phase 3.5 补充全局一致性确认）
  - 若计划无验收场景章节：标记 `"delegated-to-team"`，跳过 Phase 3.5 的 Layer 3

- **BLOCKED 合并**：[V]+[T] 同时激活且验证失败时，使用标准 AskUserQuestion 工具（与非 team 模式相同），在提示文字中标注「团队模式」：
  > "⚠️ [V]+[T] 验证未通过（已重试 N 轮）
  > 失败层：[层名] — [失败原因摘要]
  > Layer 0 层内重试：[layer0_inner_retries] 次
  >
  > 1. 查看详细错误，执行者手动修复后重新运行验证（重置 verification_rounds）
  > 2. 跳过验证，降级为标准模式继续 Phase 4
  > 3. 停止，稍后处理"

---

#### 3.5.3 更新状态并处理结果

每层执行后更新 `.context/compound-engineering/ce-work-verification.json`；`verification_rounds` 每轮 +1。

**所有激活层通过（passes: true）**：

```json
{
  "verification_rounds": 1,
  "layers": { "layer0": "pass", "layer1": "skip", "layer2": "pass", "layer3": "pass" },
  "passes": true
}
```

展示验证摘要：
```
✅ [T] 验证通过（第 N 轮）
  Layer 0: pass  ✅
  Layer 1: skip  —
  Layer 2: pass  ✅ (截图: verification-<ts>.png)
  Layer 3: pass  ✅
```

继续 **Phase 4（Ship It）**。

**[V]+[T] 委派状态的 passes 判断规则**：
- `layers.layer3 = "delegated-to-team"`：该层在 passes 判断中**不计入失败**（team 验证者 Hook 已全权处理，无验收场景章节时跳过 Phase 3.5 Layer 3 是设计如此）
- `layers.layer3 = "delegated-to-team+light-check"` 且全局一致性检查失败：**计入失败**，进入标准 BLOCKED 流程（AskUserQuestion 三选一）

**第 2 轮结束仍有层失败（BLOCKED）**：

使用 **AskUserQuestion** 工具询问：
> "⚠️ [T] 验证未通过（已重试 2 轮）
> 失败层：[层名] — [失败原因摘要]
> （Layer 0 层内重试次数：[layer0_inner_retries] 次）
>
> 1. 查看详细错误，手动修复后重新运行验证（重置轮次）
> 2. 跳过验证，降级为标准模式继续 Phase 4
> 3. 停止，稍后处理"

Based on selection:
- 选 1 → 展示完整错误，等用户修复后重新执行 Phase 3.5（verification_rounds 重置为 0）
- 选 2 → 继续 Phase 4，在 PR 描述中标注「⚠️ 验证未通过，人工跳过」
- 选 3 → 结束流程，保留 `.context/compound-engineering/ce-work-verification.json` 供后续参考

---

### Phase 4: Ship It

1. **Capture and Upload Screenshots for UI Changes** (REQUIRED for any UI work)

   For **any** design changes, new views, or UI modifications, capture and upload screenshots before creating the PR:

   **Step 1: Start dev server** (if not running)
   ```bash
   bin/dev  # Run in background
   ```

   **Step 2: Capture screenshots with agent-browser CLI**
   ```bash
   agent-browser open http://localhost:3000/[route]
   agent-browser snapshot -i
   agent-browser screenshot output.png
   ```
   See the `agent-browser` skill for detailed usage.

   **Step 3: Upload screenshots**
   Upload screenshots using any available image hosting service or share them directly in the conversation.

   **What to capture:**
   - **New screens**: Screenshot of the new UI
   - **Modified screens**: Before AND after screenshots
   - **Design implementation**: Screenshot showing Figma design match

2. **Commit and Create Pull Request**

   Load the `git-commit-push-pr` skill to handle committing, pushing, and PR creation. The skill handles convention detection, branch safety, logical commit splitting, adaptive PR descriptions, and attribution badges.

   When providing context for the PR description, include:
   - The plan's summary and key decisions
   - Testing notes (tests added/modified, manual testing performed)
   - Screenshot URLs from step 1 (if applicable)
   - Figma design link (if applicable)
   - The Post-Deploy Monitoring & Validation section (see Phase 3 Step 4)

   If the user prefers to commit without creating a PR, load the `git-commit` skill instead.

3. **Update Plan Status**

   If the input document has YAML frontmatter with a `status` field, update it to `completed`:
   ```
   status: active  →  status: completed
   ```

4. **Notify User**
   - Summarize what was completed
   - Link to PR (if one was created)
   - Note any follow-up work needed

5. **[T] 模式：销毁团队**（仅当 TEAM_GATE_ENABLED = true）

   PR 创建完成后，销毁 Agent Teams：
   ```
   TeamDelete(TEAM_NAME)
   ```
   宣告：「✅ Agent Team `{TEAM_NAME}` 已销毁，资源释放完毕。」

### Handoff

使用 **AskUserQuestion** 工具询问：

> "功能已完成。下一步？
>
> 1. **代码审查（推荐）** — `/ce:review mode:autofix plan:<计划路径>` 进行结构化审查
> 2. **直接创建 PR** — `/workflows:pr`
> 3. **完成** — 无需额外操作"

Based on selection:
- 选 1 → 调用 `ce:review` skill，传入 `mode:autofix`，plan 路径已知则传入（加 `[T]` 如果 TEAM_GATE_ENABLED）
- 选 2 → 执行 `/workflows:pr` command
- 选 3 → 结束流程

---

## Swarm Mode with Agent Teams (Optional)

For genuinely large plans where agents need to communicate with each other, challenge approaches, or coordinate across 10+ tasks with persistent specialized roles, use agent team capabilities if available (e.g., Agent Teams in Claude Code, multi-agent workflows in Codex).

**Agent teams are typically experimental and require opt-in.** Do not attempt to use agent teams unless the user explicitly requests swarm mode or agent teams, and the platform supports it.

### When to Use Agent Teams vs Subagents

| Agent Teams | Subagents (standard mode) |
|-------------|---------------------------|
| Agents need to discuss and challenge each other's approaches | Each task is independent — only the result matters |
| Persistent specialized roles (e.g., dedicated tester running continuously) | Workers report back and finish |
| 10+ tasks with complex cross-cutting coordination | 3-8 tasks with clear dependency chains |
| User explicitly requests "swarm mode" or "agent teams" | Default for most plans |

Most plans should use subagent dispatch from standard mode. Agent teams add significant token cost and coordination overhead — use them when the inter-agent communication genuinely improves the outcome.

### Agent Teams Workflow

1. **Create team** — use your available team creation mechanism
2. **Create task list** — parse Implementation Units into tasks with dependency relationships
3. **Spawn teammates** — assign specialized roles (implementer, tester, reviewer) based on the plan's needs. Give each teammate the plan file path and their specific task assignments
4. **Coordinate** — the lead monitors task completion, reassigns work if someone gets stuck, and spawns additional workers as phases unblock
5. **Cleanup** — shut down all teammates, then clean up the team resources

---

## Key Principles

### Start Fast, Execute Faster

- Get clarification once at the start, then execute
- Don't wait for perfect understanding - ask questions and move
- The goal is to **finish the feature**, not create perfect process

### The Plan is Your Guide

- Work documents should reference similar code and patterns
- Load those references and follow them
- Don't reinvent - match what exists

### Test As You Go

- Run tests after each change, not at the end
- Fix failures immediately
- Continuous testing prevents big surprises

### Quality is Built In

- Follow existing patterns
- Write tests for new code
- Run linting before pushing
- Review every change — inline for simple additive work, full review for everything else

### Ship Complete Features

- Mark all tasks completed before moving on
- Don't leave features 80% done
- A finished feature that ships beats a perfect feature that doesn't

## Quality Checklist

Before creating PR, verify:

- [ ] All clarifying questions asked and answered
- [ ] All tasks marked completed
- [ ] Testing addressed -- tests pass AND new/changed behavior has corresponding test coverage (or an explicit justification for why tests are not needed)
- [ ] Linting passes (run project lint command per CLAUDE.md/AGENTS.md)
- [ ] Code follows existing patterns
- [ ] Figma designs match implementation (if applicable)
- [ ] Before/after screenshots captured and uploaded (for UI changes)
- [ ] Commit messages follow conventional format
- [ ] PR description includes Post-Deploy Monitoring & Validation section (or explicit no-impact rationale)
- [ ] Code review completed (inline self-review or full `ce:review`)
- [ ] PR description includes summary, testing notes, and screenshots
- [ ] PR description includes Compound Engineered badge with accurate model and harness

## Code Review Tiers

Every change gets reviewed. The tier determines depth, not whether review happens.

**Tier 2 (full review)** — REQUIRED default. Invoke `ce:review mode:autofix` with `plan:<path>` when available. Safe fixes are applied automatically; residual work surfaces as todos. Always use this tier unless all four Tier 1 criteria are explicitly confirmed.

**Tier 1 (inline self-review)** — permitted only when all four are true (state each explicitly before choosing):
- Purely additive (new files only, no existing behavior modified)
- Single concern (one skill, one component — not cross-cutting)
- Pattern-following (mirrors an existing example, no novel logic)
- Plan-faithful (no scope growth, no surprising deferred-question resolutions)

## Common Pitfalls to Avoid

- **Analysis paralysis** - Don't overthink, read the plan and execute
- **Skipping clarifying questions** - Ask now, not after building wrong thing
- **Ignoring plan references** - The plan has links for a reason
- **Testing at the end** - Test continuously or suffer later
- **Forgetting to track progress** - Update task status as you go or lose track of what's done
- **80% done syndrome** - Finish the feature, don't move on early
- **Skipping review** - Every change gets reviewed; only the depth varies
