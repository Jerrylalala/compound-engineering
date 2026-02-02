---
name: workflows:work
description: "Step 3: 高效执行工作计划（1任务=标准，≥2任务=自动Subagent）"
argument-hint: "[plan file, specification, or todo file path]"
---

# Work Plan Execution Command

Execute a work plan efficiently while maintaining quality and finishing features.

## Introduction

This command takes a work document (plan, specification, or todo file) and executes it systematically. The focus is on **shipping complete features** by understanding requirements quickly, following existing patterns, and maintaining quality throughout.

## Input Document

<input_document> #$ARGUMENTS </input_document>

## Execution Mode Detection（自动）

在 Phase 1 Step 4（Create Todo List）完成后，根据 TodoWrite 中的任务数量自动选择执行模式：

```
统计时机: Phase 1 结束后，Phase 2 开始前
统计来源: TodoWrite 任务列表

任务数量 = 1  → 标准模式（单代理执行）
任务数量 ≥ 2 → Subagent-Driven 模式（自动启用）
```

**宣布执行模式：**
```
if (task_count == 1):
  "检测到 1 个任务，使用标准模式执行。"
else:
  "检测到 [task_count] 个任务，自动启用 Subagent-Driven 模式。"
```

**Subagent-Driven 模式（≥2 任务自动启用）：**
- 每个任务派遣新的子代理执行
- 执行两阶段审查（规范合规 → 代码质量）
- 默认批量处理 3 个任务后设置人工检查点

**标准模式（1 任务）：**
- 单代理直接执行
- 无需额外开销

## Execution Workflow

### Phase 1: Quick Start

1. **Read Plan and Clarify**

   - Read the work document completely
   - Review any references or links provided in the plan
   - If anything is unclear or ambiguous, ask clarifying questions now
   - Get user approval to proceed
   - **Do not skip this** - better to ask questions now than build the wrong thing

2. **Detect UI/Frontend Tasks** (Auto-Detection)

   After reading the plan, scan for UI-related keywords:

   **Detection triggers** (case-insensitive):
   - `UI`, `前端`, `frontend`, `界面`, `页面`, `组件`
   - `button`, `form`, `modal`, `layout`, `设计`
   - `CSS`, `Tailwind`, `React`, `Vue`, `HTML`
   - `Figma`, `design`, `视觉`, `交互`

   **Exclusion triggers** (suppress UI detection if found):
   - `database design`, `API design`, `system design`, `schema design`, `架构设计`
   - `data layout`, `memory layout`, `struct layout`
   - `backend only`, `server-side`, `CLI`, `命令行`

   **If UI work detected (and no exclusion triggers found):**

   - Announce: "检测到 UI/前端任务，自动加载设计指南..."
   - Load `frontend-design` skill for visual aesthetics
   - Load `user-first-design` skill for UX principles (if available in skills-custom/)
   - Apply these principles throughout implementation:
     - 极简操作路径（最多3步）
     - 即时反馈（视觉/文字/动画）
     - 温柔的错误处理（禁止责备性词汇）
     - 高对比、低密度、清晰间距

   **If Figma URL found in plan:**
   - Note for Phase 2: Use `figma-design-sync` agent for pixel-perfect implementation
   - Remind: "发现 Figma 链接，将在实现阶段使用 figma-design-sync 进行同步"

3. **Setup Environment**

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
   - Ask: "Continue working on `[current_branch]`, or create a new branch?"
   - If continuing, proceed to step 3
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

4. **Create Todo List**
   - Use TodoWrite to break plan into actionable tasks
   - Include dependencies between tasks
   - Prioritize based on what needs to be done first
   - Include testing and quality check tasks
   - Keep tasks specific and completable

### Phase 2: Execute

#### Execution Mode A: Standard（1 任务时使用）

单代理执行，适合简单任务。

1. **Task Execution Loop**

   For each task in priority order:

   ```
   while (tasks remain):
     - Mark task as in_progress in TodoWrite
     - Read any referenced files from the plan
     - Look for similar patterns in codebase
     - Implement following existing conventions
     - Write tests for new functionality
     - Run tests after changes
     - Mark task as completed in TodoWrite
     - Mark off the corresponding checkbox in the plan file ([ ] → [x])
     - Evaluate for incremental commit (see below)
   ```

   **IMPORTANT**: Always update the original plan document by checking off completed items. Use the Edit tool to change `- [ ]` to `- [x]` for each task you finish. This keeps the plan as a living document showing progress and ensures no checkboxes are left unchecked.

#### Execution Mode B: Subagent-Driven（≥2 任务自动启用）

每任务派遣新子代理，避免上下文污染，适合复杂任务。

1. **Batch Task Execution**

   默认批量处理前 3 个任务，然后设置人工检查点：

   ```
   batch_size = 3

   while (tasks remain):
     current_batch = tasks[0:batch_size]

     for task in current_batch:
       # 1. 派遣新子代理执行单个任务
       Task(general-purpose): """
         执行以下任务：

         任务描述: [task.description]
         文件路径: [task.file_path]
         代码: [task.code]

         **执行规则**：
         - 如果任务涉及新功能实现 → 使用 test-driven-development skill（先写失败测试）
         - 如果任务涉及 bug 修复 → 使用 systematic-debugging skill（先做根因分析）
         - 否则 → 直接执行

         完成后运行验证命令并报告结果。
       """

       # 2. 两阶段审查
       # Stage 1: 规范合规审查（使用 spec-compliance-review skill）
       Task(general-purpose): """
         使用 spec-compliance-review skill 审查刚完成的任务。

         原始任务描述: [task.description]
         实现者报告: [subagent 的执行结果]

         验证：
         1. 遗漏的需求 - 是否实现了所有请求的功能？
         2. 多余的工作 - 是否构建了不需要的东西？
         3. 理解偏差 - 是否以不同于预期的方式解释需求？

         报告：✅ 规格符合 或 ❌ 发现问题（附具体内容）
       """

       # Stage 2: 代码质量审查（可选，复杂任务启用）
       # Task(code-simplicity-reviewer): "审查代码质量"

       # 3. 更新任务状态
       - Mark task as completed in TodoWrite
       - Mark off checkbox in plan file ([ ] → [x])

     # 4. 人工检查点
     AskUserQuestion: "已完成 [batch_size] 个任务。继续下一批？"
     - Yes: continue to next batch
     - Review changes: show git diff, then ask again
     - Stop: exit execution loop
   ```

2. **Why Subagent-Driven?**

   | 问题 | 单代理 | 子代理驱动 |
   |------|--------|------------|
   | 上下文污染 | 任务越多，质量越差 | 每任务新鲜上下文 |
   | Token 成本 | 上下文累积增长 | 每任务精确上下文 |
   | 首次成功率 | ~40%（后期任务） | ~95%（恒定） |
   | 适用场景 | 简单/连续任务 | 复杂/独立任务 |

3. **Incremental Commits**

   After completing each task, evaluate whether to create an incremental commit:

   | Commit when... | Don't commit when... |
   |----------------|---------------------|
   | Logical unit complete (model, service, component) | Small part of a larger unit |
   | Tests pass + meaningful progress | Tests failing |
   | About to switch contexts (backend → frontend) | Purely scaffolding with no behavior |
   | About to attempt risky/uncertain changes | Would need a "WIP" commit message |

   **Heuristic:** "Can I write a commit message that describes a complete, valuable change? If yes, commit. If the message would be 'WIP' or 'partial X', wait."

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

4. **Follow Existing Patterns**

   - The plan should reference similar code - read those files first
   - Match naming conventions exactly
   - Reuse existing components where possible
   - Follow project coding standards (see CLAUDE.md)
   - When in doubt, grep for similar implementations

5. **Test Continuously**

   - Run relevant tests after each significant change
   - Don't wait until the end to test
   - Fix failures immediately
   - Add new tests for new functionality

6. **Figma Design Sync** (if applicable)

   For UI work with Figma designs:

   - Implement components following design specs
   - Use figma-design-sync agent iteratively to compare
   - Fix visual differences identified
   - Repeat until implementation matches design

7. **UI/UX Quality Check** (if UI work detected in Phase 1)

   Before moving to Phase 3, verify UI implementation against loaded design principles:

   **user-first-design 检查项：**
   - [ ] 操作路径是否 ≤ 3 步？
   - [ ] 所有操作是否有即时反馈？
   - [ ] 错误提示是否告诉用户如何解决（而非责备）？
   - [ ] 文案是否使用正向语气？（禁止"错误"、"失败"、"无效"）

   **frontend-design 检查项：**
   - [ ] 是否避免了 AI 风格同质化？（避免 Inter、Roboto、紫色渐变）
   - [ ] 视觉层级是否清晰？
   - [ ] 是否有适当的动效反馈？

   **Optional:** Use `design-iterator` agent for iterative visual refinement if design feels off

8. **Cursor Visual Editor 微调** (if running in Cursor environment)

   当 Claude Code 生成的 UI 需要微调时，使用 Cursor Visual Editor 进行可视化调整。

   详细操作步骤参见 `user-first-design` 技能中的「Cursor 集成工作流」部分。

   **快速提示**：
   - 启动本地服务器 → Cursor Browser 打开页面 → Visual Editor 面板微调
   - 点击元素 + 描述修改，或拖拽调整布局
   - 修改会自动同步到代码

9. **Track Progress**
   - Keep TodoWrite updated as you complete tasks
   - Note any blockers or unexpected discoveries
   - Create new tasks if scope expands
   - Keep user informed of major milestones

### Phase 3: Quality Check

1. **Run Core Quality Checks**

   Always run before submitting:

   ```bash
   # Run full test suite (use project's test command)
   # Examples: bin/rails test, npm test, pytest, go test, etc.

   # Run linting (per CLAUDE.md)
   # Use linting-agent before pushing to origin
   ```

2. **Consider Reviewer Agents** (Optional)

   Use for complex, risky, or large changes:

   - **code-simplicity-reviewer**: Check for unnecessary complexity
   - **kieran-rails-reviewer**: Verify Rails conventions (Rails projects)
   - **performance-oracle**: Check for performance issues
   - **security-sentinel**: Scan for security vulnerabilities
   - **cora-test-reviewer**: Review test quality (Rails projects with comprehensive test coverage)

   Run reviewers in parallel with Task tool:

   ```
   Task(code-simplicity-reviewer): "Review changes for simplicity"
   Task(kieran-rails-reviewer): "Check Rails conventions"
   ```

   Present findings to user and address critical issues.

3. **Final Validation**
   - All TodoWrite tasks marked completed
   - All tests pass
   - Linting passes
   - Code follows existing patterns
   - Figma designs match (if applicable)
   - No console errors or warnings

### Phase 4: Ship It

1. **Create Commit**

   ```bash
   git add .
   git status  # Review what's being committed
   git diff --staged  # Check the changes

   # Commit with conventional format
   git commit -m "$(cat <<'EOF'
   feat(scope): description of what and why

   Brief explanation if needed.

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```

2. **Capture and Upload Screenshots for UI Changes** (REQUIRED for any UI work)

   For **any** design changes, new views, or UI modifications, you MUST capture and upload screenshots:

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

   **Step 3: Upload using imgup skill**
   ```bash
   skill: imgup
   # Then upload each screenshot:
   imgup -h pixhost screenshot.png  # pixhost works without API key
   # Alternative hosts: catbox, imagebin, beeimg
   ```

   **What to capture:**
   - **New screens**: Screenshot of the new UI
   - **Modified screens**: Before AND after screenshots
   - **Design implementation**: Screenshot showing Figma design match

   **IMPORTANT**: Always include uploaded image URLs in PR description. This provides visual context for reviewers and documents the change.

3. **Create Pull Request**

   ```bash
   git push -u origin feature-branch-name

   gh pr create --title "Feature: [Description]" --body "$(cat <<'EOF'
   ## Summary
   - What was built
   - Why it was needed
   - Key decisions made

   ## Testing
   - Tests added/modified
   - Manual testing performed

   ## Before / After Screenshots
   | Before | After |
   |--------|-------|
   | ![before](URL) | ![after](URL) |

   ## Figma Design
   [Link if applicable]

   ---

   [![Compound Engineered](https://img.shields.io/badge/Compound-Engineered-6366f1)](https://github.com/EveryInc/compound-engineering-plugin) 🤖 Generated with [Claude Code](https://claude.com/claude-code)
   EOF
   )"
   ```

4. **Notify User**
   - Summarize what was completed
   - Link to PR
   - Note any follow-up work needed
   - Suggest next steps if applicable

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
- Use reviewer agents for complex/risky changes only

### Ship Complete Features

- Mark all tasks completed before moving on
- Don't leave features 80% done
- A finished feature that ships beats a perfect feature that doesn't

## Quality Checklist

Before creating PR, verify:

- [ ] All clarifying questions asked and answered
- [ ] All TodoWrite tasks marked completed
- [ ] Tests pass (run project's test command)
- [ ] Linting passes (use linting-agent)
- [ ] Code follows existing patterns
- [ ] Figma designs match implementation (if applicable)
- [ ] Before/after screenshots captured and uploaded (for UI changes)
- [ ] Commit messages follow conventional format
- [ ] PR description includes summary, testing notes, and screenshots
- [ ] PR description includes Compound Engineered badge

## When to Use Reviewer Agents

**Don't use by default.** Use reviewer agents only when:

- Large refactor affecting many files (10+)
- Security-sensitive changes (authentication, permissions, data access)
- Performance-critical code paths
- Complex algorithms or business logic
- User explicitly requests thorough review

For most features: tests + linting + following patterns is sufficient.

## Common Pitfalls to Avoid

- **Analysis paralysis** - Don't overthink, read the plan and execute
- **Skipping clarifying questions** - Ask now, not after building wrong thing
- **Ignoring plan references** - The plan has links for a reason
- **Testing at the end** - Test continuously or suffer later
- **Forgetting TodoWrite** - Track progress or lose track of what's done
- **80% done syndrome** - Finish the feature, don't move on early
- **Over-reviewing simple changes** - Save reviewer agents for complex work
