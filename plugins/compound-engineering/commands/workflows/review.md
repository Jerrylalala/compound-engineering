---
name: workflows:review
description: "Step 4: [C][G] 使用多代理分析进行全面代码审查"
argument-hint: "[PR number, GitHub URL, branch name, or latest] [C] [G]"
---

# Review Command

<command_purpose> Perform exhaustive code reviews using multi-agent analysis, ultra-thinking, and Git worktrees for deep local inspection. </command_purpose>

## Introduction

<role>Senior Code Review Architect with expertise in security, performance, architecture, and quality assurance</role>

## 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| PR 号 | GitHub PR 编号 | `/workflows:review 123` |
| URL | GitHub PR URL | `/workflows:review https://github.com/.../pull/123` |
| 分支名 | 审核指定分支 | `/workflows:review feature-branch` |
| `[C]` | **自动调用 Codex 额外审核** | `/workflows:review [C]` |
| `[G]` | **自动调用 Gemini 额外审核** | `/workflows:review [G]` |

<!-- CLAUDE-CODE-ONLY-START -->
**注意**：`[C]` 和 `[G]` 参数仅在 Claude Code 中有效。转换到 Codex/Gemini 后不需要这些参数。
<!-- CLAUDE-CODE-ONLY-END -->

**示例：**
```bash
/workflows:review              # 审核当前分支
/workflows:review 123          # 审核 PR #123
/workflows:review [C]          # 审核当前分支 + Codex 审核
/workflows:review [G]          # 审核当前分支 + Gemini 审核
/workflows:review [C][G]       # 审核当前分支 + Codex + Gemini 双重审核
/workflows:review 123 [C][G]   # 审核 PR #123 + 双重审核
```

> **Performance Tip**: For large PRs or multi-tool reviews ([C][G]), consider enabling `/fast` before running the review. Fast mode uses the same Opus 4.6 model with faster output, reducing review time by ~40%.

## Prerequisites

<requirements>
- Git repository with GitHub CLI (`gh`) installed and authenticated
- Clean main/master branch
- Proper permissions to create worktrees and access the repository
- For document reviews: Path to a markdown file or document
- **For Codex review `[C]`**: Codex CLI installed (`npm install -g @openai/codex`)
- **For Gemini review `[G]`**: Gemini CLI installed (`npm install -g @google/gemini-cli`)
</requirements>

## Main Tasks

### 0. 解析参数（检测 [C] 和 [G] 标志）

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

剩余部分作为审核目标
```

**记住这些标志，审核完成后根据它们决定是否自动调用 Codex/Gemini。**

</argument_parsing>

### 1. Determine Review Target & Setup (ALWAYS FIRST)

<review_target> #$ARGUMENTS (移除 [C] [G] 后的部分) </review_target>

<thinking>
First, I need to determine the review target type and set up the code for analysis.
Check if [C] flag is present - if yes, will auto-run Codex review at the end.
Check if [G] flag is present - if yes, will auto-run Gemini review at the end.
</thinking>

#### Immediate Actions:

<task_list>

- [ ] Determine review type: PR number (numeric), GitHub URL, file path (.md), or empty (current branch)
- [ ] Check current git branch
- [ ] If ALREADY on the target branch (PR branch, requested branch name, or the branch already checked out for review) → proceed with analysis on current branch
- [ ] If DIFFERENT branch than the review target → offer to use worktree: "Use git-worktree skill for isolated review." Call `skill: git-worktree` with branch name
- [ ] Fetch PR metadata using `gh pr view --json` for title, body, files, linked issues
- [ ] Set up language-specific analysis tools
- [ ] Prepare security scanning environment
- [ ] Make sure we are on the branch we are reviewing. Use gh pr checkout to switch to the branch or manually checkout the branch.

Ensure that the code is ready for analysis (either in worktree or on current branch). ONLY then proceed to the next step.

</task_list>

#### Protected Artifacts

<protected_artifacts>
The following paths are compound-engineering pipeline artifacts and must never be flagged for deletion, removal, or gitignore by any review agent:

- `docs/plans/*.md` — Plan files created by `/workflows:plan`. These are living documents that track implementation progress (checkboxes are checked off by `/workflows:work`).
- `docs/solutions/*.md` — Solution documents created during the pipeline.

If a review agent flags any file in these directories for cleanup or removal, discard that finding during synthesis. Do not create a todo for it.
</protected_artifacts>

#### Parallel Agents to review the PR:

<parallel_tasks>

Run ALL or most of these agents at the same time:

1. Task kieran-rails-reviewer(PR content)
2. Task dhh-rails-reviewer(PR title)
3. Task git-history-analyzer(PR content)
4. Task pattern-recognition-specialist(PR content)
5. Task architecture-strategist(PR content)
6. Task security-sentinel(PR content)
7. Task performance-oracle(PR content)
8. Task data-integrity-guardian(PR content)
9. Task agent-native-reviewer(PR content) - Verify new features are agent-accessible

</parallel_tasks>

#### Conditional Agents (Run if applicable):

<conditional_agents>

These agents are run ONLY when the PR matches specific criteria. Check the PR files list to determine if they apply:

**If PR contains database migrations (db/migrate/*.rb files) or data backfills:**

14. Task data-migration-expert(PR content) - Validates ID mappings match production, checks for swapped values, verifies rollback safety
15. Task deployment-verification-agent(PR content) - Creates Go/No-Go deployment checklist with SQL verification queries

**When to run migration agents:**
- PR includes files matching `db/migrate/*.rb`
- PR modifies columns that store IDs, enums, or mappings
- PR includes data backfill scripts or rake tasks
- PR changes how data is read/written (e.g., changing from FK to string column)
- PR title/body mentions: migration, backfill, data transformation, ID mapping

**What these agents check:**
- `data-migration-expert`: Verifies hard-coded mappings match production reality (prevents swapped IDs), checks for orphaned associations, validates dual-write patterns
- `deployment-verification-agent`: Produces executable pre/post-deploy checklists with SQL queries, rollback procedures, and monitoring plans

</conditional_agents>

### 2. Ultra-Thinking Deep Dive Phases

<ultrathink_instruction> For each phase below, spend maximum cognitive effort. Think step by step. Consider all angles. Question assumptions. And bring all reviews in a synthesis to the user.</ultrathink_instruction>

<deliverable>
Complete system context map with component interactions
</deliverable>

#### Phase 3: Stakeholder Perspective Analysis

<thinking_prompt> ULTRA-THINK: Put yourself in each stakeholder's shoes. What matters to them? What are their pain points? </thinking_prompt>

<stakeholder_perspectives>

1. **Developer Perspective** <questions>

   - How easy is this to understand and modify?
   - Are the APIs intuitive?
   - Is debugging straightforward?
   - Can I test this easily? </questions>

2. **Operations Perspective** <questions>

   - How do I deploy this safely?
   - What metrics and logs are available?
   - How do I troubleshoot issues?
   - What are the resource requirements? </questions>

3. **End User Perspective** <questions>

   - Is the feature intuitive?
   - Are error messages helpful?
   - Is performance acceptable?
   - Does it solve my problem? </questions>

4. **Security Team Perspective** <questions>

   - What's the attack surface?
   - Are there compliance requirements?
   - How is data protected?
   - What are the audit capabilities? </questions>

5. **Business Perspective** <questions>
   - What's the ROI?
   - Are there legal/compliance risks?
   - How does this affect time-to-market?
   - What's the total cost of ownership? </questions> </stakeholder_perspectives>

#### Phase 4: Scenario Exploration

<thinking_prompt> ULTRA-THINK: Explore edge cases and failure scenarios. What could go wrong? How does the system behave under stress? </thinking_prompt>

<scenario_checklist>

- [ ] **Happy Path**: Normal operation with valid inputs
- [ ] **Invalid Inputs**: Null, empty, malformed data
- [ ] **Boundary Conditions**: Min/max values, empty collections
- [ ] **Concurrent Access**: Race conditions, deadlocks
- [ ] **Scale Testing**: 10x, 100x, 1000x normal load
- [ ] **Network Issues**: Timeouts, partial failures
- [ ] **Resource Exhaustion**: Memory, disk, connections
- [ ] **Security Attacks**: Injection, overflow, DoS
- [ ] **Data Corruption**: Partial writes, inconsistency
- [ ] **Cascading Failures**: Downstream service issues </scenario_checklist>

### 3. Multi-Angle Review Perspectives

#### Technical Excellence Angle

- Code craftsmanship evaluation
- Engineering best practices
- Technical documentation quality
- Tooling and automation assessment

#### Business Value Angle

- Feature completeness validation
- Performance impact on users
- Cost-benefit analysis
- Time-to-market considerations

#### Risk Management Angle

- Security risk assessment
- Operational risk evaluation
- Compliance risk verification
- Technical debt accumulation

#### Team Dynamics Angle

- Code review etiquette
- Knowledge sharing effectiveness
- Collaboration patterns
- Mentoring opportunities

### 4. Simplification and Minimalism Review

Run the Task code-simplicity-reviewer() to see if we can simplify the code.

### 5. Findings Synthesis and Todo Creation Using file-todos Skill

<critical_requirement> ALL findings MUST be stored in the todos/ directory using the file-todos skill. Create todo files immediately after synthesis - do NOT present findings for user approval first. Use the skill for structured todo management. </critical_requirement>

#### Step 1: Synthesize All Findings

<thinking>
Consolidate all agent reports into a categorized list of findings.
Remove duplicates, prioritize by severity and impact.
</thinking>

<synthesis_tasks>

- [ ] Collect findings from all parallel agents
- [ ] Discard any findings that recommend deleting or gitignoring files in `docs/plans/` or `docs/solutions/` (see Protected Artifacts above)
- [ ] Categorize by type: security, performance, architecture, quality, etc.
- [ ] Assign severity levels: 🔴 CRITICAL (P1), 🟡 IMPORTANT (P2), 🔵 NICE-TO-HAVE (P3)
- [ ] Remove duplicate or overlapping findings
- [ ] Estimate effort for each finding (Small/Medium/Large)

</synthesis_tasks>

#### Step 2: Create Todo Files Using file-todos Skill

<critical_instruction> Use the file-todos skill to create todo files for ALL findings immediately. Do NOT present findings one-by-one asking for user approval. Create all todo files in parallel using the skill, then summarize results to user. </critical_instruction>

**Implementation Options:**

**Option A: Direct File Creation (Fast)**

- Create todo files directly using Write tool
- All findings in parallel for speed
- Use standard template from `${CLAUDE_PLUGIN_ROOT}/skills/file-todos/assets/todo-template.md`
- Follow naming convention: `{issue_id}-pending-{priority}-{description}.md`

**Option B: Sub-Agents in Parallel (Recommended for Scale)** For large PRs with 15+ findings, use sub-agents to create finding files in parallel:

```bash
# Launch multiple finding-creator agents in parallel
Task() - Create todos for first finding
Task() - Create todos for second finding
Task() - Create todos for third finding
etc. for each finding.
```

Sub-agents can:

- Process multiple findings simultaneously
- Write detailed todo files with all sections filled
- Organize findings by severity
- Create comprehensive Proposed Solutions
- Add acceptance criteria and work logs
- Complete much faster than sequential processing

**Execution Strategy:**

1. Synthesize all findings into categories (P1/P2/P3)
2. Group findings by severity
3. Launch 3 parallel sub-agents (one per severity level)
4. Each sub-agent creates its batch of todos using the file-todos skill
5. Consolidate results and present summary

**Process (Using file-todos Skill):**

1. For each finding:

   - Determine severity (P1/P2/P3)
   - Write detailed Problem Statement and Findings
   - Create 2-3 Proposed Solutions with pros/cons/effort/risk
   - Estimate effort (Small/Medium/Large)
   - Add acceptance criteria and work log

2. Use file-todos skill for structured todo management:

   ```bash
   skill: file-todos
   ```

   The skill provides:

   - Template location: `${CLAUDE_PLUGIN_ROOT}/skills/file-todos/assets/todo-template.md`
   - Naming convention: `{issue_id}-{status}-{priority}-{description}.md`
   - YAML frontmatter structure: status, priority, issue_id, tags, dependencies
   - All required sections: Problem Statement, Findings, Solutions, etc.

3. Create todo files in parallel:

   ```bash
   {next_id}-pending-{priority}-{description}.md
   ```

4. Examples:

   ```
   001-pending-p1-path-traversal-vulnerability.md
   002-pending-p1-api-response-validation.md
   003-pending-p2-concurrency-limit.md
   004-pending-p3-unused-parameter.md
   ```

5. Follow template structure from file-todos skill: `${CLAUDE_PLUGIN_ROOT}/skills/file-todos/assets/todo-template.md`

**Todo File Structure (from template):**

Each todo must include:

- **YAML frontmatter**: status, priority, issue_id, tags, dependencies
- **Problem Statement**: What's broken/missing, why it matters
- **Findings**: Discoveries from agents with evidence/location
- **Proposed Solutions**: 2-3 options, each with pros/cons/effort/risk
- **Recommended Action**: (Filled during triage, leave blank initially)
- **Technical Details**: Affected files, components, database changes
- **Acceptance Criteria**: Testable checklist items
- **Work Log**: Dated record with actions and learnings
- **Resources**: Links to PR, issues, documentation, similar patterns

**File naming convention:**

```
{issue_id}-{status}-{priority}-{description}.md

Examples:
- 001-pending-p1-security-vulnerability.md
- 002-pending-p2-performance-optimization.md
- 003-pending-p3-code-cleanup.md
```

**Status values:**

- `pending` - New findings, needs triage/decision
- `ready` - Approved by manager, ready to work
- `complete` - Work finished

**Priority values:**

- `p1` - Critical (blocks merge, security/data issues)
- `p2` - Important (should fix, architectural/performance)
- `p3` - Nice-to-have (enhancements, cleanup)

**Tagging:** Always add `code-review` tag, plus: `security`, `performance`, `architecture`, `rails`, `quality`, etc.

#### Step 3: Summary Report

After creating all todo files, present comprehensive summary:

````markdown
## ✅ Code Review Complete

**Review Target:** PR #XXXX - [PR Title] **Branch:** [branch-name]

### Findings Summary:

- **Total Findings:** [X]
- **🔴 CRITICAL (P1):** [count] - BLOCKS MERGE
- **🟡 IMPORTANT (P2):** [count] - Should Fix
- **🔵 NICE-TO-HAVE (P3):** [count] - Enhancements

### Created Todo Files:

**P1 - Critical (BLOCKS MERGE):**

- `001-pending-p1-{finding}.md` - {description}
- `002-pending-p1-{finding}.md` - {description}

**P2 - Important:**

- `003-pending-p2-{finding}.md` - {description}
- `004-pending-p2-{finding}.md` - {description}

**P3 - Nice-to-Have:**

- `005-pending-p3-{finding}.md` - {description}

### Review Agents Used:

- kieran-rails-reviewer
- security-sentinel
- performance-oracle
- architecture-strategist
- agent-native-reviewer
- [other agents]

### Next Steps:

1. **Address P1 Findings**: CRITICAL - must be fixed before merge

   - Review each P1 todo in detail
   - Implement fixes or request exemption
   - Verify fixes before merging PR

2. **Triage All Todos**:
   ```bash
   ls todos/*-pending-*.md  # View all pending todos
   /triage                  # Use slash command for interactive triage
   ```

3. **Work on Approved Todos**:

   ```bash
   /resolve_todo_parallel  # Fix all approved items efficiently
   ```

4. **Track Progress**:
   - Rename file when status changes: pending → ready → complete
   - Update Work Log as you work
   - Commit todos: `git add todos/ && git commit -m "refactor: add code review findings"`

### Severity Breakdown:

**🔴 P1 (Critical - Blocks Merge):**

- Security vulnerabilities
- Data corruption risks
- Breaking changes
- Critical architectural issues

**🟡 P2 (Important - Should Fix):**

- Performance issues
- Significant architectural concerns
- Major code quality problems
- Reliability issues

**🔵 P3 (Nice-to-Have):**

- Minor improvements
- Code cleanup
- Optimization opportunities
- Documentation updates
````

### 可选：边缘案例狩猎

如果审查范围涉及用户输入处理、状态管理或并发逻辑，执行边缘案例分析：

1. **识别输入边界**：空值、极端值、非法格式、Unicode 特殊字符
2. **状态转换**：是否有未覆盖的状态组合？中间状态是否安全？
3. **并发场景**：多用户/多会话同时操作是否安全？
4. **失败路径**：网络断开、文件锁定、权限不足时的行为

将发现的边缘案例添加到审查报告的"风险"部分。

### Workflow Handoff

After all findings are addressed (or triaged), use **AskUserQuestion tool**:

**Question:** "代码审查流程完成。下一步？"

**Options:**
1. **记录解决方案** - 运行 `/workflows:compound` 记录本次解决的问题（推荐，如有非 trivial 修复）
2. **创建 PR `/workflows:pr`** - 创建 Pull Request 并可选合并
3. **保存上下文** - 运行 `/workflows:save` 保存项目状态
4. **完成** - 审查流程结束，无需额外操作

Based on selection:
- **记录解决方案** → 调用 `/workflows:compound`
- **创建 PR `/workflows:pr`** → 调用 `/workflows:pr`
- **保存上下文** → 调用 `/workflows:save`
- **完成** → 结束流程

### 6. End-to-End Testing (Optional)

<detect_project_type>

**First, detect the project type from PR files:**

| Indicator | Project Type |
|-----------|--------------|
| `*.xcodeproj`, `*.xcworkspace`, `Package.swift` (iOS) | iOS/macOS |
| `Gemfile`, `package.json`, `app/views/*`, `*.html.*` | Web |
| Both iOS files AND web files | Hybrid (test both) |

</detect_project_type>

<offer_testing>

After presenting the Summary Report, offer appropriate testing based on project type:

**For Web Projects:**
```markdown
**"Want to run browser tests on the affected pages?"**
1. Yes - run `/test-browser`
2. No - skip
```

**For iOS Projects:**
```markdown
**"Want to run Xcode simulator tests on the app?"**
1. Yes - run `/xcode-test`
2. No - skip
```

**For Hybrid Projects (e.g., Rails + Hotwire Native):**
```markdown
**"Want to run end-to-end tests?"**
1. Web only - run `/test-browser`
2. iOS only - run `/xcode-test`
3. Both - run both commands
4. No - skip
```

</offer_testing>

#### If User Accepts Web Testing:

Spawn a subagent to run browser tests (preserves main context):

```
Task general-purpose("Run /test-browser for PR #[number]. Test all affected pages, check for console errors, handle failures by creating todos and fixing.")
```

The subagent will:
1. Identify pages affected by the PR
2. Navigate to each page and capture snapshots (using Playwright MCP or agent-browser CLI)
3. Check for console errors
4. Test critical interactions
5. Pause for human verification on OAuth/email/payment flows
6. Create P1 todos for any failures
7. Fix and retry until all tests pass

**Standalone:** `/test-browser [PR number]`

#### If User Accepts iOS Testing:

Spawn a subagent to run Xcode tests (preserves main context):

```
Task general-purpose("Run /xcode-test for scheme [name]. Build for simulator, install, launch, take screenshots, check for crashes.")
```

The subagent will:
1. Verify XcodeBuildMCP is installed
2. Discover project and schemes
3. Build for iOS Simulator
4. Install and launch app
5. Take screenshots of key screens
6. Capture console logs for errors
7. Pause for human verification (Sign in with Apple, push, IAP)
8. Create P1 todos for any failures
9. Fix and retry until all tests pass

**Standalone:** `/xcode-test [scheme]`

### 7. Codex 额外审核（参数 `[C]` 触发）

<codex_auto_review>

**检查 Step 0 中解析的 CODEX_ENABLED 标志：**

```
如果 CODEX_ENABLED = true（命令参数包含 [C]）：
  → 自动执行 Codex 审核
  → 整合结果到报告

如果 CODEX_ENABLED = false（命令参数不包含 [C]）：
  → 跳过此步骤
  → 直接显示最终报告
```

</codex_auto_review>

#### 当 CODEX_ENABLED = true 时，自动执行：

<codex_execution>

**Step 7.1: 检查 Codex CLI 可用性**

```bash
command -v codex || echo "Codex CLI 未安装，请运行: npm install -g @openai/codex"
```

如果未安装，提示用户安装并跳过 Codex 审核（其他审核结果仍然有效）。

**Step 7.2: 使用 codex exec 非交互模式审核（带超时保护）**

<codex_exec_strategy>

**技术方案**：`codex exec --json` + 后台执行 + 超时保护

基于 [Codex 非交互模式文档](https://developers.openai.com/codex/noninteractive)，使用 `codex exec` 替代交互式 `codex` 命令。

**优势**：
- 官方推荐的脚本/CI 集成方式
- 支持 JSONL 事件流，可监控进度
- 支持 `--output-last-message` 直接输出结果到文件

</codex_exec_strategy>

**执行流程（Claude 必须遵循）**：

```
Step 1: 后台启动 Codex
  - 使用 Bash 工具，设置 run_in_background=true
  - 调用: ./scripts/codex-review-now.sh uncommitted 300
  - 记录返回的 task_id

Step 2: 立即向用户显示进度提示
  "⏳ Codex 审核已启动（后台运行）
   - 使用 codex exec 非交互模式
   - 超时阈值：5 分钟
   - Claude 审核结果已展示，Codex 结果稍后追加"

Step 3: 轮询检查（每 30 秒一次，最多 10 次 = 5 分钟）
  使用 TaskOutput 工具：
  - TaskOutput(task_id=xxx, block=false, timeout=5000)
  - 检查任务是否完成

Step 4: 根据结果处理
  如果正常完成（exit code 0）：
    → 读取输出，整合到报告

  如果超时（exit code 124）：
    → 显示超时提示和备选方案
    → 提供手动命令供用户稍后查看

  如果失败（其他 exit code）：
    → 显示错误信息
    → 建议用户手动运行交互式 codex
```

**调用命令**：

```bash
# 后台执行 Codex 审核脚本
# 参数1: scope (uncommitted/staged/branch/all)
# 参数2: timeout_seconds (默认 300 = 5分钟)
./scripts/codex-review-now.sh uncommitted 300
```

**脚本特性**（`scripts/codex-review-now.sh` v2）：
- 使用 `codex exec -m gpt-5.3-codex --json --output-last-message` 非交互模式
- 通过 stdin 传递 prompt（避免超长参数问题）
- 解析 JSONL 事件流显示进度
- 内置软/硬超时保护
- 超时后保留部分输出和事件日志

**Step 7.3: 整合 Codex 审核结果**

将 Codex 的发现整合到审核报告中：

```markdown
---

## 🤖 Codex 额外审核结果

**审核时间：** [timestamp]
**审核范围：** 未提交的更改
**触发方式：** 命令参数 `[C]`

### Codex 发现：

[Codex 输出内容]

### 与 Claude 审核的对比：

| 发现类型 | Claude Agents | Codex | 状态 |
|----------|---------------|-------|------|
| 安全问题 | [count] | [count] | 一致/新增/遗漏 |
| 性能问题 | [count] | [count] | 一致/新增/遗漏 |
| 代码质量 | [count] | [count] | 一致/新增/遗漏 |

### 综合建议：

基于 Claude 多代理审核 + Codex 审核的综合结果：

1. **必须修复（双方一致）：** [优先级最高]
2. **建议修复（单方发现）：** [次优先]
3. **可选优化：** [最低优先]

---
```

**Step 7.4: 超时处理（如果 Codex 未在 5 分钟内完成）**

如果 TaskOutput 返回超时（exit code 124）或任务仍在运行，向用户显示：

```markdown
---

## ⏱️ Codex 审核超时

Codex 审核未在 5 分钟内完成。可能原因：
- 代码量较大，需要更多处理时间
- 网络延迟或 API 响应慢

### 备选方案

**方案 1：增加超时时间重试**
```bash
./scripts/codex-review-now.sh uncommitted 600  # 10 分钟超时
```

**方案 2：手动运行交互式 Codex**
```bash
codex
# 进入交互模式后输入:
/review
```

**方案 3：查看部分输出**
```bash
# 结果文件（如有）
cat ${TEMP:-/tmp}/codex-review/result-*.md | tail -1 | xargs cat

# 事件日志
cat ${TEMP:-/tmp}/codex-review/events-*.jsonl | tail -1 | xargs tail -20
```

---

**注意**：Claude 多代理审核结果仍然有效，Codex 仅作为补充视角。
```

</codex_execution>

#### 当 CODEX_ENABLED = false 时：

跳过 Codex 审核，直接显示 Claude 多代理审核的最终报告。

<codex_prerequisites>

**Codex 审核前提条件（使用 `[C]` 参数时需要）：**

- 安装 Codex CLI: `npm install -g @openai/codex`
- 首次使用需登录: `codex`（交互式登录）
- 需要有未提交的更改才能审核

</codex_prerequisites>

### 8. Gemini 额外审核（参数 `[G]` 触发）

<!-- CLAUDE-CODE-ONLY-START -->

<gemini_auto_review>

**检查 Step 0 中解析的 GEMINI_ENABLED 标志：**

```
如果 GEMINI_ENABLED = true（命令参数包含 [G]）：
  → 自动执行 Gemini 审核
  → 整合结果到报告

如果 GEMINI_ENABLED = false（命令参数不包含 [G]）：
  → 跳过此步骤
```

</gemini_auto_review>

#### 当 GEMINI_ENABLED = true 时，自动执行：

<gemini_execution>

**Step 8.1: 检查 Gemini CLI 可用性**

```bash
command -v gemini || echo "Gemini CLI 未安装，请运行: npm install -g @google/gemini-cli"
```

如果未安装，提示用户安装并跳过 Gemini 审核（其他审核结果仍然有效）。

**Step 8.2: 使用 gemini 非交互模式审核**

**技术方案**（基于 Gemini 官方建议）：
- 使用 `gemini -m gemini-3-pro-preview -p '' -o json` 非交互模式
- 通过 stdin 管道传递 prompt（避免命令行长度限制）
- 使用系统 `timeout` 命令处理超时（Gemini CLI 无内置超时）
- 不截断 diff（Gemini 支持 1M+ tokens）

**执行流程**：

```
Step 1: 后台启动 Gemini
  - 使用 Bash 工具，设置 run_in_background=true
  - 调用: ./scripts/gemini-review-now.sh uncommitted 300
  - 记录返回的 task_id

Step 2: 向用户显示进度提示
  "⏳ Gemini 审核已启动（后台运行）
   - 使用 gemini -m gemini-3-pro-preview -p '' -o json 非交互模式
   - 超时阈值：5 分钟"

Step 3: 等待完成
  使用 TaskOutput 工具等待任务完成

Step 4: 处理结果
  正常完成 → 读取输出，整合到报告
  超时/失败 → 显示错误信息
```

**调用命令**：

```bash
./scripts/gemini-review-now.sh uncommitted 300
```

**Step 8.3: 整合 Gemini 审核结果**

```markdown
---

## 🤖 Gemini 额外审核结果

**审核时间：** [timestamp]
**审核范围：** 未提交的更改
**触发方式：** 命令参数 `[G]`

### Gemini 发现：

[Gemini 输出内容]

---
```

</gemini_execution>

#### 当 GEMINI_ENABLED = false 时：

跳过 Gemini 审核。

<gemini_prerequisites>

**Gemini 审核前提条件（使用 `[G]` 参数时需要）：**

- 安装 Gemini CLI: `npm install -g @google/gemini-cli`
- 首次使用需登录: `gemini`（交互式登录）
- 需要有未提交的更改才能审核

</gemini_prerequisites>

<!-- CLAUDE-CODE-ONLY-END -->

### 9. 多工具审核结果综合（[C][G] 同时启用时）

<!-- CLAUDE-CODE-ONLY-START -->

当 CODEX_ENABLED 和 GEMINI_ENABLED 都为 true 时，在最终报告中整合三方结果：

```markdown
## 🔄 多工具审核综合

| 发现类型 | Claude | Codex | Gemini | 优先级 |
|----------|--------|-------|--------|--------|
| 安全问题 | [X] | [Y] | [Z] | 多方一致 > 双方 > 单方 |

**综合建议**：
1. 必须修复（多方一致）
2. 建议修复（双方发现）
3. 可选优化（单方发现）
```

<!-- CLAUDE-CODE-ONLY-END -->

### Important: P1 Findings Block Merge

Any **🔴 P1 (CRITICAL)** findings must be addressed before merging the PR. Present these prominently and ensure they're resolved before accepting the PR.
