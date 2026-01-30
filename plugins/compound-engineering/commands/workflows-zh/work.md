---
name: workflows-zh:work
description: 高效执行工作计划并保持质量，完成交付
argument-hint: "[计划文件、规格说明或待办文件路径]"
---

# 工作计划执行命令

**输出语言：中文。结构与英文版一致。**

高效执行工作计划，在保证质量的同时完成可交付功能。

## 引言

本命令接受一个工作文档（计划、规格说明或待办文件）并系统性地执行。重点是 **交付完整功能**：快速理解需求、遵循已有模式、全程保持质量。

## 输入文档

<input_document> #$ARGUMENTS </input_document>

## 执行流程

### 阶段 1：快速启动

1. **阅读计划并澄清**

   - 完整阅读工作文档
   - 查看计划中提供的引用或链接
   - 若有不清晰或歧义之处，立即提问
   - 获取用户继续执行的确认
   - **不要跳过** —— 现在提问比做错更便宜

2. **环境准备**

   首先检查当前分支：

   ```bash
   current_branch=$(git branch --show-current)
   default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

   # Fallback if remote HEAD isn't set
   if [ -z "$default_branch" ]; then
     default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
   fi
   ```

   **如果已经在功能分支**（非默认分支）：
   - 询问：“继续在 `[current_branch]` 上工作，还是新建分支？”
   - 若继续，进入步骤 3
   - 若新建，按下方 A 或 B 方案

   **如果在默认分支**，选择如何继续：

   **方案 A：创建新分支**
   ```bash
   git pull origin [default_branch]
   git checkout -b feature-branch-name
   ```
   使用有意义的分支名（如 `feat/user-authentication`, `fix/email-validation`）。

   **方案 B：使用 worktree（推荐并行开发）**
   ```bash
   skill: git-worktree
   # 该 skill 会在独立 worktree 中从默认分支创建新分支
   ```

   **方案 C：继续在默认分支**
   - 需要用户明确确认
   - 仅在用户明确说“yes, commit to [default_branch]”后才可继续
   - 未经明确许可，**不要** 直接在默认分支提交

   **推荐使用 worktree 当：**
   - 需要并行处理多个功能
   - 想保持默认分支干净
   - 需要频繁切换分支

3. **创建待办清单**
   - 使用 TodoWrite 将计划拆解为可执行任务
   - 明确任务之间依赖
   - 按优先级排序
   - 包含测试与质量检查任务
   - 任务要具体、可完成

### 阶段 2：执行

1. **任务执行循环**

   对每个任务按优先级执行：

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

   **重要：** 必须在原始计划文档中勾选已完成任务。使用 Edit 工具将 `- [ ]` 改为 `- [x]`。这能让计划成为进度记录，并确保不遗漏。

2. **增量提交**

   每完成一个任务后，评估是否进行增量提交：

   | 何时提交 | 何时不提交 |
   |----------|-----------|
   | 逻辑单元完成（模型、服务、组件） | 仍是大型单元的一小部分 |
   | 测试通过 + 有意义进展 | 测试失败 |
   | 即将切换上下文（后端 → 前端） | 纯脚手架且无行为 |
   | 即将尝试高风险变更 | 会写成 “WIP” |

   **判断标准：** “能否写出一个描述完整有价值改动的提交信息？如果能，提交；如果只能写 WIP 或 partial，就再等等。”

   **提交流程：**
   ```bash
   # 1. 确认测试通过（使用项目测试命令）
   # Examples: bin/rails test, npm test, pytest, go test, etc.

   # 2. 仅暂存本逻辑单元相关文件（不要 git add .）
   git add <files related to this logical unit>

   # 3. 使用规范提交信息
   git commit -m "feat(scope): description of this unit"
   ```

   **处理冲突：** 若 rebase/merge 冲突，立即解决。小而清晰的提交更易解决冲突。

   **注意：** 增量提交使用干净的规范消息，不含归因。最终 Phase 4 提交/PR 包含完整归因。

3. **遵循已有模式**

   - 计划中引用的文件先读
   - 命名规则严格一致
   - 尽量复用已有组件
   - 遵循项目编码规范（见 CLAUDE.md）
   - 不确定时用 grep 找类似实现

4. **持续测试**

   - 每次重要改动后运行相关测试
   - 不要等到最后才测试
   - 及时修复失败
   - 为新功能添加测试

5. **Figma 设计同步**（如适用）

   针对 UI 工作：

   - 按设计规格实现组件
   - 用 figma-design-sync 代理迭代对比
   - 修复差异
   - 重复直到一致

6. **跟踪进度**
   - 维护 TodoWrite
   - 记录阻塞点或意外发现
   - 若范围扩大，新增任务
   - 及时告知用户关键进展

### 阶段 3：质量检查

1. **运行核心质量检查**

   提交前必须执行：

   ```bash
   # Run full test suite (use project's test command)
   # Examples: bin/rails test, npm test, pytest, go test, etc.

   # Run linting (per CLAUDE.md)
   # Use linting-agent before pushing to origin
   ```

2. **可选评审代理**（可选）

   在复杂、风险高或大规模修改时使用：

   - **code-simplicity-reviewer**：检查不必要复杂度
   - **kieran-rails-reviewer**：验证 Rails 规范（Rails 项目）
   - **performance-oracle**：检查性能问题
   - **security-sentinel**：扫描安全漏洞
   - **cora-test-reviewer**：评审测试质量（Rails 项目）

   并行运行：

   ```
   Task(code-simplicity-reviewer): "Review changes for simplicity"
   Task(kieran-rails-reviewer): "Check Rails conventions"
   ```

   将发现反馈给用户并处理关键问题。

3. **最终校验**
   - TodoWrite 全部完成
   - 测试通过
   - Lint 通过
   - 符合既有模式
   - 若有 Figma，设计一致
   - 无控制台错误/警告

### 阶段 4：交付

1. **创建提交**

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

2. **为 UI 改动截图并上传**（任何 UI 修改都必须）

   对任何设计变更、新视图或 UI 修改，必须截图并上传：

   **步骤 1：启动开发服务**（如未运行）
   ```bash
   bin/dev  # Run in background
   ```

   **步骤 2：用 agent-browser CLI 截图**
   ```bash
   agent-browser open http://localhost:3000/[route]
   agent-browser snapshot -i
   agent-browser screenshot output.png
   ```
   详细用法见 `agent-browser` skill。

   **步骤 3：用 imgup 上传**
   ```bash
   skill: imgup
   # Then upload each screenshot:
   imgup -h pixhost screenshot.png  # pixhost works without API key
   # Alternative hosts: catbox, imagebin, beeimg
   ```

   **需要截图的内容：**
   - **新界面**：新 UI 截图
   - **修改界面**：修改前后对比图
   - **设计对比**：与 Figma 对齐的截图

   **重要：** 在 PR 描述中包含上传后的 URL。

3. **创建 PR**

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

4. **通知用户**
   - 总结完成内容
   - 提供 PR 链接
   - 标注后续工作
   - 建议下一步（如适用）

---

## 核心原则

### 快速启动，更快执行

- 开始时把问题问清楚
- 不要等到完美理解才开始
- 目标是 **完成交付**，不是流程完美

### 计划是指南

- 计划中的引用一定要读
- 遵循现有模式
- 不要重复造轮子

### 持续测试

- 每次改动后都测试
- 及时修复失败
- 持续测试避免大翻车

### 质量内建

- 遵循既有模式
- 为新代码写测试
- 推送前运行 lint
- 复杂/高风险才用评审代理

### 交付完整功能

- 任务必须完成后再进入下一步
- 不要 80% 停止
- 完成的功能胜过未完成的完美功能

## 质量检查清单

创建 PR 前确认：

- [ ] 所有澄清问题已答复
- [ ] TodoWrite 全部完成
- [ ] 测试通过（使用项目测试命令）
- [ ] Lint 通过（使用 linting-agent）
- [ ] 符合既有模式
- [ ] 若有 Figma，设计一致
- [ ] UI 变更已截图上传
- [ ] 提交信息符合规范
- [ ] PR 描述包含摘要/测试/截图
- [ ] PR 描述包含 Compound Engineered 徽章

## 何时使用评审代理

**默认不使用。** 仅在以下情况使用：

- 大型重构影响 10+ 文件
- 安全敏感变更（认证、权限、数据访问）
- 性能关键路径
- 复杂算法或业务逻辑
- 用户明确要求深度评审

大多数功能：测试 + lint + 遵循模式即可。

## 常见陷阱

- **分析瘫痪** —— 读计划并执行
- **跳过澄清** —— 现在问而不是做完才发现错了
- **忽略计划引用** —— 计划引用有原因
- **最后才测试** —— 持续测试
- **忘记 TodoWrite** —— 进度丢失
- **80% 综合症** —— 完成交付，不要半途而废
- **过度评审** —— 把评审留给复杂变更
